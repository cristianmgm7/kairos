# Journal Message Pipeline Refactoring Implementation Plan

## Overview

Refactor the journal message creation and processing pipeline to follow clean architecture principles by moving business logic out of repositories, eliminating the upload service orchestration layer, and implementing explicit client-side AI service calls with proper state management and resumability.

## Current State Analysis

### Problems Identified

1. **Repository contains business logic** (`journal_message_repository_impl.dart`):
   - Lines 35-64: Makes decisions about upload status based on message type
   - Lines 46-55: Different handling for media vs text on network failure
   - Lines 208-218: Complex merge logic with upload status determination
   - Lines 137-149: Silently ignores remote update failures
   - **Should be**: Pure CRUD operations coordinating local/remote data sources

2. **Upload service orchestrates everything** (`journal_upload_service.dart`):
   - Lines 23-237: File uploads + status management + transcription triggering
   - Lines 269-333: Retry logic with exponential backoff
   - Lines 122, 202: Updates messages after upload
   - **Should be**: Delegated to use cases; retain only as thin file upload utility

3. **Cloud Functions trigger on database changes**:
   - `processUserMessage` - Firestore trigger on document creation
   - `processImageUpload` - Firestore trigger when storageUrl added
   - `triggerAudioTranscription` - Firestore trigger when storageUrl added
   - `processTranscribedMessage` - Firestore trigger when transcription added
   - **Should be**: Explicit callable functions invoked by client-side AI service

4. **No state visibility in UI**:
   - Use cases don't expose granular pipeline states
   - Users can't see "Uploading...", "Transcribing...", "AI thinking..."
   - **Should be**: Use cases emit state changes for UI display

5. **Fragmented status fields**:
   - `uploadStatus` enum (5 states)
   - `aiProcessingStatus` enum (4 states)
   - Potential race conditions and inconsistent states
   - **Should be**: Single authoritative `MessageStatus` enum modeling entire pipeline

### Key Discoveries

- **Current trigger-based architecture** (`functions/src/functions/message-triggers.ts:17-392`):
  - Text messages: document creation → immediate AI response
  - Audio: document creation → upload → storageUrl update triggers transcription → transcription update triggers AI response
  - Images: document creation → upload → storageUrl update triggers image analysis → AI response

- **Existing callable function pattern** (`functions/src/functions/transcription.ts:14-70`):
  - Already has `transcribeAudio` callable function
  - Auth via `request.auth?.uid`
  - Error handling with `HttpsError`
  - Resource ownership verification

- **Service patterns in Flutter** (`lib/features/journal/domain/services/`):
  - Uses `FirebaseFunctions.instance.httpsCallable()`
  - Result<T> type for error handling
  - Riverpod providers for dependency injection
  - Fire-and-forget operations with `unawaited()`

- **Repository coordination** (`lib/features/journal/data/repositories/journal_message_repository_impl.dart`):
  - Local-first architecture: always write to local, best-effort remote sync
  - Stream pattern: remote listener upserts into local, UI watches local stream
  - Incremental sync with conflict resolution

## Desired End State

### Architecture Changes

1. **Single `MessageStatus` enum** modeling the complete pipeline:
   ```dart
   enum MessageStatus {
     draft,              // Initial creation (not used yet)
     localCreated,       // Message saved locally
     uploadingMedia,     // File upload in progress
     mediaUploaded,      // File uploaded successfully
     processingAi,       // AI processing (transcription or response)
     processed,          // AI processing complete
     remoteCreated,      // Message synced to remote
     delivered,          // Confirmed delivered (optional)
     failed,             // Terminal failure state
   }
   ```

2. **Additional status fields** for telemetry and UI:
   ```dart
   double? uploadProgress;        // 0.0 to 1.0 during upload
   String? uploadError;           // Error message if upload fails
   String? aiError;               // Error message if AI processing fails
   int attemptCount;              // Number of retry attempts
   DateTime? lastAttemptAt;       // Last retry timestamp
   String? clientLocalId;         // For idempotency on remote writes
   ```

3. **Client-side `AiServiceClient`** (`lib/features/journal/domain/services/ai_service_client.dart`):
   - Centralizes all Cloud Function calls
   - Handles: timeouts, retries, auth, error mapping, metrics
   - Methods:
     - `transcribeAudio(messageId, audioUrl) → Result<String>`
     - `analyzeImage(messageId, imageUrl) → Result<String>`
     - `generateAiResponse(messageId) → Result<void>`
   - Retry policy: 3 attempts with exponential backoff (2s, 6s, 12s)
   - Timeout: 120 seconds per call

4. **Thin `MediaUploader` utility** (`lib/core/services/media_uploader.dart`):
   - Only handles low-level upload: upload file, resume, progress, cancel
   - Returns `UploadResult(remoteUrl, metadata)`
   - No orchestration, no state transitions
   - Basic low-level network retry only

5. **Use cases orchestrate full pipeline**:
   - `CreateTextMessageUseCase`: create local → create remote → AI response
   - `CreateAudioMessageUseCase`: create local → upload → transcribe → update → create remote → AI response
   - `CreateImageMessageUseCase`: create local → upload → analyze → update → create remote → AI response
   - Each emits `MessageStatus` updates during pipeline execution
   - Persist status after each step for resumability

6. **New `RetryMessagePipelineUseCase`** for resuming failed/interrupted operations:
   - `resume(localId)` method
   - Reads current `MessageStatus` from repository
   - Executes next appropriate step based on status
   - Idempotent: safe to call multiple times

7. **Simplified repository** (`journal_message_repository_impl.dart`):
   - Pure CRUD: `create()`, `update()`, `get()`, `watch()`, `delete()`
   - Coordinates local and remote data sources only
   - No status manipulation, no business decisions
   - Accepts `JournalMessageEntity` with status already set by use case

8. **New Cloud Functions** (callable):
   - `transcribeAudioMessage(messageId, audioUrl) → { transcription }`
   - `analyzeImageMessage(messageId, imageUrl) → { description }`
   - `generateMessageResponse(messageId) → { success }`
   - Keep existing `retryAiResponse` callable function

9. **Remove Firestore triggers**:
   - Delete `processUserMessage`
   - Delete `processImageUpload`
   - Delete `triggerAudioTranscription`
   - Delete `processTranscribedMessage`
   - Backend becomes on-demand rather than reactive

### Verification Criteria

After implementation:
- Message entity has single `status` field of type `MessageStatus`
- Repository has no if/else logic based on message type or role
- `JournalUploadService` deleted, replaced with thin `MediaUploader`
- Use cases show loading states in UI: "Uploading 45%", "Transcribing...", "AI thinking..."
- Failed messages can be manually retried via UI button
- All Cloud Functions are callable (no Firestore triggers for message processing)

## What We're NOT Doing

1. **Not changing the insights generation** - Keep `generateInsight` Firestore trigger as-is
2. **Not implementing push notifications** - Backend still doesn't push responses to client
3. **Not adding real-time typing indicators** for AI responses
4. **Not changing authentication mechanism** - Firebase Auth remains as-is
5. **Not implementing message editing or deletion** in this refactor
6. **Not adding message queuing or batch processing**
7. **Not implementing offline queue with background sync** - Messages still require network for remote operations
8. **Not migrating existing messages** - Focus on new message pipeline only

## Implementation Approach

### High-Level Strategy

This refactor touches many layers: domain entities, use cases, repositories, data sources, services, Cloud Functions, and UI. We'll implement bottom-up (data layer first) and use feature flags to enable the new pipeline gradually.

**Phases**:
1. **Domain Model** - New enums and entity fields
2. **Infrastructure** - MediaUploader, AiServiceClient, updated repositories
3. **Cloud Functions** - Convert to callable functions
4. **Use Cases** - Implement pipeline orchestration
5. **Retry Logic** - RetryMessagePipelineUseCase
6. **UI Integration** - Status display and manual retry buttons
7. **Migration** - Remove old code and Firestore triggers
8. **Testing** - End-to-end verification

### Migration Strategy

- **Feature flag**: `useNewMessagePipeline` in `FlavorConfig`
- New messages use new pipeline when flag enabled
- Old messages continue working with existing code
- Gradual rollout: dev → staging → production
- Rollback plan: disable feature flag

---

## Phase 1: Domain Model Refactoring

### Overview
Update domain entities with new status enum and fields, while maintaining backward compatibility during transition.

### Changes Required

#### 1. Message Status Enum
**File**: `lib/features/journal/domain/entities/journal_message_entity.dart`

**Add new enum** (before `JournalMessageEntity` class):
```dart
/// Single authoritative status modeling the entire message pipeline
enum MessageStatus {
  /// Message created locally but not yet processed
  localCreated,

  /// Media file is being uploaded (audio/image only)
  uploadingMedia,

  /// Media file uploaded successfully
  mediaUploaded,

  /// AI processing in progress (transcription or response generation)
  processingAi,

  /// AI processing completed (transcription/analysis done)
  processed,

  /// Message synced to remote Firestore
  remoteCreated,

  /// Terminal failure state
  failed,
}

/// Detailed substatus for failed state to enable targeted retry
enum FailureReason {
  uploadFailed,
  transcriptionFailed,
  aiResponseFailed,
  remoteCreationFailed,
  networkError,
  unknown,
}
```

