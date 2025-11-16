import 'dart:io';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/services/media_uploader.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:kairos/features/journal/domain/value_objects/value_objects.dart';

/// Use case for retrying/resuming failed or interrupted message pipelines
///
/// Stateless retry logic:
/// 1. Read current message status from repository
/// 2. Determine next step based on status and failureReason
/// 3. Execute that step
/// 4. Update status and continue or stop
///
/// Idempotent: safe to call multiple times on same message.
/// Status updates are written to local DB, automatically updating UI via repository stream.
class RetryMessagePipelineUseCase {
  RetryMessagePipelineUseCase({
    required this.messageRepository,
    required this.mediaUploader,
    required this.aiServiceClient,
  });

  final JournalMessageRepository messageRepository;
  final MediaUploader mediaUploader;
  final AiServiceClient aiServiceClient;

  // Retry policy constants
  static const int _maxAttempts = 5;
  static const List<int> _backoffSeconds = [2, 4, 8, 16, 32];

  /// Resume message pipeline from current state
  ///
  /// Returns success once pipeline is resumed (status updates appear via repository stream).
  Future<Result<void>> call(String messageId) async {
    try {
      // Step 1: Get current message state
      final messageResult = await messageRepository.getMessageById(messageId);

      if (messageResult.isError) {
        return Error(messageResult.failureOrNull!);
      }

      final messageData = messageResult.dataOrNull;
      if (messageData == null) {
        return const Error(ValidationFailure(message: 'Message not found'));
      }

      final message = messageData;

      // Step 2: Check if max attempts reached
      if (message.attemptCount >= _maxAttempts) {
        logger.i('Max retry attempts reached for message $messageId');
        return const Error(
          ValidationFailure(
            message: 'Maximum retry attempts reached (5). Please contact support.',
          ),
        );
      }

      // Step 3: Check backoff period
      if (message.lastAttemptAt != null) {
        final backoffIndex = message.attemptCount.clamp(0, _backoffSeconds.length - 1);
        final requiredBackoffSeconds = _backoffSeconds[backoffIndex];
        final timeSinceLastAttempt = DateTime.now().difference(message.lastAttemptAt!).inSeconds;

        if (timeSinceLastAttempt < requiredBackoffSeconds) {
          final remainingSeconds = requiredBackoffSeconds - timeSinceLastAttempt;
          return Error(
            ValidationFailure(
              message: 'Please wait $remainingSeconds seconds before retrying',
            ),
          );
        }
      }

      logger.i(
        'Retrying message pipeline: $messageId (status: ${message.status}, attempt: ${message.attemptCount})',
      );

      // Step 4: Resume based on current status
      return _resumeFromStatus(message);
    } catch (e) {
      logger.i('Unexpected error in RetryMessagePipelineUseCase: $e');
      return Error(UnknownFailure(message: 'Retry failed: $e'));
    }
  }

  /// Resume pipeline based on message status
  Future<Result<void>> _resumeFromStatus(JournalMessageEntity message) async {
    switch (message.status) {
      case MessageStatus.localCreated:
      case MessageStatus.failed when message.failureReason == FailureReason.uploadFailed:
      case MessageStatus.uploadingMedia:
        // Need to upload media
        return _uploadMediaStep(message);

      case MessageStatus.mediaUploaded:
      case MessageStatus.failed when message.failureReason == FailureReason.transcriptionFailed:
        // Need to transcribe/analyze
        return _processAiStep(message);

      case MessageStatus.processed:
      case MessageStatus.failed when message.failureReason == FailureReason.remoteCreationFailed:
        // Need to create remote
        return _createRemoteStep(message);

      case MessageStatus.remoteCreated:
      case MessageStatus.failed when message.failureReason == FailureReason.aiResponseFailed:
      case MessageStatus.processingAi:
        // Need to request AI response
        return _requestAiResponseStep(message);

      // ignore: no_default_cases
      default:
        return const Error(
          ValidationFailure(
            message: 'Message is not in a retryable state',
          ),
        );
    }
  }

