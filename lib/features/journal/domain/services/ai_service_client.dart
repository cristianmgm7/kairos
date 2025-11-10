import 'package:cloud_functions/cloud_functions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart' as result;

/// Response from transcription
class TranscriptionResult {
  const TranscriptionResult({required this.transcription});
  final String transcription;
}

/// Response from image analysis
class ImageAnalysisResult {
  const ImageAnalysisResult({required this.description});
  final String description;
}

/// Client for calling AI-related Cloud Functions
/// Centralizes: timeouts, retries, auth, error mapping, metrics
class AiServiceClient {
  AiServiceClient(this._functions);

  final FirebaseFunctions _functions;

  // Configuration
  static const int _timeoutSeconds = 120;
  static const int _maxRetries = 3;
  static const List<int> _retryDelaysSeconds = [2, 6, 12]; // Exponential backoff

  /// Transcribe audio file to text
  ///
  /// [messageId] - ID of the message being transcribed
  /// [audioUrl] - Firebase Storage URL of the audio file
  ///
  /// Returns transcription text or error
  Future<result.Result<TranscriptionResult>> transcribeAudio({
    required String messageId,
    required String audioUrl,
  }) async {
    return _callWithRetry(
      functionName: 'transcribeAudioMessage',
      params: {
        'messageId': messageId,
        'audioUrl': audioUrl,
      },
      parser: (data) {
        final transcription = data['transcription'] as String?;
        if (transcription == null) {
          throw const ServerFailure(message: 'No transcription in response');
        }
        return TranscriptionResult(transcription: transcription);
      },
      operationName: 'Transcription',
    );
  }

  /// Analyze image content
  ///
  /// [messageId] - ID of the message being analyzed
  /// [imageUrl] - Firebase Storage URL of the image file
  ///
  /// Returns image description/analysis or error
  Future<result.Result<ImageAnalysisResult>> analyzeImage({
    required String messageId,
    required String imageUrl,
  }) async {
    return _callWithRetry(
      functionName: 'analyzeImageMessage',
      params: {
        'messageId': messageId,
        'imageUrl': imageUrl,
      },
      parser: (data) {
        final description = data['description'] as String?;
        if (description == null) {
          throw const ServerFailure(message: 'No description in response');
        }
        return ImageAnalysisResult(description: description);
      },
      operationName: 'Image analysis',
    );
  }

  /// Request AI response generation for a message
  ///
  /// [messageId] - ID of the message to respond to
  ///
  /// Returns success or error (actual response comes via Firestore)
  Future<result.Result<void>> generateAiResponse({
    required String messageId,
  }) async {
    return _callWithRetry<void>(
      functionName: 'generateMessageResponse',
      params: {
        'messageId': messageId,
      },
      parser: (data) {}, // No return value needed
      operationName: 'AI response generation',
    );
  }

  /// Internal method: Call Cloud Function with retry logic
  ///
  /// Implements:
  /// - Timeout per call (120s)
  /// - Retry for transient errors (3 attempts)
  /// - Exponential backoff (2s, 6s, 12s)
  /// - Error mapping to domain failures
  /// - Logging for debugging
  Future<result.Result<T>> _callWithRetry<T>({
    required String functionName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic> data) parser,
    required String operationName,
  }) async {
    var attempt = 0;

    while (attempt < _maxRetries) {
      try {
        logger.i('$operationName attempt ${attempt + 1}/$_maxRetries: $params');

        final callable = _functions.httpsCallable(
          functionName,
          options: HttpsCallableOptions(
            timeout: const Duration(seconds: _timeoutSeconds),
          ),
        );

        final functionResult = await callable.call<Map<String, dynamic>>(params);
        final data = functionResult.data;

        logger.i('$operationName succeeded: $data');

        // Parse response
        final parsed = parser(data);
        return result.Success(parsed);
      } on FirebaseFunctionsException catch (e) {
        // Check if error is retryable
        final isRetryable = _isRetryableError(e.code);

        if (isRetryable && attempt < _maxRetries - 1) {
          // Wait before retry (exponential backoff)
          final delaySeconds = _retryDelaysSeconds[attempt];
          logger.i(
            '$operationName failed (${e.code}), retrying in ${delaySeconds}s: ${e.message}',
          );
          await Future<void>.delayed(Duration(seconds: delaySeconds));
          attempt++;
          continue;
        }

        // Non-retryable or max retries reached
        logger.i('$operationName failed permanently (${e.code}): ${e.message}');
        return result.Error(_mapFirebaseFunctionError(e, operationName));
      } catch (e) {
        logger.i('$operationName failed with unexpected error: $e');
        return result.Error(
          UnknownFailure(message: '$operationName failed: $e'),
        );
      }
    }

    // Should never reach here
    return result.Error(
      ServerFailure(message: '$operationName failed after $attempt attempts'),
    );
  }

  /// Check if error code is retryable (transient)
  bool _isRetryableError(String code) {
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'internal' ||
        code == 'unknown';
  }

  /// Map Firebase Functions error to domain failure
  Failure _mapFirebaseFunctionError(
    FirebaseFunctionsException error,
    String operationName,
  ) {
    switch (error.code) {
      case 'unauthenticated':
        return PermissionFailure(
          message: 'Authentication required for $operationName',
        );

      case 'permission-denied':
        return PermissionFailure(
          message: 'Access denied: ${error.message}',
        );

      case 'not-found':
        return ValidationFailure(
          message: 'Resource not found: ${error.message}',
        );

      case 'invalid-argument':
        return ValidationFailure(
          message: 'Invalid request: ${error.message}',
        );

      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkFailure(
          message: 'Network timeout: ${error.message}',
        );

      default:
        return ServerFailure(
          message: '$operationName failed: ${error.message}',
          code: int.tryParse(error.code),
        );
    }
  }
}