**Add new fields to `JournalMessageEntity`**:
```dart
class JournalMessageEntity extends Equatable {
  const JournalMessageEntity({
    // ... existing fields

    // NEW: Single pipeline status
    this.status = MessageStatus.localCreated,
    this.failureReason,

    // NEW: Progress and error tracking
    this.uploadProgress,
    this.uploadError,
    this.aiError,
    this.attemptCount = 0,
    this.lastAttemptAt,

    // NEW: Idempotency
    this.clientLocalId,

    // DEPRECATED (keep for backward compatibility during migration)
    this.uploadStatus = UploadStatus.notStarted,
    this.aiProcessingStatus = AiProcessingStatus.pending,
    this.uploadRetryCount = 0,
    this.lastUploadAttemptAt,
  });

  // NEW: Pipeline status
  final MessageStatus status;
  final FailureReason? failureReason;

  // NEW: Progress tracking
  final double? uploadProgress; // 0.0 to 1.0
  final String? uploadError;
  final String? aiError;
  final int attemptCount;
  final DateTime? lastAttemptAt;

  // NEW: Idempotency key for remote writes
  final String? clientLocalId;

  // DEPRECATED: Keep for migration compatibility
  @Deprecated('Use status instead')
  final UploadStatus uploadStatus;

  @Deprecated('Use status instead')
  final AiProcessingStatus aiProcessingStatus;

  @Deprecated('Use attemptCount instead')
  final int uploadRetryCount;

  @Deprecated('Use lastAttemptAt instead')
  final DateTime? lastUploadAttemptAt;

  // ... rest of class
}
```

**Update `copyWith` method** to include new fields.

**Update `props` getter** to include new fields.

#### 2. Update Data Model
**File**: `lib/features/journal/data/models/journal_message_model.dart`

**Add new fields to `JournalMessageModel`**:
```dart
class JournalMessageModel {
  const JournalMessageModel({
    // ... existing fields
    required this.status,
    this.failureReason,
    this.uploadProgress,
    this.uploadError,
    this.aiError,
    required this.attemptCount,
    this.lastAttemptAt,
    this.clientLocalId,

    // Keep deprecated fields for backward compatibility
    required this.uploadStatus,
    required this.aiProcessingStatus,
    required this.uploadRetryCount,
    this.lastUploadAttemptAt,
  });

  final MessageStatus status;
  final FailureReason? failureReason;
  final double? uploadProgress;
  final String? uploadError;
  final String? aiError;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? clientLocalId;

  // Deprecated fields
  final UploadStatus uploadStatus;
  final AiProcessingStatus aiProcessingStatus;
  final int uploadRetryCount;
  final DateTime? lastUploadAttemptAt;
}
```

**Update `toEntity()` method** to map new fields.

**Update `fromEntity()` method** to map new fields.

**Update `toFirestoreMap()` method**:
```dart
Map<String, dynamic> toFirestoreMap() {
  return {
    // ... existing fields
    'status': status.index,
    'failureReason': failureReason?.index,
    'uploadProgress': uploadProgress,
    'uploadError': uploadError,
    'aiError': aiError,
    'attemptCount': attemptCount,
    'lastAttemptAt': lastAttemptAt?.millisecondsSinceEpoch,
    'clientLocalId': clientLocalId,

    // Omit deprecated fields from Firestore to save space
    // Keep only in local database for migration
  };
}
```

**Update `fromFirestore()` factory**:
```dart
factory JournalMessageModel.fromFirestore(Map<String, dynamic> data) {
  return JournalMessageModel(
    // ... existing fields
    status: MessageStatus.values[data['status'] as int? ?? MessageStatus.localCreated.index],
    failureReason: data['failureReason'] != null
      ? FailureReason.values[data['failureReason'] as int]
      : null,
    uploadProgress: (data['uploadProgress'] as num?)?.toDouble(),
    uploadError: data['uploadError'] as String?,
    aiError: data['aiError'] as String?,
    attemptCount: data['attemptCount'] as int? ?? 0,
    lastAttemptAt: data['lastAttemptAt'] != null
      ? DateTime.fromMillisecondsSinceEpoch(data['lastAttemptAt'] as int)
      : null,
    clientLocalId: data['clientLocalId'] as String?,

    // Provide defaults for deprecated fields
    uploadStatus: UploadStatus.notStarted,
    aiProcessingStatus: AiProcessingStatus.pending,
    uploadRetryCount: 0,
    lastUploadAttemptAt: null,
  );
}
```

**Add `toIsarMap()` and `fromIsarMap()` methods** for local storage (keep deprecated fields in Isar during migration).

#### 3. Update Local Data Source Schema
**File**: `lib/features/journal/data/datasources/journal_message_local_datasource.dart`

The Isar schema needs to be updated. Since you're using code generation, update the `@Collection` annotations:

```dart
@collection
class JournalMessageIsar {
  Id id = Isar.autoIncrement;

  // ... existing fields

  // NEW fields
  @enumerated
  late MessageStatus status;

  @enumerated
  FailureReason? failureReason;

  double? uploadProgress;
  String? uploadError;
  String? aiError;
  late int attemptCount;
  DateTime? lastAttemptAt;
  String? clientLocalId;

  // Keep deprecated for migration
  @enumerated
  late UploadStatus uploadStatus;

  @enumerated
  late AiProcessingStatus aiProcessingStatus;

  late int uploadRetryCount;
  DateTime? lastUploadAttemptAt;
}
```

**Run code generation**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. Update Remote Data Source
**File**: `lib/features/journal/data/datasources/journal_message_remote_datasource.dart`

No changes needed - Firestore automatically handles new fields. Ensure `toFirestoreMap()` includes new fields.

### Success Criteria

#### Automated Verification:
- [ ] Code compiles with new fields: `flutter analyze`
- [ ] Schema generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Existing tests pass: `flutter test test/features/journal/`
- [ ] No breaking changes to existing message creation flows

#### Manual Verification:
- [ ] Existing messages load correctly from local database
- [ ] Existing messages sync correctly from Firestore
- [ ] New fields default to appropriate values for existing data
- [ ] Entity copyWith method works with new fields

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that existing messages still load correctly before proceeding to Phase 2.

---

## Phase 2: Infrastructure Layer - MediaUploader and AiServiceClient

### Overview
Create thin `MediaUploader` utility for file uploads and centralized `AiServiceClient` for Cloud Function calls.

### Changes Required

#### 1. Create MediaUploader Utility
**File**: `lib/core/services/media_uploader.dart`

**Purpose**: Thin wrapper around Firebase Storage for file uploads only. No orchestration or business logic.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

/// Result returned from successful upload
class UploadResult {
  const UploadResult({
    required this.remoteUrl,
    required this.metadata,
  });

  final String remoteUrl;
  final Map<String, String> metadata;
}

/// Thin utility for uploading files to Firebase Storage
/// Does NOT handle business logic, orchestration, or state transitions
class MediaUploader {
  MediaUploader(this._storage);

  final FirebaseStorage _storage;

