# Refactor Message Upload Architecture Implementation Plan

## Overview

Refactor the MessageController and message upload flow to eliminate the JournalUploadService dependency and move all orchestration logic into dedicated use cases. This improves separation of concerns by ensuring controllers depend only on use cases, not services, while maintaining the existing fire-and-forget background upload pattern.

## Current State Analysis

### Current Architecture
**MessageController** ([message_controller.dart:31-285](lib/features/journal/presentation/controllers/message_controller.dart#L31-L285)) depends on:
- 3 Use Cases: `CreateTextMessageUseCase`, `CreateImageMessageUseCase`, `CreateAudioMessageUseCase`
- 1 Service: `JournalUploadService` ← **To be removed**
- 2 UI Services: `ImagePickerService`, `AudioRecorderService`

**JournalUploadService** ([journal_upload_service.dart:13-348](lib/features/journal/domain/services/journal_upload_service.dart#L13-L348)) orchestrates:
1. File validation (local file existence checks)
2. Status management (updates `UploadStatus` via repository)
3. Storage operations (delegates to `FirebaseStorageService`)
4. Metadata management (attaches message/thread IDs to uploads)
5. Image processing (configures thumbnail: 150px/70% quality, full: 2048px/85% quality)
6. Repository persistence (updates messages with storage URLs)
7. Retry logic (exponential backoff: 2, 4, 8, 16, 32 seconds, max 5 retries)
8. Transcription (triggers Cloud Function for audio - **will be removed**)
9. Error recovery (status updates on failure)
10. Progress reporting (debug logging)

### Current Upload Flow
1. Controller calls `CreateImageMessageUseCase` → creates message entity
2. Controller manually triggers fire-and-forget upload via `JournalUploadService.uploadImageMessage()`
3. Upload service coordinates `FirebaseStorageService` and `JournalMessageRepository`

### Key Discoveries
- **Background Upload Pattern**: Uploads are fire-and-forget using `.then()` without awaiting ([message_controller.dart:102-114](lib/features/journal/presentation/controllers/message_controller.dart#L102-L114))
- **Status Tracking**: Messages track upload state via `uploadStatus`, `uploadRetryCount`, `lastUploadAttemptAt` fields
- **Thumbnail Generation**: `CreateImageMessageUseCase` already generates thumbnails using `FirebaseStorageService.generateThumbnail()` ([create_image_message_usecase.dart:49-71](lib/features/journal/domain/usecases/create_image_message_usecase.dart#L49-L71))
- **Retry Logic**: Exponential backoff implemented in `processPendingUploads` ([journal_upload_service.dart:287-297](lib/features/journal/domain/services/journal_upload_service.dart#L287-L297))
- **Audio Transcription**: Currently fire-and-forget after upload ([journal_upload_service.dart:209-215](lib/features/journal/domain/services/journal_upload_service.dart#L209-L215)) - will be removed per requirements

## Desired End State

### After Refactoring
**MessageController** depends only on:
- 3 Message Creation Use Cases (modified): `CreateTextMessageUseCase`, `CreateImageMessageUseCase`, `CreateAudioMessageUseCase`
- 2 UI Services: `ImagePickerService`, `AudioRecorderService`

**New Use Cases**:
- `UploadMessageUseCase`: Single parameterized use case handling image/audio uploads
- `RetryUploadUseCase`: Delegates to `UploadMessageUseCase` for manual retries
- `ProcessPendingUploadsUseCase`: Batch processes pending uploads with retry logic

**Deleted**:
- `JournalUploadService` (completely removed)

### Verification
After completion:
- ✅ `MessageController` has no dependency on `JournalUploadService`
- ✅ All upload orchestration lives in use cases
- ✅ `JournalUploadService` file deleted
- ✅ All existing upload flows work identically (fire-and-forget pattern preserved)
- ✅ No transcription logic in client code
- ✅ Manual retries work via `RetryUploadUseCase`
- ✅ Pending uploads processing works via `ProcessPendingUploadsUseCase`

## What We're NOT Doing

- NOT changing the upload status enum or tracking fields
- NOT modifying the retry backoff algorithm (keeping exponential: 2, 4, 8, 16, 32 seconds)
- NOT changing image processing parameters (thumbnail: 150px/70%, full: 2048px/85%)
- NOT implementing client-side transcription (relying on Cloud Function triggers only)
- NOT modifying `FirebaseStorageService` interface
- NOT changing `JournalMessageRepository` interface
- NOT altering the fire-and-forget upload pattern
- NOT adding new UI functionality

## Implementation Approach

The refactoring will be done in phases to maintain working state at each step:

1. **Phase 1**: Create `UploadMessageUseCase` with full orchestration logic
2. **Phase 2**: Create `RetryUploadUseCase` and `ProcessPendingUploadsUseCase`
3. **Phase 3**: Modify creation use cases to trigger uploads internally
4. **Phase 4**: Update `MessageController` to remove `JournalUploadService` dependency
5. **Phase 5**: Update dependency injection and cleanup

This allows us to build new functionality before removing old, minimizing risk of breaking changes.

---

## Phase 1: Create UploadMessageUseCase

### Overview
Create a single parameterized use case that handles both image and audio uploads by encapsulating all orchestration logic from `JournalUploadService`.

### Changes Required

#### 1. Create `UploadMessageParams` Class
**File**: `lib/features/journal/domain/usecases/upload_message_usecase.dart` (new file)
**Purpose**: Define input parameters for upload operation

```dart
class UploadMessageParams {
  const UploadMessageParams({
    required this.message,
  });

  final JournalMessageEntity message;
}
```

#### 2. Create `UploadMessageUseCase` Class
**File**: `lib/features/journal/domain/usecases/upload_message_usecase.dart` (same file)
**Changes**: Implement complete upload orchestration

```dart
class UploadMessageUseCase {
  UploadMessageUseCase({
    required this.storageService,
    required this.messageRepository,
  });

  final FirebaseStorageService storageService;
  final JournalMessageRepository messageRepository;

  Future<Result<void>> call(UploadMessageParams params) async {
    final message = params.message;

    // Route to appropriate upload method based on message type
    if (message.messageType == MessageType.image) {
      return _uploadImageMessage(message);
    } else if (message.messageType == MessageType.audio) {
      return _uploadAudioMessage(message);
    } else {
      return const Error(
        ValidationFailure(message: 'Cannot upload text message'),
      );
    }
  }

  /// Upload image message with thumbnail
  /// Migrated from JournalUploadService.uploadImageMessage (lines 23-143)
  Future<Result<void>> _uploadImageMessage(JournalMessageEntity message) async {
    debugPrint('🚀 _uploadImageMessage called for: ${message.id}');
    try {
      // 1. Validate local file exists
      if (message.localFilePath == null) {
        return const Error(
          ValidationFailure(message: 'No local file path for image'),
        );
      }

      final file = File(message.localFilePath!);
      if (!file.existsSync()) {
        await _updateUploadStatus(message, UploadStatus.failed);
        return const Error(
          ValidationFailure(message: 'Image file does not exist'),
        );
      }

      // 2. Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // 3. Upload thumbnail first if exists
      String? thumbnailUrl;
      if (message.localThumbnailPath != null) {
        final thumbnailFile = File(message.localThumbnailPath!);
        if (thumbnailFile.existsSync()) {
          final thumbPath = storageService.buildJournalPath(
            userId: message.userId,
            journalId: message.threadId,
            filename: '${message.id}_thumb.jpg',
          );

          final thumbResult = await storageService.uploadFile(
            file: thumbnailFile,
            storagePath: thumbPath,
            fileType: FileType.image,
            imageMaxSize: 150,
            imageQuality: 70,
            metadata: {
              'messageId': message.id,
              'threadId': message.threadId,
              'type': 'thumbnail',
            },
          );
          debugPrint('Thumbnail upload result: ${thumbResult.dataOrNull}');

          if (thumbResult.isError) {
            debugPrint(
              'Failed to upload thumbnail: ${thumbResult.failureOrNull?.message}',
            );
            // Continue with full image upload even if thumbnail fails
          } else {
            thumbnailUrl = thumbResult.dataOrNull;
          }
        }
      }

      // 4. Upload full image
      final imagePath = storageService.buildJournalPath(
        userId: message.userId,
        journalId: message.threadId,
        filename: '${message.id}.jpg',
      );

      debugPrint('📤 Starting image upload for: ${message.id}');
      final uploadResult = await storageService.uploadFile(
        file: file,
        storagePath: imagePath,
        fileType: FileType.image,
        imageMaxSize: 2048,
        imageQuality: 85,
        metadata: {
          'messageId': message.id,
          'threadId': message.threadId,
          'type': 'image',
        },
        onProgress: (progress) {
          if (progress.isFinite && progress >= 0 && progress <= 1) {
            debugPrint('Image upload progress: ${(progress * 100).toInt()}%');
          }
        },
      );

      debugPrint('📦 Upload completed, processing result for: ${message.id}');
      debugPrint('📦 Upload result type: ${uploadResult.isSuccess ? "SUCCESS" : "ERROR"}');

      // 5. Update message with URLs and status
      return uploadResult.when(
        success: (downloadUrl) async {
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            thumbnailUrl: thumbnailUrl,
            uploadStatus: UploadStatus.completed,
          );

          debugPrint('Calling updateMessage for: ${updatedMessage.id} with storageUrl: ${updatedMessage.storageUrl}');
          final updateResult = await messageRepository.updateMessage(updatedMessage);

          return updateResult.when(
            success: (_) {
              debugPrint('Successfully updated message in repository: ${updatedMessage.id}');
              return const Success(null);
            },
            error: (failure) {
              debugPrint('Failed to update message in repository: $failure');
              return Error(failure);
            },
          );
        },
        error: (failure) async {
          await _updateUploadStatus(message, UploadStatus.failed);
          return Error(failure);
        },
      );
    } catch (e) {
      await _updateUploadStatus(message, UploadStatus.failed);
      return Error(UnknownFailure(message: 'Image upload failed: $e'));
    }
  }

  /// Upload audio message
  /// Migrated from JournalUploadService.uploadAudioMessage (lines 146-234)
  /// NOTE: Transcription logic removed per requirements - Cloud Functions handle it
  Future<Result<void>> _uploadAudioMessage(JournalMessageEntity message) async {
    try {
      // 1. Validate local file exists
      if (message.localFilePath == null) {
        return const Error(
          ValidationFailure(message: 'No local file path for audio'),
        );
      }

      final file = File(message.localFilePath!);
      if (!file.existsSync()) {
        await _updateUploadStatus(message, UploadStatus.failed);
        return const Error(
          ValidationFailure(message: 'Audio file does not exist'),
        );
      }

      // 2. Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // 3. Upload audio file
      final audioPath = storageService.buildJournalPath(
        userId: message.userId,
        journalId: message.threadId,
        filename: '${message.id}.m4a',
      );

      final uploadResult = await storageService.uploadFile(
        file: file,
        storagePath: audioPath,
        fileType: FileType.audio,
        metadata: {
          'messageId': message.id,
          'threadId': message.threadId,
          'type': 'audio',
          'durationSeconds': message.audioDurationSeconds?.toString() ?? '0',
        },
        onProgress: (progress) {
          if (progress.isFinite && progress >= 0 && progress <= 1) {
            debugPrint('Audio upload progress: ${(progress * 100).toInt()}%');
          }
        },
      );

      // 4. Update message with URL and status
      return uploadResult.when(
        success: (downloadUrl) async {
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            uploadStatus: UploadStatus.completed,
          );

          debugPrint('Calling updateMessage for audio: ${updatedMessage.id} with storageUrl: ${updatedMessage.storageUrl}');
          final updateResult = await messageRepository.updateMessage(updatedMessage);

          return updateResult.when(
            success: (_) {
              debugPrint('Successfully updated audio message in repository: ${updatedMessage.id}');
              // NOTE: No transcription trigger here - Cloud Functions handle it automatically
              return const Success(null);
            },
            error: (failure) {
              debugPrint('Failed to update audio message in repository: $failure');
              return Error(failure);
            },
          );
        },
        error: (failure) async {
          await _updateUploadStatus(message, UploadStatus.failed);
          return Error(failure);
        },
      );
    } catch (e) {
      await _updateUploadStatus(message, UploadStatus.failed);
      return Error(UnknownFailure(message: 'Audio upload failed: $e'));
    }
  }

  /// Helper to update upload status and retry count
  /// Migrated from JournalUploadService._updateUploadStatus (lines 334-347)
  Future<void> _updateUploadStatus(
    JournalMessageEntity message,
    UploadStatus status,
  ) async {
    final updatedMessage = message.copyWith(
      uploadStatus: status,
      uploadRetryCount: status == UploadStatus.failed
          ? message.uploadRetryCount + 1
          : message.uploadRetryCount,
      lastUploadAttemptAt: DateTime.now().toUtc(),
    );

    await messageRepository.updateMessage(updatedMessage);
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] No import errors or undefined references
- [ ] File compiles successfully: `~/flutter/bin/dart analyze lib/features/journal/domain/usecases/upload_message_usecase.dart`

#### Manual Verification:
- [ ] Code review confirms all orchestration logic migrated from `JournalUploadService.uploadImageMessage` (lines 23-143)
- [ ] Code review confirms all orchestration logic migrated from `JournalUploadService.uploadAudioMessage` (lines 146-234)
- [ ] Code review confirms transcription logic removed (no Cloud Function calls)
- [ ] Code review confirms `_updateUploadStatus` helper migrated (lines 334-347)
- [ ] Upload parameters match original (thumbnail: 150px/70%, full: 2048px/85%, audio: .m4a)

---

## Phase 2: Create RetryUploadUseCase and ProcessPendingUploadsUseCase

### Overview
Create two additional use cases: one for manual retry of failed uploads, and one for batch processing of pending uploads with exponential backoff.

### Changes Required

#### 1. Create `RetryUploadUseCase`
**File**: `lib/features/journal/domain/usecases/retry_upload_usecase.dart` (new file)
**Changes**: Implement retry logic by delegating to `UploadMessageUseCase`

```dart
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/usecases/upload_message_usecase.dart';

class RetryUploadParams {
  const RetryUploadParams({
    required this.message,
  });

  final JournalMessageEntity message;
}

/// Retry a specific failed upload manually
/// Migrated from JournalUploadService.retryUpload (lines 321-331)
class RetryUploadUseCase {
  RetryUploadUseCase({
    required this.uploadMessageUseCase,
  });

  final UploadMessageUseCase uploadMessageUseCase;

  Future<Result<void>> call(RetryUploadParams params) async {
    final message = params.message;

    // Validate message type
    if (message.messageType == MessageType.image ||
        message.messageType == MessageType.audio) {
      // Delegate to UploadMessageUseCase
      return uploadMessageUseCase.call(UploadMessageParams(message: message));
    } else {
      return const Error(
        ValidationFailure(message: 'Cannot retry text message upload'),
      );
    }
  }
}
```

#### 2. Create `ProcessPendingUploadsUseCase`
**File**: `lib/features/journal/domain/usecases/process_pending_uploads_usecase.dart` (new file)
**Changes**: Implement batch processing with exponential backoff

```dart
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/usecases/upload_message_usecase.dart';

class ProcessPendingUploadsParams {
  const ProcessPendingUploadsParams({
    required this.userId,
  });

  final String userId;
}

/// Process pending uploads for a user with retry logic
/// Returns count of successfully uploaded messages
/// Migrated from JournalUploadService.processPendingUploads (lines 268-318)
class ProcessPendingUploadsUseCase {
  ProcessPendingUploadsUseCase({
    required this.messageRepository,
    required this.uploadMessageUseCase,
  });

  final JournalMessageRepository messageRepository;
  final UploadMessageUseCase uploadMessageUseCase;

  Future<Result<int>> call(ProcessPendingUploadsParams params) async {
    try {
      final pendingResult = await messageRepository.getPendingUploads(params.userId);

      if (pendingResult.isError) {
        return Error(pendingResult.failureOrNull!);
      }

      final pendingMessages = pendingResult.dataOrNull!;
      var successCount = 0;

      for (final message in pendingMessages) {
        // Skip if retry count too high (max 5 attempts)
        if (message.uploadRetryCount >= 5) {
          debugPrint('Max retry count reached for message ${message.id}');
          continue;
        }

        // Exponential backoff: wait 2^retryCount seconds
        if (message.lastUploadAttemptAt != null) {
          final timeSinceLastAttempt = DateTime.now()
              .difference(message.lastUploadAttemptAt!)
              .inSeconds;
          final backoffSeconds = 2 << message.uploadRetryCount; // 2, 4, 8, 16, 32

          if (timeSinceLastAttempt < backoffSeconds) {
            debugPrint('Backoff period not elapsed for message ${message.id}');
            continue;
          }
        }

        // Upload based on message type
        Result<void> uploadResult;
        if (message.messageType == MessageType.image) {
          uploadResult = await uploadMessageUseCase.call(
            UploadMessageParams(message: message),
          );
        } else if (message.messageType == MessageType.audio) {
          uploadResult = await uploadMessageUseCase.call(
            UploadMessageParams(message: message),
          );
        } else {
          continue; // Text messages don't need upload
        }

        if (uploadResult.isSuccess) {
          successCount++;
        }
      }

      return Success(successCount);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to process uploads: $e'));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] Files compile successfully: `~/flutter/bin/dart analyze lib/features/journal/domain/usecases/retry_upload_usecase.dart lib/features/journal/domain/usecases/process_pending_uploads_usecase.dart`

#### Manual Verification:
- [ ] Code review confirms `RetryUploadUseCase` delegates to `UploadMessageUseCase`
- [ ] Code review confirms `ProcessPendingUploadsUseCase` implements exponential backoff (2, 4, 8, 16, 32 seconds)
- [ ] Code review confirms max retry limit of 5 preserved
- [ ] Logic matches `JournalUploadService.processPendingUploads` (lines 268-318)
- [ ] Logic matches `JournalUploadService.retryUpload` (lines 321-331)

---

## Phase 3: Modify Creation Use Cases to Trigger Uploads

### Overview
Update `CreateImageMessageUseCase` and `CreateAudioMessageUseCase` to trigger background uploads internally after creating messages, removing the need for the controller to manually trigger uploads.

### Changes Required

#### 1. Update `CreateImageMessageUseCase`
**File**: `lib/features/journal/domain/usecases/create_image_message_usecase.dart`
**Changes**: Add `UploadMessageUseCase` dependency and trigger upload after message creation

**Add import**:
```dart
import 'dart:async'; // For unawaited
import 'package:kairos/features/journal/domain/usecases/upload_message_usecase.dart';
```

**Update constructor** (lines 28-33):
```dart
class CreateImageMessageUseCase {
  CreateImageMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.storageService,
    required this.uploadMessageUseCase, // NEW
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final FirebaseStorageService storageService;
  final UploadMessageUseCase uploadMessageUseCase; // NEW
```

**Trigger upload after message creation** (after line 122):
```dart
      final messageResult = await messageRepository.createMessage(message);
      if (messageResult.isError) {
        return Error(messageResult.failureOrNull!);
      }

      final threadResult = await threadRepository.getThreadById(threadId);
      if (threadResult.dataOrNull != null) {
        final thread = threadResult.dataOrNull!;
        final updatedThread = thread.copyWith(
          lastMessageAt: now,
          messageCount: thread.messageCount + 1,
          updatedAt: now,
        );
        await threadRepository.updateThread(updatedThread);
      }

      // NEW: Trigger background upload (fire-and-forget)
      final createdMessage = messageResult.dataOrNull!;
      unawaited(
        uploadMessageUseCase.call(UploadMessageParams(message: createdMessage)).then((uploadResult) {
          uploadResult.when(
            success: (_) {
              debugPrint('✅ Image upload completed successfully for: ${createdMessage.id}');
            },
            error: (failure) {
              debugPrint('❌ Upload failed: ${failure.message}');
              // Message saved locally, will retry later
            },
          );
        }).catchError((Object error) {
          debugPrint('❌ Unexpected error in upload: $error');
        }),
      );

      return messageResult;
```

#### 2. Update `CreateAudioMessageUseCase`
**File**: `lib/features/journal/domain/usecases/create_audio_message_usecase.dart`
**Changes**: Add `UploadMessageUseCase` dependency and trigger upload after message creation

**Add import**:
```dart
import 'dart:async'; // For unawaited
import 'package:kairos/features/journal/domain/usecases/upload_message_usecase.dart';
```

**Update constructor**:
```dart
class CreateAudioMessageUseCase {
  CreateAudioMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.uploadMessageUseCase, // NEW
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final UploadMessageUseCase uploadMessageUseCase; // NEW
```

**Trigger upload after message creation** (similar pattern as image):
```dart
      // After message creation and thread update...

      // NEW: Trigger background upload (fire-and-forget)
      final createdMessage = messageResult.dataOrNull!;
      unawaited(
        uploadMessageUseCase.call(UploadMessageParams(message: createdMessage)).then((uploadResult) {
          if (uploadResult.isError) {
            debugPrint('Upload failed: ${uploadResult.failureOrNull?.message}');
          }
        }),
      );

      return messageResult;
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] Files compile successfully: `~/flutter/bin/dart analyze lib/features/journal/domain/usecases/create_image_message_usecase.dart lib/features/journal/domain/usecases/create_audio_message_usecase.dart`

#### Manual Verification:
- [ ] `CreateImageMessageUseCase` constructor includes `uploadMessageUseCase` parameter
- [ ] `CreateAudioMessageUseCase` constructor includes `uploadMessageUseCase` parameter
- [ ] Both use cases trigger upload via `unawaited()` after successful message creation
- [ ] Fire-and-forget pattern preserved (upload doesn't block return)
- [ ] Error logging matches original controller pattern

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Update MessageController to Remove JournalUploadService

### Overview
Remove the `JournalUploadService` dependency from `MessageController` and update the `retryUpload` method to use the new `RetryUploadUseCase`.

### Changes Required

#### 1. Update `MessageController` Constructor
**File**: `lib/features/journal/presentation/controllers/message_controller.dart`
**Changes**: Remove `uploadService` parameter and add `retryUploadUseCase`

**Remove import** (line 10):
```dart
// DELETE THIS LINE:
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
```

**Add import**:
```dart
import 'package:kairos/features/journal/domain/usecases/retry_upload_usecase.dart';
```

**Update constructor** (lines 32-39):
```dart
class MessageController extends StateNotifier<MessageState> {
  MessageController({
    required this.createTextMessageUseCase,
    required this.createImageMessageUseCase,
    required this.createAudioMessageUseCase,
    required this.retryUploadUseCase, // NEW (replaces uploadService)
    required this.imagePickerService,
    required this.audioRecorderService,
  }) : super(MessageInitial());

  final CreateTextMessageUseCase createTextMessageUseCase;
  final CreateImageMessageUseCase createImageMessageUseCase;
  final CreateAudioMessageUseCase createAudioMessageUseCase;
  final RetryUploadUseCase retryUploadUseCase; // NEW
  // DELETE: final JournalUploadService uploadService;
  final ImagePickerService imagePickerService;
  final AudioRecorderService audioRecorderService;
```

#### 2. Remove Manual Upload Triggers
**File**: `lib/features/journal/presentation/controllers/message_controller.dart`
**Changes**: Remove manual upload triggering from `createImageMessage` and `createAudioMessage`

**Update `createImageMessage`** (lines 79-120):
```dart
  Future<void> createImageMessage({
    required String userId,
    required File imageFile,
    required String thumbnailPath,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateImageMessageParams(
      userId: userId,
      imageFile: imageFile,
      thumbnailPath: thumbnailPath,
      threadId: threadId,
    );

    final result = await createImageMessageUseCase.call(params);

    result.when<void>(
      success: (JournalMessageEntity message) {
        state = MessageSuccess(message);
        // DELETE LINES 100-114 (manual upload trigger)
        // Upload is now triggered internally by CreateImageMessageUseCase
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }
```

**Update `createAudioMessage`** (lines 122-156):
```dart
  Future<void> createAudioMessage({
    required String userId,
    required File audioFile,
    required int durationSeconds,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateAudioMessageParams(
      userId: userId,
      audioFile: audioFile,
      durationSeconds: durationSeconds,
      threadId: threadId,
    );

    final result = await createAudioMessageUseCase.call(params);

    result.when<void>(
      success: (JournalMessageEntity message) {
        state = MessageSuccess(message);
        // DELETE LINES 144-150 (manual upload trigger)
        // Upload is now triggered internally by CreateAudioMessageUseCase
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }
```

#### 3. Update `retryUpload` Method
**File**: `lib/features/journal/presentation/controllers/message_controller.dart`
**Changes**: Use `RetryUploadUseCase` instead of `JournalUploadService`

**Update method** (lines 266-280):
```dart
  /// Manually retry a failed upload
  Future<void> retryUpload(JournalMessageEntity message) async {
    state = MessageLoading();

    final params = RetryUploadParams(message: message); // NEW
    final result = await retryUploadUseCase.call(params); // CHANGED

    result.when<void>(
      success: (_) {
        state = MessageSuccess(message);
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] File compiles successfully: `~/flutter/bin/dart analyze lib/features/journal/presentation/controllers/message_controller.dart`
- [ ] No references to `JournalUploadService` in MessageController: `grep -n "JournalUploadService" lib/features/journal/presentation/controllers/message_controller.dart` returns nothing

#### Manual Verification:
- [ ] `MessageController` no longer imports `JournalUploadService`
- [ ] `MessageController` constructor has `retryUploadUseCase` instead of `uploadService`
- [ ] `createImageMessage` no longer manually triggers upload (lines 100-114 removed)
- [ ] `createAudioMessage` no longer manually triggers upload (lines 144-150 removed)
- [ ] `retryUpload` method uses `RetryUploadUseCase`
- [ ] No compile errors or warnings

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Update Dependency Injection and Cleanup

### Overview
Update Riverpod providers to register new use cases, update `MessageController` provider, and delete `JournalUploadService`.

### Changes Required

#### 1. Register New Use Cases
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`
**Changes**: Add providers for new use cases

**Add imports** (after line 17):
```dart
import 'package:kairos/features/journal/domain/usecases/upload_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/retry_upload_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/process_pending_uploads_usecase.dart';
```

**Add providers** (after line 111, before stream providers):
```dart
// Upload use cases
final uploadMessageUseCaseProvider = Provider<UploadMessageUseCase>((ref) {
  final storageService = ref.watch(firebaseStorageServiceProvider);
  final messageRepository = ref.watch(messageRepositoryProvider);
  return UploadMessageUseCase(
    storageService: storageService,
    messageRepository: messageRepository,
  );
});

final retryUploadUseCaseProvider = Provider<RetryUploadUseCase>((ref) {
  final uploadMessageUseCase = ref.watch(uploadMessageUseCaseProvider);
  return RetryUploadUseCase(
    uploadMessageUseCase: uploadMessageUseCase,
  );
});

final processPendingUploadsUseCaseProvider =
    Provider<ProcessPendingUploadsUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final uploadMessageUseCase = ref.watch(uploadMessageUseCaseProvider);
  return ProcessPendingUploadsUseCase(
    messageRepository: messageRepository,
    uploadMessageUseCase: uploadMessageUseCase,
  );
});
```

#### 2. Update Creation Use Case Providers
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`
**Changes**: Add `uploadMessageUseCase` dependency to creation use cases

**Update `createImageMessageUseCaseProvider`** (lines 91-101):
```dart
final createImageMessageUseCaseProvider =
    Provider<CreateImageMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final storageService = ref.watch(firebaseStorageServiceProvider);
  final uploadMessageUseCase = ref.watch(uploadMessageUseCaseProvider); // NEW
  return CreateImageMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    storageService: storageService,
    uploadMessageUseCase: uploadMessageUseCase, // NEW
  );
});
```

**Update `createAudioMessageUseCaseProvider`** (lines 103-111):
```dart
final createAudioMessageUseCaseProvider =
    Provider<CreateAudioMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final uploadMessageUseCase = ref.watch(uploadMessageUseCaseProvider); // NEW
  return CreateAudioMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    uploadMessageUseCase: uploadMessageUseCase, // NEW
  );
});
```

#### 3. Update MessageController Provider
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`
**Changes**: Replace `uploadService` with `retryUploadUseCase`

**Update `messageControllerProvider`** (lines 127-146):
```dart
final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase =
      ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase =
      ref.watch(createAudioMessageUseCaseProvider);
  final retryUploadUseCase = ref.watch(retryUploadUseCaseProvider); // CHANGED
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  final audioRecorderService = ref.watch(audioRecorderServiceProvider);

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
    retryUploadUseCase: retryUploadUseCase, // CHANGED (was uploadService)
    imagePickerService: imagePickerService,
    audioRecorderService: audioRecorderService,
  );
});
```

#### 4. Delete JournalUploadService Provider
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`
**Changes**: Remove `journalUploadServiceProvider`

**Delete provider** (lines 71-78):
```dart
// DELETE THESE LINES:
final journalUploadServiceProvider = Provider<JournalUploadService>((ref) {
  final storageService = ref.watch(firebaseStorageServiceProvider);
  final messageRepository = ref.watch(messageRepositoryProvider);
  return JournalUploadService(
    storageService: storageService,
    messageRepository: messageRepository,
  );
});
```

**Delete import** (line 14):
```dart
// DELETE THIS LINE:
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
```

#### 5. Delete JournalUploadService File
**File**: `lib/features/journal/domain/services/journal_upload_service.dart`
**Changes**: Delete entire file

```bash
rm lib/features/journal/domain/services/journal_upload_service.dart
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] All files compile successfully: `~/flutter/bin/flutter pub get && ~/flutter/bin/dart analyze`
- [ ] No references to `JournalUploadService` exist: `grep -r "JournalUploadService" lib/ --include="*.dart"` returns nothing
- [ ] File deleted: `test ! -f lib/features/journal/domain/services/journal_upload_service.dart`
- [ ] Build succeeds: `~/flutter/bin/flutter build apk --debug` (or iOS equivalent)

#### Manual Verification:
- [ ] All new use case providers registered correctly
- [ ] `MessageController` provider uses `retryUploadUseCase` instead of `uploadService`
- [ ] `CreateImageMessageUseCase` provider includes `uploadMessageUseCase` dependency
- [ ] `CreateAudioMessageUseCase` provider includes `uploadMessageUseCase` dependency
- [ ] `journalUploadServiceProvider` deleted from providers file
- [ ] `JournalUploadService` import removed from providers file
- [ ] `journal_upload_service.dart` file deleted from filesystem
- [ ] App runs without crashes: Test creating text, image, and audio messages
- [ ] Background uploads work: Image/audio uploads trigger automatically after creation
- [ ] Manual retry works: Retry failed upload via UI
- [ ] Upload status updates correctly: Messages show uploading → completed/failed states

---

## Testing Strategy

### Unit Tests
**Note**: No existing tests found for `MessageController` or upload components. Consider adding:

- `UploadMessageUseCase`:
  - Image upload success path
  - Audio upload success path
  - File not found error handling
  - Storage service failure handling
  - Repository update failure handling
  - Progress callback invocation

- `RetryUploadUseCase`:
  - Delegates to `UploadMessageUseCase` for image messages
  - Delegates to `UploadMessageUseCase` for audio messages
  - Returns error for text messages

- `ProcessPendingUploadsUseCase`:
  - Skips messages with retry count >= 5
  - Applies exponential backoff correctly (2, 4, 8, 16, 32 seconds)
  - Processes multiple pending messages
  - Returns correct success count

### Integration Tests
- End-to-end flow: Create image message → background upload triggers → message updates with URL
- End-to-end flow: Create audio message → background upload triggers → message updates with URL
- Retry flow: Failed upload → manual retry → success
- Pending uploads: Multiple failed messages → batch processing → respects backoff

### Manual Testing Steps
1. **Create text message**: Verify no upload triggered, message created successfully
2. **Create image message**:
   - Verify message created locally with `notStarted` status
   - Verify status changes to `uploading` then `completed`
   - Verify `storageUrl` and `thumbnailUrl` populated after upload
   - Check Firebase Storage for uploaded files
3. **Create audio message**:
   - Verify message created locally with `notStarted` status
   - Verify status changes to `uploading` then `completed`
   - Verify `storageUrl` populated after upload
   - Verify NO client-side transcription call (check logs)
   - Check Firebase Storage for uploaded file
4. **Simulate upload failure**:
   - Turn off network
   - Create image/audio message
   - Verify status changes to `failed`
   - Verify `uploadRetryCount` incremented
   - Turn on network
   - Trigger manual retry
   - Verify upload succeeds
5. **Test pending uploads**:
   - Create multiple messages while offline
   - Turn on network
   - Call `ProcessPendingUploadsUseCase`
   - Verify messages upload with exponential backoff
6. **Test max retry limit**:
   - Simulate 5 failed uploads for a message
   - Verify message no longer retries automatically

## Performance Considerations

### No Performance Impact Expected
- Same upload logic, just reorganized into use cases
- Fire-and-forget pattern preserved (no blocking)
- Exponential backoff algorithm unchanged
- Image processing parameters unchanged (thumbnail: 150px/70%, full: 2048px/85%)

### Memory Considerations
- `unawaited()` ensures uploads don't block UI thread
- Local file references released after upload completes
- Repository updates trigger UI stream refreshes (existing behavior)

## Migration Notes

### Breaking Changes
- **None for end users**: Upload flow remains identical
- **For developers**: `JournalUploadService` no longer exists
  - Use `UploadMessageUseCase` instead
  - Use `RetryUploadUseCase` for manual retries
  - Use `ProcessPendingUploadsUseCase` for batch processing

### Data Migration
- **Not required**: No database schema changes
- Upload status fields remain unchanged (`uploadStatus`, `uploadRetryCount`, `lastUploadAttemptAt`)

### Rollback Plan
If issues arise, rollback by:
1. Restore `journal_upload_service.dart` from git history
2. Revert changes to `MessageController`
3. Revert changes to creation use cases
4. Revert changes to `journal_providers.dart`

## References

- Original architecture: [message_controller.dart:31-285](lib/features/journal/presentation/controllers/message_controller.dart#L31-L285)
- JournalUploadService logic: [journal_upload_service.dart:13-348](lib/features/journal/domain/services/journal_upload_service.dart#L13-L348)
- Use case patterns: [create_image_message_usecase.dart](lib/features/journal/domain/usecases/create_image_message_usecase.dart), [create_text_message_usecase.dart](lib/features/journal/domain/usecases/create_text_message_usecase.dart)
- Dependency injection: [journal_providers.dart](lib/features/journal/presentation/providers/journal_providers.dart)
- FirebaseStorageService: [firebase_storage_service.dart](lib/core/services/firebase_storage_service.dart)
- JournalMessageRepository: [journal_message_repository.dart](lib/features/journal/domain/repositories/journal_message_repository.dart)