  /// Upload media files (audio/image)
  Future<Result<void>> _uploadMediaStep(JournalMessageEntity message) async {
    if (message.messageType == MessageType.text) {
      // Text messages don't need upload - skip to remote creation
      return _createRemoteStep(message);
    }

    if (message.localFilePath == null) {
      // ignore: parameter_assignments
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.uploadFailed,
        uploadError: 'No local file path',
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      return const Error(ValidationFailure(message: 'No local file path for upload'));
    }

    final file = File(message.localFilePath!);
    if (!file.existsSync()) {
      // ignore: parameter_assignments
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.uploadFailed,
        uploadError: 'Local file no longer exists',
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      return const Error(ValidationFailure(message: 'Local file no longer exists'));
    }

    // Update status to uploading
    // ignore: parameter_assignments
    message = message.copyWith(
      status: MessageStatus.uploadingMedia,
      uploadProgress: 0,
    );
    await messageRepository.updateMessage(message);

    // Determine content type and storage path
    final contentType = message.messageType == MessageType.audio ? 'audio/mp4' : 'image/jpeg';
    final extension = message.messageType == MessageType.audio ? 'm4a' : 'jpg';
    final storagePath =
        'users/${message.userId}/journals/${message.threadId}/${message.id}.$extension';

    logger.i('Uploading ${message.messageType.name} for message ${message.id}');

    final uploadResult = await mediaUploader.uploadFile(
      file: file,
      storagePath: storagePath,
      contentType: contentType,
      metadata: {
        'messageId': message.id,
        'threadId': message.threadId,
        'type': message.messageType.name,
      },
      onProgress: (progress) async {
        // ignore: parameter_assignments
        message = message.copyWith(uploadProgress: progress);
        await messageRepository.updateMessage(message);
      },
    );

    if (uploadResult.isError) {
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.uploadFailed,
        uploadError: uploadResult.failureOrNull?.message,
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      return Error(uploadResult.failureOrNull!);
    }

    // Upload succeeded
    message = message.copyWith(
      status: MessageStatus.mediaUploaded,
      storageUrl: uploadResult.dataOrNull!.remoteUrl,
      uploadProgress: 1,
    );
    await messageRepository.updateMessage(message);

    // Continue to next step
    return _processAiStep(message);
  }

  /// Process AI (transcription or image analysis)
  Future<Result<void>> _processAiStep(JournalMessageEntity message) async {
    message = message.copyWith(
      status: MessageStatus.processingAi,
      aiError: null, // Clear previous error
    );
    await messageRepository.updateMessage(message);

    if (message.messageType == MessageType.audio) {
      // Transcribe audio
      if (message.storageUrl == null) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.transcriptionFailed,
          aiError: 'No audio URL for transcription',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);
        return const Error(ValidationFailure(message: 'No audio URL'));
      }

      logger.i('Transcribing audio for message ${message.id}');

      final transcriptionResult = await aiServiceClient.transcribeAudio(
        messageId: message.id,
        audioUrl: message.storageUrl!,
      );

      if (transcriptionResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.transcriptionFailed,
          aiError: transcriptionResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);
        return Error(transcriptionResult.failureOrNull!);
      }

      message = message.copyWith(
        status: MessageStatus.processed,
        transcription: transcriptionResult.dataOrNull!.transcription,
        content: transcriptionResult.dataOrNull!.transcription,
      );
      await messageRepository.updateMessage(message);
    } else if (message.messageType == MessageType.image) {
      // Analyze image
      if (message.storageUrl == null) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: 'No image URL for analysis',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);
        return const Error(ValidationFailure(message: 'No image URL'));
      }

      logger.i('Analyzing image for message ${message.id}');

      final analysisResult = await aiServiceClient.analyzeImage(
        messageId: message.id,
        imageUrl: message.storageUrl!,
      );

      if (analysisResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: analysisResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);
        return Error(analysisResult.failureOrNull!);
      }

      message = message.copyWith(
        status: MessageStatus.processed,
        content: analysisResult.dataOrNull!.description,
      );
      await messageRepository.updateMessage(message);
    } else {
      // Text message - skip this step
      message = message.copyWith(status: MessageStatus.processed);
      await messageRepository.updateMessage(message);
    }

    // Continue to next step
    return _createRemoteStep(message);
  }

  /// Create remote message (sync to Firestore)
  Future<Result<void>> _createRemoteStep(JournalMessageEntity message) async {
    logger.i('Creating remote message ${message.id}');

    message = message.copyWith(status: MessageStatus.remoteCreated);

    final updateResult = await messageRepository.updateMessage(message);

    if (updateResult.isError) {
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.remoteCreationFailed,
        aiError: 'Failed to sync to server',
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      return Error(updateResult.failureOrNull!);
    }

    // Continue to next step
    return _requestAiResponseStep(message);
  }

  /// Request AI response generation
  Future<Result<void>> _requestAiResponseStep(JournalMessageEntity message) async {
    logger.i('Requesting AI response for message ${message.id}');

    message = message.copyWith(
      status: MessageStatus.processingAi,
      aiError: null,
    );
    await messageRepository.updateMessage(message);

    final aiResult = await aiServiceClient.generateAiResponse(messageId: message.id);

    if (aiResult.isError) {
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.aiResponseFailed,
        aiError: aiResult.failureOrNull?.message,
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      return Error(aiResult.failureOrNull!);
    }

    // Success - pipeline complete
    logger.i('Message pipeline complete (retry): ${message.id}');
    return const Success(null);
  }
}