  /// Upload file to specified storage path with progress tracking
  ///
  /// Low-level operation that only handles:
  /// - Reading file bytes
  /// - Uploading to Firebase Storage
  /// - Progress callbacks
  /// - Basic network retry (via Firebase SDK)
  ///
  /// Does NOT:
  /// - Update message status
  /// - Call repositories
  /// - Trigger AI processing
  /// - Implement business retry logic
  Future<Result<UploadResult>> uploadFile({
    required File file,
    required String storagePath,
    required String contentType,
    Map<String, String>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file exists
      if (!file.existsSync()) {
        return const Error(ValidationFailure(message: 'File does not exist'));
      }

      // Read file bytes
      final Uint8List fileBytes = await file.readAsBytes();

      // Create storage reference
      final storageRef = _storage.ref().child(storagePath);

      // Create upload task
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toUtc().toIso8601String(),
            ...?metadata,
          },
        ),
      );

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final totalBytes = snapshot.totalBytes;
          if (totalBytes > 0) {
            final progress = snapshot.bytesTransferred / totalBytes;
            if (progress.isFinite && progress >= 0 && progress <= 1) {
              onProgress(progress);
            }
          }
        });
      }

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Success(UploadResult(
        remoteUrl: downloadUrl,
        metadata: metadata ?? {},
      ));
    } on FirebaseException catch (e) {
      return Error(StorageFailure(
        message: 'Upload failed: ${e.message}',
        code: int.tryParse(e.code),
      ));
    } catch (e) {
      return Error(StorageFailure(message: 'Upload failed: $e'));
    }
  }

  /// Cancel an in-progress upload (if needed for future cancellation support)
  /// Not implemented yet - placeholder for future enhancement
  void cancel(UploadTask task) {
    task.cancel();
  }
}
```

**Register provider**:
**File**: `lib/core/providers/core_providers.dart`

```dart
final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  return MediaUploader(FirebaseStorage.instance);
});
```

#### 2. Create AiServiceClient
**File**: `lib/features/journal/domain/services/ai_service_client.dart`

**Purpose**: Centralized client for all Cloud Function calls with timeout, retry, error mapping.

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/logging/logger.dart';

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
  Future<Result<TranscriptionResult>> transcribeAudio({
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
  Future<Result<ImageAnalysisResult>> analyzeImage({
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
  Future<Result<void>> generateAiResponse({
    required String messageId,
  }) async {
    return _callWithRetry(
      functionName: 'generateMessageResponse',
      params: {
        'messageId': messageId,
      },
      parser: (data) => null, // No return value needed
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
  Future<Result<T>> _callWithRetry<T>({
    required String functionName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic> data) parser,
    required String operationName,
  }) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        logger.i('$operationName attempt ${attempt + 1}/$_maxRetries: $params');

        final callable = _functions.httpsCallable(
          functionName,
          options: HttpsCallableOptions(
            timeout: const Duration(seconds: _timeoutSeconds),
          ),
        );

        final result = await callable.call<Map<String, dynamic>>(params);
        final data = result.data;

        logger.i('$operationName succeeded: $data');

        // Parse response
        final parsed = parser(data);
        return Success(parsed);

      } on FirebaseFunctionsException catch (e) {
        // Check if error is retryable
        final isRetryable = _isRetryableError(e.code);

        if (isRetryable && attempt < _maxRetries - 1) {
          // Wait before retry (exponential backoff)
          final delaySeconds = _retryDelaysSeconds[attempt];
          logger.i(
            '$operationName failed (${e.code}), retrying in ${delaySeconds}s: ${e.message}',
          );
          await Future.delayed(Duration(seconds: delaySeconds));
          attempt++;
          continue;
        }

        // Non-retryable or max retries reached
        logger.i('$operationName failed permanently (${e.code}): ${e.message}');
        return Error(_mapFirebaseFunctionError(e, operationName));

      } catch (e) {
        logger.i('$operationName failed with unexpected error: $e');
        return Error(UnknownFailure(message: '$operationName failed: $e'));
      }
    }

    // Should never reach here
    return Error(ServerFailure(message: '$operationName failed after $attempt attempts'));
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
```

**Register provider**:
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`

```dart
final aiServiceClientProvider = Provider<AiServiceClient>((ref) {
  return AiServiceClient(FirebaseFunctions.instance);
});
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Unit tests pass for MediaUploader: `flutter test test/core/services/media_uploader_test.dart`
- [ ] Unit tests pass for AiServiceClient: `flutter test test/features/journal/domain/services/ai_service_client_test.dart`

#### Manual Verification:
- [ ] MediaUploader can upload a test file to Firebase Storage and return download URL
- [ ] AiServiceClient can call a Cloud Function (use existing `transcribeAudio`) and handle success/error
- [ ] Retry logic works for transient errors (simulate by making function return 'unavailable')
- [ ] Timeout works correctly (simulate by making function sleep for 130s)

**Implementation Note**: Write unit tests for MediaUploader and AiServiceClient before proceeding to Phase 3. Mock Firebase dependencies using mockito.

---

## Phase 3: Cloud Functions - Convert to Callable

### Overview
Convert existing Firestore triggers to callable functions and update backend AI service methods.

### Changes Required

#### 1. Create Transcription Callable Function
**File**: `functions/src/functions/transcription-callable.ts`

**New file** with callable function for audio transcription:

```typescript
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { db } from '../config/firebase';
import { MessageRole } from '../config/constants';

/**
 * Callable function to transcribe audio message
 *
 * Replaces Firestore trigger: triggerAudioTranscription
 * Called explicitly by client after audio upload completes
 */
export const transcribeAudioMessage = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    // 1. Authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // 2. Extract and validate parameters
    const { messageId, audioUrl } = request.data as {
      messageId: string;
      audioUrl: string;
    };

    if (!messageId || !audioUrl) {
      throw new HttpsError(
        'invalid-argument',
        'messageId and audioUrl required'
      );
    }

    console.log(`Transcribing audio for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      // 4. Authorization check - verify user owns the message
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Message not found or access denied'
        );
      }

      // 5. Validate message type
      if (message.role !== MessageRole.USER) {
        throw new HttpsError(
          'invalid-argument',
          'Can only transcribe user messages'
        );
      }

      // 6. Call AI service to transcribe
      const result = await aiService.transcribeAudio(audioUrl);

      console.log(`Transcription complete for message ${messageId}`);

      // 7. Return transcription (client will update message)
      return {
        success: true,
        transcription: result.text,
      };
    } catch (error) {
      console.error(`Transcription failed for message ${messageId}:`, error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Convert other errors
      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Transcription failed: ${message}`);
    }
  }
);
```

#### 2. Create Image Analysis Callable Function
**File**: `functions/src/functions/image-analysis-callable.ts`

**New file** with callable function for image analysis:

```typescript
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { db } from '../config/firebase';
import { MessageRole } from '../config/constants';

/**
 * Callable function to analyze image message content
 *
 * Replaces Firestore trigger: processImageUpload
 * Called explicitly by client after image upload completes
 */
export const analyzeImageMessage = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    // 1. Authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // 2. Extract and validate parameters
    const { messageId, imageUrl } = request.data as {
      messageId: string;
      imageUrl: string;
    };

    if (!messageId || !imageUrl) {
      throw new HttpsError(
        'invalid-argument',
        'messageId and imageUrl required'
      );
    }

    console.log(`Analyzing image for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      // 4. Authorization check
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Message not found or access denied'
        );
      }

      // 5. Validate message type
      if (message.role !== MessageRole.USER) {
        throw new HttpsError(
          'invalid-argument',
          'Can only analyze user messages'
        );
      }

      // 6. Analyze image with AI
      // Build simple prompt for image description
      const prompt = 'Describe what you see in this image. If there is any text, transcribe it accurately.';

      // Note: we're not building full conversation context here
      // Just analyzing the image standalone for transcription/description
      const result = await aiService.generateImageResponse(imageUrl, prompt);

      console.log(`Image analysis complete for message ${messageId}`);

      // 7. Return description (client will update message)
      return {
        success: true,
        description: result.text,
      };
    } catch (error) {
      console.error(`Image analysis failed for message ${messageId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Image analysis failed: ${message}`);
    }
  }
);
```

#### 3. Create AI Response Callable Function
**File**: `functions/src/functions/ai-response-callable.ts`

**New file** with callable function for generating AI response:

```typescript
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { db } from '../config/firebase';
import { MessageRole, MessageType, AiProcessingStatus } from '../config/constants';
import { ConversationBuilder } from '../domain/conversation/conversation-builder';

/**
 * Callable function to generate AI response to a user message
 *
 * Replaces Firestore triggers: processUserMessage, processTranscribedMessage
 * Called explicitly by client after message is ready (text/transcription/image analysis done)
 */
export const generateMessageResponse = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    // 1. Authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // 2. Extract and validate parameters
    const { messageId } = request.data as {
      messageId: string;
    };

    if (!messageId) {
      throw new HttpsError('invalid-argument', 'messageId required');
    }

    console.log(`Generating AI response for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());
    const conversationBuilder = new ConversationBuilder(db);

    try {
      // 4. Authorization check
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Message not found or access denied'
        );
      }

      // 5. Validate message type and role
      if (message.role !== MessageRole.USER) {
        throw new HttpsError(
          'invalid-argument',
          'Can only generate responses for user messages'
        );
      }

      const threadId = message.threadId;

      // 6. Build conversation context
      const context = await conversationBuilder.buildContext(threadId);

      // 7. Generate AI response based on message type
      let aiResponse;

      if (message.messageType === MessageType.TEXT) {
        // Text message - use content directly
        if (!message.content) {
          throw new HttpsError('invalid-argument', 'Text message has no content');
        }
        aiResponse = await aiService.generateTextResponse(
          message.content,
          context
        );
      } else if (message.messageType === MessageType.AUDIO) {
        // Audio message - use transcription
        if (!message.transcription) {
          throw new HttpsError(
            'invalid-argument',
            'Audio message not transcribed yet'
          );
        }
        aiResponse = await aiService.generateTextResponse(
          message.transcription,
          context
        );
      } else if (message.messageType === MessageType.IMAGE) {
        // Image message - use storage URL for multimodal generation
        if (!message.storageUrl) {
          throw new HttpsError(
            'invalid-argument',
            'Image message not uploaded yet'
          );
        }
        aiResponse = await aiService.generateImageResponse(
          message.storageUrl,
          context
        );
      } else {
        throw new HttpsError('invalid-argument', 'Unknown message type');
      }

      // 8. Save AI response as new message
      const responseMessage = {
        id: '', // Will be generated by Firestore
        threadId,
        userId,
        role: MessageRole.AI,
        messageType: MessageType.TEXT,
        content: aiResponse.text,
        createdAtMillis: Date.now(),
        updatedAtMillis: Date.now(),
        aiProcessingStatus: AiProcessingStatus.COMPLETED,
        isDeleted: false,
        version: 1,
      };

      await messageRepo.create(responseMessage);

      console.log(`AI response created for message ${messageId}`);

      // 9. Return success
      return {
        success: true,
        message: 'AI response generated successfully',
      };
    } catch (error) {
      console.error(`AI response generation failed for message ${messageId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `AI response generation failed: ${message}`);
    }
  }
);
```

#### 4. Update Functions Index
**File**: `functions/src/index.ts`

**Add new exports** at the top:

```typescript
// Callable functions (NEW)
export { transcribeAudioMessage } from './functions/transcription-callable';
export { analyzeImageMessage } from './functions/image-analysis-callable';
export { generateMessageResponse } from './functions/ai-response-callable';

// Keep existing exports for now (will be deprecated later)
export { transcribeAudio, triggerAudioTranscription, retryAiResponse } from './functions/transcription';
export { processUserMessage, processImageUpload, processTranscribedMessage } from './functions/message-triggers';
export { generateInsight } from './functions/insights-triggers';
export { onThreadDeleted } from './functions/thread-deletion';
```

#### 5. Deploy New Functions
**Run deployment**:

```bash
cd functions
npm run build
firebase deploy --only functions:transcribeAudioMessage,functions:analyzeImageMessage,functions:generateMessageResponse
```

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compiles: `cd functions && npm run build`
- [ ] Linting passes: `cd functions && npm run lint`
- [ ] Functions deploy successfully: `firebase deploy --only functions:transcribeAudioMessage,functions:analyzeImageMessage,functions:generateMessageResponse`
- [ ] Functions appear in Firebase Console

#### Manual Verification:
- [ ] Call `transcribeAudioMessage` from Firebase Console with test audio URL - returns transcription
- [ ] Call `analyzeImageMessage` from Firebase Console with test image URL - returns description
- [ ] Call `generateMessageResponse` from Firebase Console with test message ID - creates AI response message
- [ ] Verify authentication: calling without auth token returns 'unauthenticated' error
- [ ] Verify authorization: calling with different user's message returns 'permission-denied' error

**Implementation Note**: Test each callable function manually from Firebase Console or using `firebase functions:shell` before integrating with Flutter app.

---

## Phase 4: Repository Simplification

### Overview
Remove business logic from repository, making it pure CRUD that accepts entities with status already set by use cases.

### Changes Required

#### 1. Simplify Message Repository Implementation
**File**: `lib/features/journal/data/repositories/journal_message_repository_impl.dart`

**Refactor `createMessage` method** (lines 24-83):

**Before** (complex business logic):
```dart
@override
Future<Result<JournalMessageEntity>> createMessage(
  JournalMessageEntity message,
) async {
  try {
    final messageModel = JournalMessageModel.fromEntity(message);
    await localDataSource.saveMessage(messageModel);

    // Try remote save
    try {
      await remoteDataSource.saveMessage(messageModel);

      // For text messages or non-user messages, mark as completed immediately
      if (message.role != MessageRole.user ||
          message.messageType == MessageType.text) {
        final updatedMessage = message.copyWith(
          uploadStatus: UploadStatus.completed,
        );
        final updatedModel = JournalMessageModel.fromEntity(updatedMessage);
        await localDataSource.saveMessage(updatedModel);
        return Success(updatedMessage);
      }

      return Success(message);
    } on NetworkException catch (e) {
      // Network failure handling - different for media vs text
      if (message.role == MessageRole.user &&
          message.messageType != MessageType.text) {
        // For media messages, mark as failed
        final updatedMessage = message.copyWith(
          uploadStatus: UploadStatus.failed,
          uploadRetryCount: message.uploadRetryCount + 1,
          lastUploadAttemptAt: DateTime.now().toUtc(),
        );
        final updatedModel = JournalMessageModel.fromEntity(updatedMessage);
        await localDataSource.saveMessage(updatedModel);
        return Error(e);
      } else {
        // For text messages, mark as not started
        final updatedMessage = message.copyWith(
          uploadStatus: UploadStatus.notStarted,
        );
        final updatedModel = JournalMessageModel.fromEntity(updatedMessage);
        await localDataSource.saveMessage(updatedModel);
        return Success(updatedMessage);
      }
    }
    // ... more error handling
  } catch (e) {
    return Error(UnknownFailure(message: 'Failed to create message: $e'));
  }
}
```

**After** (pure CRUD):
```dart
@override
Future<Result<JournalMessageEntity>> createMessage(
  JournalMessageEntity message,
) async {
  try {
    final messageModel = JournalMessageModel.fromEntity(message);

    // Always save to local first (guaranteed to succeed)
    await localDataSource.saveMessage(messageModel);

    // Try remote save (best effort)
    try {
      await remoteDataSource.saveMessage(messageModel);
    } on NetworkException catch (e) {
      logger.i('Remote save failed (network), will sync later: $e');
      // Don't fail operation - local save succeeded
    } on ServerException catch (e) {
      logger.i('Remote save failed (server): $e');
      // Don't fail operation - local save succeeded
    }

    // Return entity as-is (status set by use case)
    return Success(message);

  } catch (e) {
    // Only local save errors are actual failures
    return Error(CacheFailure(message: 'Failed to save message locally: $e'));
  }
}
```

**Refactor `updateMessage` method** (lines 129-155):

**After** (simplified):
```dart
@override
Future<Result<void>> updateMessage(JournalMessageEntity message) async {
  try {
    final messageModel = JournalMessageModel.fromEntity(message);

    // Always update local first
    await localDataSource.updateMessage(messageModel);

    // Try remote update (best effort)
    try {
      await remoteDataSource.updateMessage(messageModel);
    } on NetworkException catch (e) {
      logger.i('Remote update failed (network): $e');
      // Don't fail operation
    } on ServerException catch (e) {
      logger.i('Remote update failed (server): $e');
      // Don't fail operation
    }

    return const Success(null);

  } catch (e) {
    return Error(CacheFailure(message: 'Failed to update message locally: $e'));
  }
}
```

**Remove business logic from `syncThreadIncremental`** (lines 177-252):

Simplified version that just merges remote data without status manipulation:

```dart
@override
Future<Result<void>> syncThreadIncremental(String threadId) async {
  try {
    // Get last sync timestamp from local
    final since = (await localDataSource.getLastUpdatedAtMillis(threadId)) ?? 0;

    // Fetch updated messages from remote
    final remoteResult = await remoteDataSource.getUpdatedMessages(threadId, since);

    if (remoteResult.isError) {
      return Error(remoteResult.failureOrNull!);
    }

    final remoteMessages = remoteResult.dataOrNull!;

    // Upsert all remote messages to local
    for (final remoteModel in remoteMessages) {
      await localDataSource.upsertFromRemote(remoteModel);
    }

    return const Success(null);

  } catch (e) {
    return Error(UnknownFailure(message: 'Sync failed: $e'));
  }
}
```

**Remove business logic from `watchMessagesByThreadId`** (lines 96-126):

Already relatively clean, but ensure no status manipulation:

```dart
@override
Stream<List<JournalMessageEntity>> watchMessagesByThreadId(
  String threadId,
) async* {
  StreamSubscription<List<JournalMessageModel>>? remoteSub;

  try {
    // Get last sync timestamp
    final since = (await localDataSource.getLastUpdatedAtMillis(threadId)) ?? 0;

    // Set up remote listener that auto-upserts to local
    remoteSub = remoteDataSource.watchUpdatedMessages(threadId, since).listen(
      (remoteModels) async {
        for (final remoteModel in remoteModels) {
          await localDataSource.upsertFromRemote(remoteModel);
        }
      },
      onError: (Object error) {
        logger.i('Remote sync error (transient): $error');
      },
    );

    // Always yield local stream
    yield* localDataSource
        .watchMessagesByThreadId(threadId)
        .map((models) => models.map((m) => m.toEntity()).toList());

  } finally {
    await remoteSub?.cancel();
  }
}
```

#### 2. Update Repository Interface (Optional)
**File**: `lib/features/journal/domain/repositories/journal_message_repository.dart`

Add documentation clarifying repository responsibilities:

```dart
/// Repository for journal messages - coordinates local and remote data sources
///
/// Responsibilities:
/// - Pure CRUD operations (create, read, update, delete)
/// - Coordinate between local (Isar) and remote (Firestore) data sources
/// - Provide streams for reactive UI updates
///
/// Does NOT handle:
/// - Business logic or state transitions
/// - File uploads or AI processing
/// - Retry logic or error recovery
/// - Status manipulation based on message type
///
/// Use cases are responsible for setting correct status before calling repository.
abstract class JournalMessageRepository {
  /// Create new message
  ///
  /// Always saves to local database first, then attempts remote save.
  /// Returns success if local save succeeds, even if remote fails.
  /// Entity should have status set by use case before calling.
  Future<Result<JournalMessageEntity>> createMessage(JournalMessageEntity message);

  /// Update existing message
  ///
  /// Updates local database first, then attempts remote update.
  /// Returns success if local update succeeds, even if remote fails.
  /// Entity should have status set by use case before calling.
  Future<Result<void>> updateMessage(JournalMessageEntity message);

  // ... rest of interface
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Repository tests pass (update tests to remove business logic expectations): `flutter test test/features/journal/data/repositories/`
- [ ] No if/else logic based on `messageType` or `role` remains in repository

#### Manual Verification:
- [ ] Repository creates message with status as-is (doesn't modify it)
- [ ] Repository updates message with status as-is (doesn't modify it)
- [ ] Network failures during remote operations don't fail the operation (logged only)
- [ ] Local failures fail the operation (return Error)

**Implementation Note**: Update existing repository tests to reflect new simplified behavior. Remove tests that verify business logic (since it's moved to use cases).

---

## Phase 5: Use Cases - Pipeline Orchestration

### Overview
Implement new use cases that orchestrate the full message pipeline, emitting status updates at each step.

### Changes Required

#### 1. Update Create Text Message Use Case
**File**: `lib/features/journal/domain/usecases/create_text_message_usecase.dart`

**Refactor to orchestrate full pipeline with status emissions**:

```dart
import 'package:uuid/uuid.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:kairos/core/logging/logger.dart';

class CreateTextMessageParams {
  const CreateTextMessageParams({
    required this.userId,
    required this.content,
    this.threadId,
  });

  final String userId;
  final String content;
  final String? threadId;
}

/// Use case for creating text messages with full pipeline orchestration
///
/// Pipeline steps:
/// 1. Create message locally (status: localCreated)
/// 2. Create remote message (status: remoteCreated)
/// 3. Request AI response (status: processingAi)
///
/// Emits status updates via stream for UI display
class CreateTextMessageUseCase {
  CreateTextMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.aiServiceClient,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final AiServiceClient aiServiceClient;

  final _uuid = const Uuid();

  /// Execute use case with status stream
  ///
  /// Returns stream that emits message entity with updated status at each step.
  /// Final emission is either success (status: processingAi) or failure (status: failed).
  Stream<Result<JournalMessageEntity>> call(CreateTextMessageParams params) async* {
    try {
      // Validate content
      if (params.content.trim().isEmpty) {
        yield const Error(ValidationFailure(message: 'Message content cannot be empty'));
        return;
      }

      // Determine thread ID (create thread if needed)
      String threadId = params.threadId ?? _uuid.v4();

      if (params.threadId == null) {
        // Create new thread
        final threadTitle = params.content.length > 50
            ? '${params.content.substring(0, 50)}...'
            : params.content;

        final thread = JournalThreadEntity(
          id: threadId,
          userId: params.userId,
          title: threadTitle,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastMessageAt: DateTime.now().toUtc(),
          messageCount: 0,
        );

        final threadResult = await threadRepository.createThread(thread);
        if (threadResult.isError) {
          yield Error(threadResult.failureOrNull!);
          return;
        }
      }

      // STEP 1: Create message locally
      final messageId = _uuid.v4();
      final clientLocalId = _uuid.v4(); // For idempotency

      var message = JournalMessageEntity(
        id: messageId,
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.text,
        content: params.content,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: MessageStatus.localCreated, // Initial status
        clientLocalId: clientLocalId,
        attemptCount: 0,
      );

      logger.i('Creating text message locally: $messageId');

      final createResult = await messageRepository.createMessage(message);
      if (createResult.isError) {
        yield Error(createResult.failureOrNull!);
        return;
      }

      // Emit: message created locally
      yield Success(message);

      // STEP 2: Create remote message
      message = message.copyWith(status: MessageStatus.remoteCreated);

      logger.i('Updating message to remoteCreated: $messageId');

      final remoteResult = await messageRepository.updateMessage(message);
      if (remoteResult.isError) {
        // Mark as failed
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.remoteCreationFailed,
          aiError: 'Failed to sync message to server',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(remoteResult.failureOrNull!);
        return;
      }

      // Emit: message synced to remote
      yield Success(message);

      // STEP 3: Request AI response
      message = message.copyWith(status: MessageStatus.processingAi);

      logger.i('Requesting AI response for message: $messageId');

      await messageRepository.updateMessage(message);
      yield Success(message);

      final aiResult = await aiServiceClient.generateAiResponse(messageId: messageId);

      if (aiResult.isError) {
        // Mark as failed
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: aiResult.failureOrNull?.message ?? 'AI response failed',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(aiResult.failureOrNull!);
        return;
      }

      // Success! AI response will be created by backend and appear via stream
      logger.i('Text message pipeline complete: $messageId');

      // Final status remains processingAi since we're waiting for backend response
      yield Success(message);

      // Update thread metadata
      await _updateThreadMetadata(threadId);

    } catch (e) {
      logger.i('Unexpected error in CreateTextMessageUseCase: $e');
      yield Error(UnknownFailure(message: 'Failed to create text message: $e'));
    }
  }

  Future<void> _updateThreadMetadata(String threadId) async {
    final threadResult = await threadRepository.getThreadById(threadId);
    if (threadResult.isSuccess) {
      final thread = threadResult.dataOrNull!;
      final updatedThread = thread.copyWith(
        lastMessageAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        messageCount: thread.messageCount + 1,
      );
      await threadRepository.updateThread(updatedThread);
    }
  }
}
```

#### 2. Update Create Audio Message Use Case
**File**: `lib/features/journal/domain/usecases/create_audio_message_usecase.dart`

**Refactor to orchestrate: create → upload → transcribe → update → remote sync → AI response**:

```dart
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/services/media_uploader.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kairos/core/logging/logger.dart';

class CreateAudioMessageParams {
  const CreateAudioMessageParams({
    required this.userId,
    required this.audioFile,
    required this.durationSeconds,
    this.threadId,
  });

  final String userId;
  final File audioFile;
  final int durationSeconds;
  final String? threadId;
}

/// Use case for creating audio messages with full pipeline orchestration
///
/// Pipeline steps:
/// 1. Create message locally (status: localCreated)
/// 2. Upload audio file (status: uploadingMedia → mediaUploaded)
/// 3. Transcribe audio (status: processingAi)
/// 4. Update with transcription (status: processed)
/// 5. Create remote message (status: remoteCreated)
/// 6. Request AI response (status: processingAi)
class CreateAudioMessageUseCase {
  CreateAudioMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.mediaUploader,
    required this.aiServiceClient,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final MediaUploader mediaUploader;
  final AiServiceClient aiServiceClient;

  final _uuid = const Uuid();

  Stream<Result<JournalMessageEntity>> call(CreateAudioMessageParams params) async* {
    try {
      // Validate audio file
      if (!params.audioFile.existsSync()) {
        yield const Error(ValidationFailure(message: 'Audio file does not exist'));
        return;
      }

      // Determine thread ID
      String threadId = params.threadId ?? _uuid.v4();

      if (params.threadId == null) {
        final thread = JournalThreadEntity(
          id: threadId,
          userId: params.userId,
          title: 'Audio Journal',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastMessageAt: DateTime.now().toUtc(),
          messageCount: 0,
        );

        final threadResult = await threadRepository.createThread(thread);
        if (threadResult.isError) {
          yield Error(threadResult.failureOrNull!);
          return;
        }
      }

      // STEP 1: Create message locally
      final messageId = _uuid.v4();
      final clientLocalId = _uuid.v4();

      var message = JournalMessageEntity(
        id: messageId,
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.audio,
        localFilePath: params.audioFile.path,
        audioDurationSeconds: params.durationSeconds,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: MessageStatus.localCreated,
        clientLocalId: clientLocalId,
        attemptCount: 0,
      );

      logger.i('Creating audio message locally: $messageId');

      final createResult = await messageRepository.createMessage(message);
      if (createResult.isError) {
        yield Error(createResult.failureOrNull!);
        return;
      }

      yield Success(message);

      // STEP 2: Upload audio file
      message = message.copyWith(
        status: MessageStatus.uploadingMedia,
        uploadProgress: 0.0,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      final storagePath = 'users/${params.userId}/journals/$threadId/$messageId.m4a';

      logger.i('Uploading audio file: $messageId');

      final uploadResult = await mediaUploader.uploadFile(
        file: params.audioFile,
        storagePath: storagePath,
        contentType: 'audio/mp4',
        metadata: {
          'messageId': messageId,
          'threadId': threadId,
          'type': 'audio',
          'durationSeconds': params.durationSeconds.toString(),
        },
        onProgress: (progress) async {
          // Update progress in entity
          message = message.copyWith(uploadProgress: progress);
          await messageRepository.updateMessage(message);
          // Note: Not yielding here to avoid too many emissions
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

        yield Error(uploadResult.failureOrNull!);
        return;
      }

      final audioUrl = uploadResult.dataOrNull!.remoteUrl;

      message = message.copyWith(
        status: MessageStatus.mediaUploaded,
        storageUrl: audioUrl,
        uploadProgress: 1.0,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 3: Transcribe audio
      message = message.copyWith(status: MessageStatus.processingAi);
      await messageRepository.updateMessage(message);
      yield Success(message);

      logger.i('Transcribing audio: $messageId');

      final transcriptionResult = await aiServiceClient.transcribeAudio(
        messageId: messageId,
        audioUrl: audioUrl,
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

        yield Error(transcriptionResult.failureOrNull!);
        return;
      }

      // STEP 4: Update with transcription
      final transcription = transcriptionResult.dataOrNull!.transcription;

      message = message.copyWith(
        status: MessageStatus.processed,
        transcription: transcription,
        content: transcription, // Use transcription as content
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 5: Create remote message
      message = message.copyWith(status: MessageStatus.remoteCreated);
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 6: Request AI response
      message = message.copyWith(status: MessageStatus.processingAi);
      await messageRepository.updateMessage(message);
      yield Success(message);

      logger.i('Requesting AI response for audio message: $messageId');

      final aiResult = await aiServiceClient.generateAiResponse(messageId: messageId);

      if (aiResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: aiResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(aiResult.failureOrNull!);
        return;
      }

      logger.i('Audio message pipeline complete: $messageId');
      yield Success(message);

      await _updateThreadMetadata(threadId);

    } catch (e) {
      logger.i('Unexpected error in CreateAudioMessageUseCase: $e');
      yield Error(UnknownFailure(message: 'Failed to create audio message: $e'));
    }
  }

  Future<void> _updateThreadMetadata(String threadId) async {
    final threadResult = await threadRepository.getThreadById(threadId);
    if (threadResult.isSuccess) {
      final thread = threadResult.dataOrNull!;
      final updatedThread = thread.copyWith(
        lastMessageAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        messageCount: thread.messageCount + 1,
      );
      await threadRepository.updateThread(updatedThread);
    }
  }
}
```

#### 3. Update Create Image Message Use Case
**File**: `lib/features/journal/domain/usecases/create_image_message_usecase.dart`

**Refactor to orchestrate: create → upload → analyze → update → remote sync → AI response**:

Similar structure to audio, but:
- Upload image (with thumbnail)
- Call `aiServiceClient.analyzeImage()` instead of `transcribeAudio()`
- Update with description instead of transcription

```dart
// Similar implementation to CreateAudioMessageUseCase
// Replace transcription step with image analysis:

// STEP 3: Analyze image
message = message.copyWith(status: MessageStatus.processingAi);
await messageRepository.updateMessage(message);
yield Success(message);

logger.i('Analyzing image: $messageId');

final analysisResult = await aiServiceClient.analyzeImage(
  messageId: messageId,
  imageUrl: imageUrl,
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

  yield Error(analysisResult.failureOrNull!);
  return;
}

// STEP 4: Update with description
final description = analysisResult.dataOrNull!.description;

message = message.copyWith(
  status: MessageStatus.processed,
  content: description, // Use image description as content
);
await messageRepository.updateMessage(message);
yield Success(message);

// Continue with remote sync and AI response...
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Use case tests pass: `flutter test test/features/journal/domain/usecases/`

#### Manual Verification:
- [ ] Text message creation shows status progression: localCreated → remoteCreated → processingAi
- [ ] Audio message creation shows: localCreated → uploadingMedia → mediaUploaded → processingAi → processed → remoteCreated → processingAi
- [ ] Image message creation shows: localCreated → uploadingMedia → mediaUploaded → processingAi → processed → remoteCreated → processingAi
- [ ] Upload progress updates (0.0 to 1.0) visible during file upload
- [ ] Failed operations show status: failed with appropriate failureReason
- [ ] UI can display status messages based on MessageStatus enum

**Implementation Note**: Update UI controllers to listen to use case streams and display appropriate status messages for each MessageStatus value.

---

## Phase 6: Retry Logic - RetryMessagePipelineUseCase

### Overview
Implement resumable retry logic that picks up where the pipeline left off based on current message status.

### Changes Required

#### 1. Create Retry Use Case
**File**: `lib/features/journal/domain/usecases/retry_message_pipeline_usecase.dart`

```dart
import 'dart:io';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/services/media_uploader.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:kairos/core/logging/logger.dart';

/// Use case for retrying/resuming failed or interrupted message pipelines
///
/// Stateless retry logic:
/// 1. Read current message status from repository
/// 2. Determine next step based on status and failureReason
/// 3. Execute that step
/// 4. Update status and continue or stop
///
/// Idempotent: safe to call multiple times on same message
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
  /// Returns stream of status updates as pipeline progresses
  Stream<Result<JournalMessageEntity>> call(String messageId) async* {
    try {
      // Step 1: Get current message state
      final messageResult = await messageRepository.getMessageById(messageId);

      if (messageResult.isError) {
        yield Error(messageResult.failureOrNull!);
        return;
      }

      var message = messageResult.dataOrNull!;

      // Step 2: Check if max attempts reached
      if (message.attemptCount >= _maxAttempts) {
        logger.i('Max retry attempts reached for message $messageId');
        yield const Error(ValidationFailure(
          message: 'Maximum retry attempts reached (5). Please contact support.',
        ));
        return;
      }

      // Step 3: Check backoff period
      if (message.lastAttemptAt != null) {
        final backoffIndex = message.attemptCount.clamp(0, _backoffSeconds.length - 1);
        final requiredBackoffSeconds = _backoffSeconds[backoffIndex];
        final timeSinceLastAttempt = DateTime.now().difference(message.lastAttemptAt!).inSeconds;

        if (timeSinceLastAttempt < requiredBackoffSeconds) {
          final remainingSeconds = requiredBackoffSeconds - timeSinceLastAttempt;
          yield Error(ValidationFailure(
            message: 'Please wait $remainingSeconds seconds before retrying',
          ));
          return;
        }
      }

      logger.i('Retrying message pipeline: $messageId (status: ${message.status}, attempt: ${message.attemptCount})');

      // Step 4: Resume based on current status
      yield* _resumeFromStatus(message);

    } catch (e) {
      logger.i('Unexpected error in RetryMessagePipelineUseCase: $e');
      yield Error(UnknownFailure(message: 'Retry failed: $e'));
    }
  }

  /// Resume pipeline based on message status
  Stream<Result<JournalMessageEntity>> _resumeFromStatus(
    JournalMessageEntity message,
  ) async* {
    switch (message.status) {
      case MessageStatus.localCreated:
      case MessageStatus.failed when message.failureReason == FailureReason.uploadFailed:
        // Need to upload media
        yield* _uploadMediaStep(message);
        break;

      case MessageStatus.uploadingMedia:
        // Was interrupted during upload - restart upload
        yield* _uploadMediaStep(message);
        break;

      case MessageStatus.mediaUploaded:
      case MessageStatus.failed when message.failureReason == FailureReason.transcriptionFailed:
        // Need to transcribe/analyze
        yield* _processAiStep(message);
        break;

      case MessageStatus.processed:
      case MessageStatus.failed when message.failureReason == FailureReason.remoteCreationFailed:
        // Need to create remote
        yield* _createRemoteStep(message);
        break;

      case MessageStatus.remoteCreated:
      case MessageStatus.failed when message.failureReason == FailureReason.aiResponseFailed:
        // Need to request AI response
        yield* _requestAiResponseStep(message);
        break;

      case MessageStatus.processingAi:
        // Already processing - just re-request
        yield* _requestAiResponseStep(message);
        break;

      default:
        yield const Error(ValidationFailure(
          message: 'Message is not in a retryable state',
        ));
    }
  }

  /// Upload media files (audio/image)
  Stream<Result<JournalMessageEntity>> _uploadMediaStep(
    JournalMessageEntity message,
  ) async* {
    if (message.messageType == MessageType.text) {
      // Text messages don't need upload - skip to remote creation
      yield* _createRemoteStep(message);
      return;
    }

    if (message.localFilePath == null) {
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.uploadFailed,
        uploadError: 'No local file path',
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      yield Error(ValidationFailure(message: 'No local file path for upload'));
      return;
    }

    final file = File(message.localFilePath!);
    if (!file.existsSync()) {
      message = message.copyWith(
        status: MessageStatus.failed,
        failureReason: FailureReason.uploadFailed,
        uploadError: 'Local file no longer exists',
        attemptCount: message.attemptCount + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );
      await messageRepository.updateMessage(message);
      yield Error(ValidationFailure(message: 'Local file no longer exists'));
      return;
    }

    // Update status to uploading
    message = message.copyWith(
      status: MessageStatus.uploadingMedia,
      uploadProgress: 0.0,
      uploadError: null, // Clear previous error
    );
    await messageRepository.updateMessage(message);
    yield Success(message);

    // Determine content type and storage path
    final contentType = message.messageType == MessageType.audio ? 'audio/mp4' : 'image/jpeg';
    final extension = message.messageType == MessageType.audio ? 'm4a' : 'jpg';
    final storagePath = 'users/${message.userId}/journals/${message.threadId}/${message.id}.$extension';

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
      yield Error(uploadResult.failureOrNull!);
      return;
    }

    // Upload succeeded
    message = message.copyWith(
      status: MessageStatus.mediaUploaded,
      storageUrl: uploadResult.dataOrNull!.remoteUrl,
      uploadProgress: 1.0,
    );
    await messageRepository.updateMessage(message);
    yield Success(message);

    // Continue to next step
    yield* _processAiStep(message);
  }

  /// Process AI (transcription or image analysis)
  Stream<Result<JournalMessageEntity>> _processAiStep(
    JournalMessageEntity message,
  ) async* {
    message = message.copyWith(
      status: MessageStatus.processingAi,
      aiError: null, // Clear previous error
    );
    await messageRepository.updateMessage(message);
    yield Success(message);

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
        yield Error(ValidationFailure(message: 'No audio URL'));
        return;
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
        yield Error(transcriptionResult.failureOrNull!);
        return;
      }

      message = message.copyWith(
        status: MessageStatus.processed,
        transcription: transcriptionResult.dataOrNull!.transcription,
        content: transcriptionResult.dataOrNull!.transcription,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

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
        yield Error(ValidationFailure(message: 'No image URL'));
        return;
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
        yield Error(analysisResult.failureOrNull!);
        return;
      }

      message = message.copyWith(
        status: MessageStatus.processed,
        content: analysisResult.dataOrNull!.description,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

    } else {
      // Text message - skip this step
      message = message.copyWith(status: MessageStatus.processed);
      await messageRepository.updateMessage(message);
      yield Success(message);
    }

    // Continue to next step
    yield* _createRemoteStep(message);
  }

  /// Create remote message (sync to Firestore)
  Stream<Result<JournalMessageEntity>> _createRemoteStep(
    JournalMessageEntity message,
  ) async* {
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
      yield Error(updateResult.failureOrNull!);
      return;
    }

    yield Success(message);

    // Continue to next step
    yield* _requestAiResponseStep(message);
  }

  /// Request AI response generation
  Stream<Result<JournalMessageEntity>> _requestAiResponseStep(
    JournalMessageEntity message,
  ) async* {
    logger.i('Requesting AI response for message ${message.id}');

    message = message.copyWith(
      status: MessageStatus.processingAi,
      aiError: null,
    );
    await messageRepository.updateMessage(message);
    yield Success(message);

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
      yield Error(aiResult.failureOrNull!);
      return;
    }

    // Success - pipeline complete
    logger.i('Message pipeline complete (retry): ${message.id}');
    yield Success(message);
  }
}
```

#### 2. Register Use Case Provider
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`

```dart
final retryMessagePipelineUseCaseProvider = Provider<RetryMessagePipelineUseCase>((ref) {
  return RetryMessagePipelineUseCase(
    messageRepository: ref.watch(messageRepositoryProvider),
    mediaUploader: ref.watch(mediaUploaderProvider),
    aiServiceClient: ref.watch(aiServiceClientProvider),
  );
});
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Use case tests pass: `flutter test test/features/journal/domain/usecases/retry_message_pipeline_usecase_test.dart`

#### Manual Verification:
- [ ] Retry use case can resume from localCreated status
- [ ] Retry use case can resume from uploadingMedia status (restarts upload)
- [ ] Retry use case can resume from mediaUploaded status (transcribes/analyzes)
- [ ] Retry use case can resume from processed status (creates remote)
- [ ] Retry use case can resume from remoteCreated status (requests AI response)
- [ ] Retry use case respects exponential backoff (shows "wait X seconds" message)
- [ ] Retry use case stops after 5 attempts (shows "maximum attempts" message)
- [ ] Idempotent: calling retry multiple times on same message doesn't cause duplicates

**Implementation Note**: Create unit tests that mock each step and verify retry logic for all status transitions.

---

## Phase 7: UI Integration - Status Display and Retry Buttons

### Overview
Update UI to display granular status messages and add manual retry buttons for failed messages.

### Changes Required

#### 1. Add Status Display Helper
**File**: `lib/features/journal/presentation/utils/message_status_display.dart`

```dart
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

/// Helper for converting MessageStatus to user-friendly display text
class MessageStatusDisplay {
  /// Get display text for message status
  static String getStatusText(JournalMessageEntity message) {
    switch (message.status) {
      case MessageStatus.localCreated:
        return 'Sending...';

      case MessageStatus.uploadingMedia:
        final progress = message.uploadProgress ?? 0.0;
        final percentage = (progress * 100).toInt();
        final mediaType = message.messageType == MessageType.audio ? 'audio' : 'image';
        return 'Uploading $mediaType $percentage%';

      case MessageStatus.mediaUploaded:
        return 'Uploaded';

      case MessageStatus.processingAi:
        if (message.transcription == null && message.messageType == MessageType.audio) {
          return 'Transcribing audio...';
        } else if (message.content == null && message.messageType == MessageType.image) {
          return 'Analyzing image...';
        } else {
          return 'AI is thinking...';
        }

      case MessageStatus.processed:
        return 'Processed';

      case MessageStatus.remoteCreated:
        return 'Waiting for AI response...';

      case MessageStatus.failed:
        return 'Failed';
    }
  }

  /// Get error message for failed status
  static String? getErrorText(JournalMessageEntity message) {
    if (message.status != MessageStatus.failed) {
      return null;
    }

    switch (message.failureReason) {
      case FailureReason.uploadFailed:
        return message.uploadError ?? 'Upload failed. Please try again.';

      case FailureReason.transcriptionFailed:
      case FailureReason.aiResponseFailed:
        return message.aiError ?? 'AI processing failed. Please try again.';

      case FailureReason.remoteCreationFailed:
        return 'Failed to sync to server. Please check your connection.';

      case FailureReason.networkError:
        return 'Network error. Please check your internet connection.';

      case FailureReason.unknown:
      case null:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if message is retryable
  static bool isRetryable(JournalMessageEntity message) {
    return message.status == MessageStatus.failed && message.attemptCount < 5;
  }

  /// Get retry button text
  static String getRetryButtonText(JournalMessageEntity message) {
    if (message.attemptCount == 0) {
      return 'Retry';
    } else {
      return 'Retry (${message.attemptCount}/5)';
    }
  }
}
```

#### 2. Update Message Bubble Widget
**File**: `lib/features/journal/presentation/widgets/message_bubble.dart`

**Add status indicator and retry button** to message bubble:

```dart
// Inside message bubble build method, add status indicator for user messages:

if (message.role == MessageRole.user && message.status != MessageStatus.remoteCreated) {
  // Show status indicator
  Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.status == MessageStatus.uploadingMedia ||
            message.status == MessageStatus.processingAi) ...[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        if (message.status == MessageStatus.failed) ...[
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 8),
        ],
        Text(
          MessageStatusDisplay.getStatusText(message),
          style: TextStyle(
            fontSize: 12,
            color: message.status == MessageStatus.failed
              ? Colors.red
              : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  ),
}

// Show error message and retry button for failed messages
if (message.status == MessageStatus.failed) {
  Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          MessageStatusDisplay.getErrorText(message) ?? 'Error occurred',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
          ),
        ),
        if (MessageStatusDisplay.isRetryable(message)) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _handleRetry(message.id),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(MessageStatusDisplay.getRetryButtonText(message)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ] else if (message.attemptCount >= 5) ...[
          const SizedBox(height: 8),
          const Text(
            'Maximum retry attempts reached. Please contact support.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    ),
  ),
}
```

**Add retry handler method**:

```dart
void _handleRetry(String messageId) async {
  final retryUseCase = ref.read(retryMessagePipelineUseCaseProvider);

  // Show loading indicator
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Retrying...')),
  );

  // Execute retry use case
  await for (final result in retryUseCase(messageId)) {
    if (!mounted) break;

    result.when(
      success: (message) {
        // Status updates handled by repository stream
        // Just log for debugging
        logger.i('Retry progress: ${message.status}');
      },
      error: (failure) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: ${failure.message}')),
        );
      },
    );
  }
}
```

#### 3. Update Message Controller
**File**: `lib/features/journal/presentation/controllers/message_controller.dart`

**Update to use stream-based use cases**:

```dart
// For text messages
Future<void> createTextMessage(String content, String threadId) async {
  state = const MessageLoading();

  final params = CreateTextMessageParams(
    userId: _currentUserId,
    content: content,
    threadId: threadId,
  );

  // Listen to use case stream for status updates
  await for (final result in _createTextMessageUseCase(params)) {
    result.when(
      success: (message) {
        // Update state with message status
        state = MessageSuccess(message: message);

        // Log status for debugging
        logger.i('Text message status: ${message.status}');
      },
      error: (failure) {
        state = MessageError(message: failure.message);
      },
    );
  }
}

// Similar updates for createAudioMessage and createImageMessage
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Widget tests pass: `flutter test test/features/journal/presentation/`

#### Manual Verification:
- [ ] Text message shows "Sending..." → "Waiting for AI response..." → disappears when AI responds
- [ ] Audio message shows "Uploading audio X%" → "Transcribing audio..." → "AI is thinking..." → disappears
- [ ] Image message shows "Uploading image X%" → "Analyzing image..." → "AI is thinking..." → disappears
- [ ] Failed messages show red error icon and error message
- [ ] Retry button appears on failed messages (if attempts < 5)
- [ ] Clicking retry button starts retry pipeline and updates status
- [ ] Messages with 5 failed attempts show "Maximum retry attempts reached" message
- [ ] Progress indicator (spinner) appears during processing states

**Implementation Note**: Test all status transitions manually by simulating failures (disconnect network, make Cloud Function return errors, etc.).

---

## Phase 8: Migration and Cleanup

### Overview
Remove old code, delete deprecated services, and remove Firestore triggers.

### Changes Required

#### 1. Delete Journal Upload Service
**File**: `lib/features/journal/domain/services/journal_upload_service.dart`

**Delete entire file** - functionality moved to use cases.

**Remove from providers**:
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`

```dart
// DELETE this provider:
// final journalUploadServiceProvider = Provider<JournalUploadService>(...);
```

#### 2. Remove Deprecated Fields from Entity
**File**: `lib/features/journal/domain/entities/journal_message_entity.dart`

**Remove deprecated fields**:

```dart
// DELETE these fields:
// @Deprecated('Use status instead')
// final UploadStatus uploadStatus;
//
// @Deprecated('Use status instead')
// final AiProcessingStatus aiProcessingStatus;
//
// @Deprecated('Use attemptCount instead')
// final int uploadRetryCount;
//
// @Deprecated('Use lastAttemptAt instead')
// final DateTime? lastUploadAttemptAt;
```

**Remove from constructors, copyWith, props, etc.**

#### 3. Update Data Model
**File**: `lib/features/journal/data/models/journal_message_model.dart`

**Remove deprecated fields** from model, toFirestoreMap, fromFirestore, toEntity, fromEntity.

#### 4. Update Isar Schema
**File**: `lib/features/journal/data/datasources/journal_message_local_datasource.dart`

**Remove deprecated fields** from `@Collection` class.

**Run code generation**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Note**: Isar will handle migration automatically when schema changes.

#### 5. Remove Firestore Triggers from Backend
**File**: `functions/src/functions/message-triggers.ts`

**Comment out or delete** these exports from `functions/src/index.ts`:

```typescript
// DEPRECATED: Replaced by callable functions
// export { processUserMessage, processImageUpload, processTranscribedMessage } from './functions/message-triggers';
```

**File**: `functions/src/functions/transcription.ts`

**Comment out or delete**:

```typescript
// DEPRECATED: Replaced by transcribeAudioMessage callable
// export { triggerAudioTranscription } from './functions/transcription';
```

**Deploy to remove functions**:

```bash
cd functions
npm run build
firebase deploy --only functions
```

**Note**: Firebase will automatically remove functions that are no longer exported.

#### 6. Remove Old Controller Code
**File**: `lib/features/journal/presentation/controllers/message_controller.dart`

**Remove old fire-and-forget upload calls** (lines that called `uploadService.uploadAudioMessage`, etc.).

#### 7. Clean Up Imports

Run throughout codebase:
- Remove imports of `JournalUploadService`
- Remove imports of deprecated enums (`UploadStatus`, `AiProcessingStatus` if not used elsewhere)
- Remove unused imports

**Run**:
```bash
flutter analyze
flutter pub run dart_code_metrics:metrics check-unused-files lib
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] No warnings about deprecated fields
- [ ] All tests pass: `flutter test`
- [ ] Unused imports removed
- [ ] Firebase Functions deploy successfully: `firebase deploy --only functions`
- [ ] Old functions no longer appear in Firebase Console

#### Manual Verification:
- [ ] App runs without errors
- [ ] Creating messages works with new pipeline
- [ ] No references to `JournalUploadService` remain in codebase
- [ ] Database schema updated (Isar migration successful)
- [ ] Old Firestore triggers no longer execute (verify in Firebase Console logs)

**Implementation Note**: Deploy backend changes first, then Flutter app changes. Keep a backup of old Cloud Functions in case rollback is needed.

---

## Testing Strategy

### Unit Tests

#### Domain Layer Tests
- **MessageStatus enum**: Test all enum values
- **FailureReason enum**: Test all enum values
- **MediaUploader**: Mock Firebase Storage, verify upload logic
- **AiServiceClient**: Mock Cloud Functions, verify retry logic, error mapping
- **Use cases**: Mock dependencies, verify pipeline steps and status transitions
- **RetryMessagePipelineUseCase**: Verify resumption from each status, backoff logic, max attempts

#### Data Layer Tests
- **Repository**: Verify CRUD operations without business logic
- **Data sources**: Verify Firestore/Isar operations
- **Models**: Verify serialization/deserialization with new fields

### Integration Tests
- Create text message end-to-end (with mocked Cloud Functions)
- Create audio message end-to-end (with mocked upload and transcription)
- Create image message end-to-end (with mocked upload and analysis)
- Retry failed message (simulate each failure reason)

### Manual Testing Steps

#### Text Message Flow
1. Open app, go to journal thread
2. Type text message and send
3. Verify status shows: "Sending..." → "Waiting for AI response..."
4. Verify AI response appears
5. Disconnect network, send text message
6. Verify status shows "Failed" with error message
7. Click retry button
8. Verify message succeeds after reconnecting

#### Audio Message Flow
1. Record audio message (10 seconds)
2. Send audio message
3. Verify status progression: "Uploading audio 0%" → "Uploading audio 100%" → "Transcribing audio..." → "AI is thinking..."
4. Verify transcription appears in message
5. Verify AI response appears
6. Disconnect network during upload
7. Verify status shows "Failed" with error
8. Click retry, verify upload resumes

#### Image Message Flow
1. Select image from gallery
2. Send image message
3. Verify status: "Uploading image X%" → "Analyzing image..." → "AI is thinking..."
4. Verify image description appears
5. Verify AI response appears
6. Simulate Cloud Function error (return 'internal' error)
7. Verify retry works after fixing error

#### Retry Logic
1. Create message that fails on upload (disconnect network)
2. Verify retry button appears
3. Click retry immediately - verify "wait X seconds" message
4. Wait for backoff period, click retry
5. Verify message progresses through pipeline
6. Force failure 5 times
7. Verify "Maximum retry attempts reached" message

## Performance Considerations

### Client-Side Performance

1. **Status updates**: Use `copyWith` efficiently, avoid unnecessary rebuilds
2. **Stream emissions**: Don't emit too frequently during upload progress (debounce if needed)
3. **File upload**: Use resumable uploads for large files (Firebase Storage SDK handles this)
4. **Local database writes**: Batch updates where possible

### Backend Performance

1. **Callable function cold starts**: Keep memory allocation appropriate (512MiB-1GiB)
2. **Concurrent requests**: Use Genkit's built-in concurrency handling
3. **Timeouts**: Set appropriate timeouts (60-120s) to avoid hanging requests
4. **Token usage**: Monitor Gemini API usage and set reasonable `maxOutputTokens`

### Network Optimization

1. **Reduce round trips**: Upload file → transcribe → AI response requires 3 Cloud Function calls (acceptable)
2. **Idempotency**: Use `clientLocalId` to prevent duplicate remote messages
3. **Error recovery**: Exponential backoff prevents hammering backend during outages
4. **Offline support**: Local-first architecture ensures UI remains responsive

## Migration Notes

### Data Migration

**Not required** - New fields have default values:
- `status`: Defaults to `MessageStatus.localCreated`
- `attemptCount`: Defaults to `0`
- `clientLocalId`: Can be null for existing messages

Existing messages will work with old `uploadStatus` and `aiProcessingStatus` fields during transition period.

### Backend Compatibility

**Old clients** will continue working:
- Firestore triggers remain deployed initially
- Old clients use triggers, new clients use callable functions
- Gradual migration: enable new pipeline per-user or percentage rollout

**New clients** will use callable functions exclusively:
- Old triggers can be removed after all clients updated
- Monitor Cloud Function logs to verify no old trigger invocations

### Rollback Plan

If issues discovered in production:
1. **Disable feature flag**: Set `useNewMessagePipeline` to `false` in FlavorConfig
2. **Revert Cloud Functions**: Redeploy old trigger-based functions
3. **Keep new code**: Don't need to roll back Flutter code - feature flag controls behavior

## References

- Current repository implementation: `lib/features/journal/data/repositories/journal_message_repository_impl.dart`
- Current upload service: `lib/features/journal/domain/services/journal_upload_service.dart`
- Existing callable function pattern: `functions/src/functions/transcription.ts:14-70`
- Firestore triggers to replace: `functions/src/functions/message-triggers.ts:17-392`
- Entity definition: `lib/features/journal/domain/entities/journal_message_entity.dart`
- Cloud Function AI service: `functions/src/services/ai-service.ts`
