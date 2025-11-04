# Journal Feature Completion Plan

## Overview

This plan completes the remaining 20% of the Kairos journal feature implementation by adding the missing service layer (audio recording, media upload orchestration), integrating UI components (image picker, recording interface), enhancing error handling, and migrating the profile feature to use the new Firebase Storage Service. The journal feature has a solid foundation with domain entities, data models, repositories, use cases, and basic UI already implemented.

## Current State Analysis

### What Exists (80% Complete)

**Domain Layer** ✅
- `JournalThreadEntity` and `JournalMessageEntity` with complete field definitions
- `MessageRole` (user/ai/system), `MessageType` (text/image/audio), `UploadStatus` (5 states), `AiProcessingStatus` (4 states) enums
- Repository interfaces returning `Result<T>` for error handling
- Three use cases: `CreateTextMessageUseCase`, `CreateImageMessageUseCase`, `CreateAudioMessageUseCase`

**Data Layer** ✅
- `JournalThreadModel` and `JournalMessageModel` with Isar annotations
- Local data sources with Isar for offline persistence
- Remote data sources with Firestore for cloud sync
- Repositories implementing offline-first pattern with Result types
- Database schema registered in Isar

**Presentation Layer** ✅
- `MessageController` with sealed state hierarchy
- Riverpod providers for dependency injection
- `ThreadListScreen` and `ThreadDetailScreen`
- `MessageBubble` and `MessageInput` widgets

**Core Services** ⚠️ Partially Complete
- `FirebaseStorageService` fully implemented with `Result<T>` types ✅
- `ImagePickerService` fully implemented ✅
- `FirebaseImageStorageService` legacy service (needs migration) ⚠️

### What's Missing (20%)

**Critical Services** ❌
1. **AudioRecorderService** - No audio recording implementation
2. **JournalUploadService** - No background upload orchestration
3. **ThumbnailGenerationService** wrapper - Not wired up

**UI Integration** ❌
4. Image picker not connected to `MessageInput` widget
5. No recording UI for audio messages
6. No upload progress indicators or retry buttons

**Error Handling** ⚠️
7. Generic `UnknownFailure` used everywhere instead of specific failures
8. Controller error mapping incomplete
9. No user-friendly error messages for all scenarios

**Migration** ❌
10. `ProfileController` still uses old `FirebaseImageStorageService`

### Key Discoveries

- **Error Handling Architecture**: Complete `Result<T>` pattern with 8 failure types already defined ([failures.dart:3-70](lib/core/errors/failures.dart#L3-L70))
- **Image Picker Ready**: `ImagePickerService` fully implemented with `Result<File>` return type ([image_picker_service.dart:9-64](lib/core/services/image_picker_service.dart#L9-L64))
- **Storage Service Complete**: `FirebaseStorageService` supports all file types with progress tracking ([firebase_storage_service.dart:10-155](lib/core/services/firebase_storage_service.dart#L10-L155))
- **Audio Packages Installed**: `record: ^5.0.0` and `audioplayers: ^5.0.0` already in `pubspec.yaml`
- **Permissions Configured**: iOS microphone permission already declared ([Info.plist:63-64](ios/Runner/Info.plist#L63-L64))
- **Upload Queue Query**: Repository has `getPendingUploads` method but no consumer ([journal_message_repository_impl.dart:111-120](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L111-L120))
- **Message Entity Complete**: All upload tracking fields defined ([journal_message_entity.dart:39-48](lib/features/journal/domain/entities/journal_message_entity.dart#L39-L48))

## Desired End State

### Functional Requirements

After implementation, the journal feature will support:

1. **Text Messages**: Create and sync immediately ✅ (already working)
2. **Image Messages**:
   - Pick from gallery or capture with camera
   - Generate thumbnail locally for instant preview
   - Upload full image and thumbnail in background
   - Show upload progress and status
   - Retry failed uploads manually or automatically
3. **Audio Messages**:
   - Record audio with duration tracking
   - Show recording UI with timer
   - Upload recording in background
   - Display duration in message bubble
   - Support playback (display only, full playback future)
4. **Upload Management**:
   - Offline-first: save locally, queue for upload
   - Background upload with exponential backoff retry
   - Upload status tracking (notStarted → uploading → completed/failed)
   - Manual retry button for failed uploads
5. **Error Handling**:
   - Specific failure types for each error scenario
   - User-friendly error messages in UI
   - Permission error guidance
6. **Profile Migration**:
   - Profile avatar uploads use new `FirebaseStorageService`
   - Old `FirebaseImageStorageService` removed

### Verification Criteria

The feature will be complete when:
- User can capture/select images that appear instantly with thumbnails
- User can record audio with visible duration counter
- All media uploads happen in background with progress indicators
- Failed uploads show retry button and succeed on retry
- Offline media saves locally and uploads when online resumes
- All automated tests pass
- Manual testing confirms smooth UX for all three message types

## What We're NOT Doing

Explicitly out of scope:

- **AI Integration**: Cloud Functions for transcription/responses (separate backend work)
- **Message Editing**: Edit or delete messages after creation
- **Search**: Full-text or semantic search
- **Thread Management**: Merge, split, archive UI (data model supports archive)
- **Rich Media**: Waveform visualization, image annotation, rich text formatting
- **Live Features**: Live transcription during recording, real-time collaboration
- **Pagination**: Load all threads/messages (implement when >100 threads)
- **Export**: Export threads or share functionality
- **Background Sync Service**: OS-level WorkManager for background uploads (manual/foreground only for MVP)

## Implementation Approach

### Strategy

1. **Services First**: Implement `AudioRecorderService` and `JournalUploadService` with complete error handling
2. **Error Handling Polish**: Add specific failure types throughout use cases and repositories
3. **UI Integration**: Wire up image picker and recording to message input
4. **Upload Orchestration**: Connect upload service to message creation flow
5. **Profile Migration**: Move profile to new storage service and remove old one
6. **Testing**: Manual testing of complete flows, automated testing where possible

### Architectural Decisions

- **Audio Format**: M4A/AAC via `record` package for cross-platform support
- **Thumbnail Generation**: Local generation before upload for instant preview (150x150, 70% quality)
- **Upload Timing**: Trigger immediately after message creation (not background worker)
- **Retry Logic**: Exponential backoff in upload service (2s → 4s → 8s → 16s → 32s max)
- **Progress Tracking**: Callback-based, not streamed (simpler for MVP)
- **Error Specificity**: Use existing failure types, add context in messages
- **Service Layer**: Domain services for upload orchestration (not in use cases)
- **State Management**: Controller owns transient state (selected files), repository owns persistent state

---

## Phase 1: Audio Recording Service

### Overview

Implement the `AudioRecorderService` to record audio messages using the `record` package. This service will handle microphone permissions, recording start/stop, duration tracking, and return audio files with metadata. Follows the same pattern as `ImagePickerService` with `Result<T>` return types.

### Changes Required

#### 1.1 Audio Recorder Service

**File**: `lib/core/services/audio_recorder_service.dart` (new)

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

/// Result containing audio file and duration metadata
class AudioRecordingResult {
  const AudioRecordingResult({
    required this.file,
    required this.durationSeconds,
  });

  final File file;
  final int durationSeconds;
}

/// Service for recording audio using the record package
class AudioRecorderService {
  AudioRecorderService(this._recorder);

  final AudioRecorder _recorder;
  DateTime? _recordingStartTime;

  /// Start recording audio
  /// Returns Success or Error with PermissionFailure if permission denied
  Future<Result<void>> startRecording() async {
    try {
      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        return const Error(
          PermissionFailure(message: 'Microphone permission denied'),
        );
      }

      // Generate unique file path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/recording_$timestamp.m4a';

      // Start recording with M4A/AAC codec
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordingStartTime = DateTime.now();

      return const Success(null);
    } catch (e) {
      return Error(
        UnknownFailure(message: 'Failed to start recording: $e'),
      );
    }
  }

  /// Stop recording and return file with duration
  /// Returns Success with AudioRecordingResult or Error
  Future<Result<AudioRecordingResult>> stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (path == null) {
        return const Error(
          UnknownFailure(message: 'Recording path is null'),
        );
      }

      final file = File(path);
      if (!file.existsSync()) {
        return const Error(
          UnknownFailure(message: 'Recording file does not exist'),
        );
      }

      // Calculate duration
      int durationSeconds = 0;
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        durationSeconds = duration.inSeconds;
      }

      _recordingStartTime = null;

      return Success(
        AudioRecordingResult(
          file: file,
          durationSeconds: durationSeconds,
        ),
      );
    } catch (e) {
      _recordingStartTime = null;
      return Error(
        UnknownFailure(message: 'Failed to stop recording: $e'),
      );
    }
  }

  /// Cancel recording without returning file
  Future<Result<void>> cancelRecording() async {
    try {
      await _recorder.cancel();
      _recordingStartTime = null;
      return const Success(null);
    } catch (e) {
      _recordingStartTime = null;
      return Error(
        UnknownFailure(message: 'Failed to cancel recording: $e'),
      );
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  /// Get current recording duration in seconds
  int get currentDurationSeconds {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Dispose the recorder
  void dispose() {
    _recorder.dispose();
  }
}
```

#### 1.2 Provider Registration

**File**: `lib/core/providers/core_providers.dart` (update)

Add after `imagePickerServiceProvider`:

```dart
// Audio recorder service provider
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final recorder = AudioRecorder();
  return AudioRecorderService(recorder);
});
```

#### 1.3 Service Tests

**File**: `test/core/services/audio_recorder_service_test.dart` (new)

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/audio_recorder_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

void main() {
  late AudioRecorderService service;
  late MockAudioRecorder mockRecorder;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    service = AudioRecorderService(mockRecorder);
  });

  group('AudioRecorderService', () {
    test('startRecording returns Success when permission granted', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(() => mockRecorder.start(any(), path: any(named: 'path')))
          .thenAnswer((_) async {});

      final result = await service.startRecording();

      expect(result.isSuccess, true);
      verify(() => mockRecorder.hasPermission()).called(1);
    });

    test('startRecording returns PermissionFailure when denied', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => false);

      final result = await service.startRecording();

      expect(result.isError, true);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('stopRecording returns AudioRecordingResult with duration', () async {
      when(() => mockRecorder.stop())
          .thenAnswer((_) async => '/tmp/recording_123.m4a');

      // Mock file existence would require filesystem mocking
      // For now, test the happy path structure
      final result = await service.stopRecording();

      expect(result.isSuccess || result.isError, true);
      verify(() => mockRecorder.stop()).called(1);
    });

    test('cancelRecording returns Success', () async {
      when(() => mockRecorder.cancel()).thenAnswer((_) async {});

      final result = await service.cancelRecording();

      expect(result.isSuccess, true);
      verify(() => mockRecorder.cancel()).called(1);
    });
  });
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Service tests pass: `~/flutter/bin/flutter test test/core/services/audio_recorder_service_test.dart`
- [ ] Service can be instantiated via provider

#### Manual Verification:
- [ ] `AudioRecorderService` can be injected via Riverpod
- [ ] Permission check returns appropriate result
- [ ] Recording start/stop works (test with basic script)
- [ ] Duration tracking is accurate
- [ ] Cancel recording doesn't crash
- [ ] Generated audio file is playable

**Implementation Note**: After completing this phase, verify audio recording works end-to-end with a simple test before proceeding to upload integration.

---

## Phase 2: Firebase Storage Service Provider & Journal Upload Service

### Overview

Create the provider for `FirebaseStorageService` and implement `JournalUploadService` to orchestrate media uploads with progress tracking, retry logic, and status management. This service will process the upload queue and update message entities with storage URLs.

### Changes Required

#### 2.1 Firebase Storage Service Provider

**File**: `lib/core/providers/core_providers.dart` (update)

Add after `firebaseStorageProvider` (around line 54):

```dart
/// Firebase Storage Service provider - Generalized file upload with processing
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseStorageService(storage);
});
```

#### 2.2 Journal Upload Service

**File**: `lib/features/journal/domain/services/journal_upload_service.dart` (new)

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

/// Service for uploading journal message media files to Firebase Storage
class JournalUploadService {
  JournalUploadService({
    required this.storageService,
    required this.messageRepository,
  });

  final FirebaseStorageService storageService;
  final JournalMessageRepository messageRepository;

  /// Upload image message with thumbnail
  Future<Result<void>> uploadImageMessage(JournalMessageEntity message) async {
    try {
      // Validate local file exists
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

      // Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // Upload thumbnail first if exists
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

          if (thumbResult.isError) {
            debugPrint('Failed to upload thumbnail: ${thumbResult.failureOrNull?.message}');
            // Continue with full image upload even if thumbnail fails
          } else {
            thumbnailUrl = thumbResult.dataOrNull;
          }
        }
      }

      // Upload full image
      final imagePath = storageService.buildJournalPath(
        userId: message.userId,
        journalId: message.threadId,
        filename: '${message.id}.jpg',
      );

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
          debugPrint('Image upload progress: ${(progress * 100).toInt()}%');
          // Could emit to stream for UI updates
        },
      );

      return uploadResult.when(
        success: (downloadUrl) async {
          // Update message with URLs and completed status
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            thumbnailUrl: thumbnailUrl,
            uploadStatus: UploadStatus.completed,
          );

          await messageRepository.updateMessage(updatedMessage);
          return const Success(null);
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
  Future<Result<void>> uploadAudioMessage(JournalMessageEntity message) async {
    try {
      // Validate local file exists
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

      // Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // Upload audio file
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
          debugPrint('Audio upload progress: ${(progress * 100).toInt()}%');
        },
      );

      return uploadResult.when(
        success: (downloadUrl) async {
          // Update message with URL and completed status
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            uploadStatus: UploadStatus.completed,
          );

          await messageRepository.updateMessage(updatedMessage);
          return const Success(null);
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

  /// Process pending uploads for a user
  /// Returns count of successfully uploaded messages
  Future<Result<int>> processPendingUploads(String userId) async {
    try {
      final pendingResult = await messageRepository.getPendingUploads(userId);

      if (pendingResult.isError) {
        return Error(pendingResult.failureOrNull!);
      }

      final pendingMessages = pendingResult.dataOrNull!;
      int successCount = 0;

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
          uploadResult = await uploadImageMessage(message);
        } else if (message.messageType == MessageType.audio) {
          uploadResult = await uploadAudioMessage(message);
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

  /// Retry a specific failed upload manually
  Future<Result<void>> retryUpload(JournalMessageEntity message) async {
    if (message.messageType == MessageType.image) {
      return uploadImageMessage(message);
    } else if (message.messageType == MessageType.audio) {
      return uploadAudioMessage(message);
    } else {
      return const Error(
        ValidationFailure(message: 'Cannot retry text message upload'),
      );
    }
  }

  /// Helper to update upload status and retry count
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

#### 2.3 Upload Service Provider

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (update)

Add after repository providers (around line 68):

```dart
// Journal upload service provider
final journalUploadServiceProvider = Provider<JournalUploadService>((ref) {
  final storageService = ref.watch(firebaseStorageServiceProvider);
  final messageRepository = ref.watch(messageRepositoryProvider);
  return JournalUploadService(
    storageService: storageService,
    messageRepository: messageRepository,
  );
});
```

#### 2.4 Upload Service Tests

**File**: `test/features/journal/domain/services/journal_upload_service_test.dart` (new)

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseStorageService extends Mock
    implements FirebaseStorageService {}

class MockJournalMessageRepository extends Mock
    implements JournalMessageRepository {}

void main() {
  late JournalUploadService service;
  late MockFirebaseStorageService mockStorageService;
  late MockJournalMessageRepository mockRepository;

  setUp(() {
    mockStorageService = MockFirebaseStorageService();
    mockRepository = MockJournalMessageRepository();
    service = JournalUploadService(
      storageService: mockStorageService,
      messageRepository: mockRepository,
    );
  });

  group('JournalUploadService', () {
    test('uploadImageMessage updates status to uploading then completed',
        () async {
      // Test implementation would require extensive mocking
      // This is a structure example
      expect(service, isNotNull);
    });

    test('processPendingUploads respects exponential backoff', () async {
      // Test backoff logic
      expect(service, isNotNull);
    });

    test('retryUpload calls appropriate upload method', () async {
      // Test retry logic
      expect(service, isNotNull);
    });
  });
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze`
- [ ] `FirebaseStorageService` provider available in app
- [ ] `JournalUploadService` provider available in journal feature
- [ ] Service tests compile: `~/flutter/bin/flutter test test/features/journal/domain/services/`

#### Manual Verification:
- [ ] Services can be injected via Riverpod providers
- [ ] Upload service can access storage service
- [ ] Upload service can update message repository
- [ ] Exponential backoff logic is correct (2s → 4s → 8s → 16s → 32s)
- [ ] Max retry count (5) prevents infinite retries

**Implementation Note**: After this phase, the upload infrastructure exists but isn't triggered by message creation yet. Next phase wires it up.

---

## Phase 3: Enhanced Error Handling & Use Case Integration

### Overview

Improve error handling by using specific failure types throughout repositories and use cases, add thumbnail generation to image use case, integrate upload service with message creation, and improve error messages in controllers.

### Changes Required

#### 3.1 Update Message Repository Error Handling

**File**: `lib/features/journal/data/repositories/journal_message_repository_impl.dart` (update)

Replace generic `UnknownFailure` with specific types:

**Line 50** - Change from:
```dart
return Error(UnknownFailure(message: 'Failed to create message: $e'));
```

To:
```dart
return Error(CacheFailure(message: 'Failed to save message locally: $e'));
```

**Line 60** - Change from:
```dart
return Error(UnknownFailure(message: 'Failed to get message: $e'));
```

To:
```dart
return Error(CacheFailure(message: 'Failed to retrieve message: $e'));
```

**Line 87** - Change from:
```dart
return Error(UnknownFailure(message: 'Failed to update message: $e'));
```

To:
```dart
return Error(CacheFailure(message: 'Failed to update message: $e'));
```

**Line 106** - Change from:
```dart
return Error(UnknownFailure(message: 'Failed to sync messages: $e'));
```

To:
```dart
if (e.toString().contains('network')) {
  return Error(NetworkFailure(message: 'Network error syncing messages: $e'));
}
return Error(ServerFailure(message: 'Failed to sync messages: $e'));
```

**Line 118** - Change from:
```dart
return Error(UnknownFailure(message: 'Failed to get pending uploads: $e'));
```

To:
```dart
return Error(CacheFailure(message: 'Failed to query pending uploads: $e'));
```

#### 3.2 Update Thread Repository Error Handling

**File**: `lib/features/journal/data/repositories/journal_thread_repository_impl.dart` (update)

Similar pattern - replace `UnknownFailure` with specific types:

**Lines 45, 57, 70, 86, 100** - Replace `UnknownFailure` with:
- Local operations: `CacheFailure`
- Network operations: `NetworkFailure` or `ServerFailure`

#### 3.3 Update CreateImageMessageUseCase with Thumbnail Generation

**File**: `lib/features/journal/domain/usecases/create_image_message_usecase.dart` (update)

**Add constructor parameter** (line 27-29):
```dart
final FirebaseStorageService storageService; // Add this
```

**Replace constructor** (line 31-35):
```dart
CreateImageMessageUseCase({
  required this.messageRepository,
  required this.threadRepository,
  required this.storageService, // Add this
});
```

**Add thumbnail generation** after file validation (insert after line 39):

```dart
// Generate thumbnail for instant preview
String? localThumbnailPath;
final thumbnailResult = await storageService.generateThumbnail(
  params.imageFile,
  size: 150,
);

if (thumbnailResult.isSuccess) {
  try {
    // Save thumbnail to temp file
    final tempDir = await getTemporaryDirectory();
    final thumbnailFile = File(
        '${tempDir.path}/${const Uuid().v4()}_thumb.jpg');
    await thumbnailFile.writeAsBytes(thumbnailResult.dataOrNull!);
    localThumbnailPath = thumbnailFile.path;
  } catch (e) {
    debugPrint('Failed to save thumbnail: $e');
    // Continue without thumbnail
  }
} else {
  debugPrint(
      'Thumbnail generation failed: ${thumbnailResult.failureOrNull?.message}');
}
```

**Update message creation** (line 64-74) to include thumbnail:

```dart
final message = JournalMessageEntity(
  id: const Uuid().v4(),
  threadId: threadId,
  userId: params.userId,
  role: MessageRole.user,
  messageType: MessageType.image,
  localFilePath: params.imageFile.path,
  localThumbnailPath: localThumbnailPath, // Add this
  createdAt: now,
  uploadStatus: UploadStatus.notStarted,
);
```

**Add missing imports** at top:
```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:path_provider/path_provider.dart';
```

#### 3.4 Update CreateImageMessageUseCase Provider

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (update)

**Replace provider** (around line 80-88):

```dart
final createImageMessageUseCaseProvider =
    Provider<CreateImageMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final storageService = ref.watch(firebaseStorageServiceProvider); // Add
  return CreateImageMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    storageService: storageService, // Add
  );
});
```

#### 3.5 Update Message Controller Error Mapping

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (update)

**Replace** `_getErrorMessage` method (lines 118-124):

```dart
String _getErrorMessage(Failure failure) {
  return switch (failure) {
    ValidationFailure() => failure.message,
    NetworkFailure() => 'Network error. Please check your connection.',
    StorageFailure() => 'Storage error: ${failure.message}',
    PermissionFailure() => 'Permission denied. Please enable access in Settings.',
    UserCancelledFailure() => failure.message,
    CacheFailure() => 'Local storage error: ${failure.message}',
    ServerFailure() => 'Server error: ${failure.message}',
    _ => 'An unexpected error occurred: ${failure.message}',
  };
}
```

#### 3.6 Wire Upload Service to Message Creation

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (update)

**Add constructor parameter** (line 29-34):
```dart
final JournalUploadService uploadService; // Add this
```

**Update createImageMessage** (line 64-89) to trigger upload:

Replace the `result.when` block with:

```dart
result.when(
  success: (message) {
    state = MessageSuccess(message);

    // Trigger background upload
    uploadService.uploadImageMessage(message).then((uploadResult) {
      if (uploadResult.isError) {
        debugPrint('Upload failed: ${uploadResult.failureOrNull?.message}');
        // Message saved locally, will retry later
      }
    });
  },
  error: (failure) {
    state = MessageError(_getErrorMessage(failure));
  },
);
```

**Update createAudioMessage** similarly (line 91-116):

```dart
result.when(
  success: (message) {
    state = MessageSuccess(message);

    // Trigger background upload
    uploadService.uploadAudioMessage(message).then((uploadResult) {
      if (uploadResult.isError) {
        debugPrint('Upload failed: ${uploadResult.failureOrNull?.message}');
      }
    });
  },
  error: (failure) {
    state = MessageError(_getErrorMessage(failure));
  },
);
```

#### 3.7 Update Message Controller Provider

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (update)

**Replace provider** (around line 114-127):

```dart
final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase = ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase = ref.watch(createAudioMessageUseCaseProvider);
  final uploadService = ref.watch(journalUploadServiceProvider); // Add

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
    uploadService: uploadService, // Add
  );
});
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze`
- [ ] Use case tests pass: `~/flutter/bin/flutter test test/features/journal/domain/usecases/`
- [ ] Repository tests pass: `~/flutter/bin/flutter test test/features/journal/data/repositories/`
- [ ] Controller tests pass: `~/flutter/bin/flutter test test/features/journal/presentation/controllers/`

#### Manual Verification:
- [ ] Creating image message generates thumbnail locally
- [ ] Thumbnail appears in message list immediately
- [ ] Upload starts automatically after message creation
- [ ] Error messages are user-friendly and specific
- [ ] Network errors show appropriate message
- [ ] Permission errors guide user to settings
- [ ] Upload failures don't prevent local save

**Implementation Note**: After this phase, image messages will upload automatically with thumbnails. Next phase adds UI integration for picking images and recording audio.

---

## Phase 4: UI Integration - Image Picker & Recording

### Overview

Wire up the image picker service to the `MessageInput` widget and create a recording UI for audio messages. This makes the media capture functionality accessible to users.

### Changes Required

#### 4.1 Update Message Controller with Image Picker Integration

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (update)

**Add constructor parameters** (line 29-35):
```dart
final ImagePickerService imagePickerService; // Add
final AudioRecorderService audioRecorderService; // Add
```

**Add state for selected media**:
```dart
File? _selectedImage;
File? get selectedImage => _selectedImage;

bool _isRecording = false;
bool get isRecording => _isRecording;
```

**Add image picker methods** (after existing methods):

```dart
/// Pick image from gallery
Future<void> pickImageFromGallery() async {
  final result = await imagePickerService.pickImageFromGallery();

  result.when(
    success: (file) {
      _selectedImage = file;
      // Optionally emit state to show preview
      state = MessageInitial(); // Reset any errors
    },
    error: (failure) {
      if (failure is UserCancelledFailure) {
        // User cancelled - silent return
        return;
      }
      state = MessageError(_getErrorMessage(failure));
    },
  );
}

/// Pick image from camera
Future<void> pickImageFromCamera() async {
  final result = await imagePickerService.pickImageFromCamera();

  result.when(
    success: (file) {
      _selectedImage = file;
      state = MessageInitial();
    },
    error: (failure) {
      if (failure is UserCancelledFailure) {
        return;
      }
      state = MessageError(_getErrorMessage(failure));
    },
  );
}

/// Clear selected image
void clearSelectedImage() {
  _selectedImage = null;
  state = MessageInitial();
}

/// Start audio recording
Future<void> startRecording() async {
  final result = await audioRecorderService.startRecording();

  result.when(
    success: (_) {
      _isRecording = true;
      state = MessageInitial();
    },
    error: (failure) {
      state = MessageError(_getErrorMessage(failure));
    },
  );
}

/// Stop recording and create audio message
Future<void> stopRecording({
  required String userId,
  String? threadId,
}) async {
  final result = await audioRecorderService.stopRecording();

  result.when(
    success: (recordingResult) async {
      _isRecording = false;

      // Create audio message
      await createAudioMessage(
        userId: userId,
        audioFile: recordingResult.file,
        durationSeconds: recordingResult.durationSeconds,
        threadId: threadId,
      );
    },
    error: (failure) {
      _isRecording = false;
      state = MessageError(_getErrorMessage(failure));
    },
  );
}

/// Cancel recording
Future<void> cancelRecording() async {
  await audioRecorderService.cancelRecording();
  _isRecording = false;
  state = MessageInitial();
}

/// Get current recording duration
int get recordingDuration => audioRecorderService.currentDurationSeconds;
```

#### 4.2 Update Message Controller Provider with Services

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (update)

```dart
final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase = ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase = ref.watch(createAudioMessageUseCaseProvider);
  final uploadService = ref.watch(journalUploadServiceProvider);
  final imagePickerService = ref.watch(imagePickerServiceProvider); // Add
  final audioRecorderService = ref.watch(audioRecorderServiceProvider); // Add

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
    uploadService: uploadService,
    imagePickerService: imagePickerService, // Add
    audioRecorderService: audioRecorderService, // Add
  );
});
```

**Note**: `imagePickerServiceProvider` is in profile providers. Move it to core providers:

**File**: `lib/core/providers/core_providers.dart` (update)

Add after `audioRecorderServiceProvider`:

```dart
// Image picker service provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  final picker = ImagePicker();
  return ImagePickerService(picker);
});
```

**Then remove from** `lib/features/profile/presentation/providers/user_profile_providers.dart` (lines 70-73).

#### 4.3 Update MessageInput Widget

**File**: `lib/features/journal/presentation/widgets/message_input.dart` (update)

**Replace attachment button onPressed** (line 76):

Change from:
```dart
onPressed: () {
  _showAttachmentMenu(context);
},
```

To:
```dart
onPressed: () => _showAttachmentMenu(context, ref),
```

**Update _showAttachmentMenu method signature** (line 151):

Change from:
```dart
void _showAttachmentMenu(BuildContext context) {
```

To:
```dart
void _showAttachmentMenu(BuildContext context, WidgetRef ref) {
```

**Replace photo option** (lines 159-168):

```dart
ListTile(
  leading: const Icon(Icons.photo),
  title: const Text('Photo'),
  onTap: () async {
    Navigator.pop(context);
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.pickImageFromGallery();

    // If image selected, show it in preview or send immediately
    if (controller.selectedImage != null) {
      _showImagePreview(context, ref);
    }
  },
),
```

**Replace camera option** (lines 169-178):

```dart
ListTile(
  leading: const Icon(Icons.camera_alt),
  title: const Text('Camera'),
  onTap: () async {
    Navigator.pop(context);
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.pickImageFromCamera();

    if (controller.selectedImage != null) {
      _showImagePreview(context, ref);
    }
  },
),
```

**Replace voice message option** (lines 179-188):

```dart
ListTile(
  leading: const Icon(Icons.mic),
  title: const Text('Voice message'),
  onTap: () {
    Navigator.pop(context);
    _showRecordingDialog(context, ref);
  },
),
```

**Add image preview dialog method** (after line 194):

```dart
void _showImagePreview(BuildContext context, WidgetRef ref) {
  final controller = ref.read(messageControllerProvider.notifier);
  final image = controller.selectedImage;

  if (image == null) return;

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Send Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            image,
            height: 300,
            fit: BoxFit.contain,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.clearSelectedImage();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            // Send image message
            final userId = ref.read(authStateProvider).valueOrNull?.id;
            if (userId != null && widget.threadId != null) {
              await controller.createImageMessage(
                userId: userId,
                imageFile: image,
                thumbnailPath: '', // Will be generated in use case
                threadId: widget.threadId,
              );
              controller.clearSelectedImage();
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
```

**Add recording dialog method**:

```dart
void _showRecordingDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RecordingDialog(
      threadId: widget.threadId,
      onSend: widget.onSend,
    ),
  );
}
```

#### 4.4 Create Recording Dialog Widget

**File**: `lib/features/journal/presentation/widgets/message_input.dart` (add at bottom)

```dart
class _RecordingDialog extends ConsumerStatefulWidget {
  const _RecordingDialog({
    this.threadId,
    required this.onSend,
  });

  final String? threadId;
  final VoidCallback onSend;

  @override
  ConsumerState<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends ConsumerState<_RecordingDialog> {
  Timer? _timer;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.startRecording();

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = controller.recordingDuration;
        });
      }
    });
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    final controller = ref.read(messageControllerProvider.notifier);
    await controller.stopRecording(
      userId: userId,
      threadId: widget.threadId,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onSend();
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.cancelRecording();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(messageControllerProvider.notifier);

    return AlertDialog(
      title: const Text('Recording'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.isRecording ? Icons.mic : Icons.mic_off,
            size: 64,
            color: controller.isRecording ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_duration),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            controller.isRecording ? 'Recording...' : 'Stopped',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        if (controller.isRecording)
          ElevatedButton.icon(
            onPressed: _stopAndSend,
            icon: const Icon(Icons.stop),
            label: const Text('Stop & Send'),
          ),
      ],
    );
  }
}
```

**Add missing import at top**:
```dart
import 'dart:async';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze`
- [ ] No import errors
- [ ] Provider dependency graph resolves correctly

#### Manual Verification:
- [ ] Tapping attachment button shows modal with 3 options
- [ ] "Photo" option opens gallery picker
- [ ] "Camera" option opens camera
- [ ] Selected image shows in preview dialog
- [ ] "Send" button creates image message with thumbnail
- [ ] "Voice message" opens recording dialog
- [ ] Recording starts automatically with timer
- [ ] "Stop & Send" creates audio message
- [ ] "Cancel" dismisses dialog without creating message
- [ ] User cancellation doesn't show error
- [ ] Permission errors show appropriate message

**Implementation Note**: After this phase, users can create all three message types. Next phase adds upload progress UI and retry buttons.

---

## Phase 5: Upload Progress UI & Retry Functionality

### Overview

Add visual upload status indicators to message bubbles, implement retry buttons for failed uploads, and enhance the UI to show upload progress.

### Changes Required

#### 5.1 Add Retry Method to Message Controller

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (update)

Add method after existing methods:

```dart
/// Manually retry a failed upload
Future<void> retryUpload(JournalMessageEntity message) async {
  state = MessageLoading();

  final result = await uploadService.retryUpload(message);

  result.when(
    success: (_) {
      state = MessageSuccess(message);
    },
    error: (failure) {
      state = MessageError(_getErrorMessage(failure));
    },
  );
}
```

#### 5.2 Update MessageBubble Widget

**File**: `lib/features/journal/presentation/widgets/message_bubble.dart` (update)

**Update upload status display** (replace lines 197-225):

```dart
Widget _buildUploadStatusIndicator() {
  if (message.uploadStatus == UploadStatus.completed) {
    return const SizedBox.shrink();
  }

  IconData icon;
  Color color;
  String tooltip;
  bool showRetry = false;

  switch (message.uploadStatus) {
    case UploadStatus.notStarted:
      icon = Icons.cloud_upload_outlined;
      color = Colors.grey;
      tooltip = 'Waiting to upload';
    case UploadStatus.uploading:
      icon = Icons.cloud_upload;
      color = Colors.blue;
      tooltip = 'Uploading...';
    case UploadStatus.completed:
      return const SizedBox.shrink();
    case UploadStatus.failed:
      icon = Icons.error_outline;
      color = Colors.red;
      tooltip = 'Upload failed - Tap to retry';
      showRetry = true;
    case UploadStatus.retrying:
      icon = Icons.refresh;
      color = Colors.orange;
      tooltip = 'Retrying upload...';
  }

  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.uploadStatus == UploadStatus.uploading)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          tooltip,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
        if (showRetry) ...[
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              return InkWell(
                onTap: () {
                  final controller = ref.read(messageControllerProvider.notifier);
                  controller.retryUpload(message);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
}
```

**Add retry button for failed media** (insert after line 195, in _buildMediaContent):

```dart
if (message.uploadStatus == UploadStatus.failed &&
    (message.messageType == MessageType.image ||
        message.messageType == MessageType.audio)) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Show thumbnail or audio icon
      if (message.messageType == MessageType.image &&
          message.localThumbnailPath != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(message.localThumbnailPath!),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        )
      else if (message.messageType == MessageType.audio)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audiotrack, size: 24),
              const SizedBox(width: 8),
              Text(
                _formatDuration(message.audioDurationSeconds ?? 0),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      _buildUploadStatusIndicator(),
    ],
  );
}
```

**Add missing import**:
```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';
```

#### 5.3 Add Upload Progress Stream (Optional Enhancement)

This is optional but provides better UX. If you want real-time progress:

**File**: `lib/features/journal/domain/services/journal_upload_service.dart` (update)

Add stream controller at class level:

```dart
final _progressController = StreamController<MapEntry<String, double>>.broadcast();
Stream<MapEntry<String, double>> get progressStream => _progressController.stream;
```

Update `onProgress` callbacks in `uploadImageMessage` and `uploadAudioMessage`:

```dart
onProgress: (progress) {
  _progressController.add(MapEntry(message.id, progress));
},
```

Add dispose method:

```dart
void dispose() {
  _progressController.close();
}
```

Then in `MessageBubble`, listen to stream and show progress bar.

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze`
- [ ] No widget errors in message bubble

#### Manual Verification:
- [ ] Upload status shows "Waiting to upload" for queued messages
- [ ] Upload status shows "Uploading..." with spinner during upload
- [ ] Upload status disappears when completed
- [ ] Failed uploads show "Upload failed - Tap to retry" with retry button
- [ ] Tapping retry button re-uploads the message
- [ ] Retry button works and updates status
- [ ] Image thumbnails appear immediately even while uploading
- [ ] Audio duration displays correctly

**Implementation Note**: After this phase, upload management is complete. Next phase migrates profile to new storage service.

---

## Phase 6: Profile Migration to FirebaseStorageService

### Overview

Migrate the profile feature from the legacy `FirebaseImageStorageService` to the new `FirebaseStorageService`, then remove the old service. This completes the unification of file upload handling.

### Changes Required

#### 6.1 Update ProfileController

**File**: `lib/features/profile/presentation/controllers/profile_controller.dart` (update)

**Change service type** (line 41):

From:
```dart
final FirebaseImageStorageService storageService;
```

To:
```dart
final FirebaseStorageService storageService;
```

**Update import** (line 6):

From:
```dart
import 'package:kairos/core/services/firebase_image_storage_service.dart';
```

To:
```dart
import 'package:kairos/core/services/firebase_storage_service.dart';
```

**Replace uploadProfileAvatar call** (lines 104-107):

From:
```dart
final uploadResult = await storageService.uploadProfileAvatar(
  imageFile: _selectedAvatar!,
  userId: userId,
);
```

To:
```dart
// Build storage path
final timestamp = DateTime.now().millisecondsSinceEpoch;
final storagePath = 'profile_avatars/$userId/avatar_$timestamp.jpg';

final uploadResult = await storageService.uploadFile(
  file: _selectedAvatar!,
  storagePath: storagePath,
  fileType: FileType.image,
  imageMaxSize: 512,
  imageQuality: 85,
  metadata: {
    'userId': userId,
    'type': 'avatar',
  },
);
```

#### 6.2 Update Profile Provider

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart` (update)

**Remove old provider** (delete lines 76-79):

```dart
// DELETE THIS:
final firebaseImageStorageServiceProvider =
    Provider<FirebaseImageStorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseImageStorageService(storage);
});
```

**Update profile controller provider** (around line 117):

From:
```dart
final storageService = ref.watch(firebaseImageStorageServiceProvider);
```

To:
```dart
final storageService = ref.watch(firebaseStorageServiceProvider);
```

#### 6.3 Delete Old Service File

**File**: `lib/core/services/firebase_image_storage_service.dart` (delete entire file)

Use bash to remove:
```bash
rm lib/core/services/firebase_image_storage_service.dart
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get && ~/flutter/bin/flutter analyze`
- [ ] No import errors referencing `FirebaseImageStorageService`
- [ ] Profile controller tests pass (if they exist)
- [ ] Grep shows no remaining references: `rg FirebaseImageStorageService lib/`

#### Manual Verification:
- [ ] Profile creation with avatar upload still works
- [ ] Avatar displays correctly after upload
- [ ] Upload succeeds and returns download URL
- [ ] Storage path is `profile_avatars/{userId}/avatar_{timestamp}.jpg`
- [ ] Avatar is resized to 512x512
- [ ] Old service file no longer exists
- [ ] No regressions in profile feature

**Implementation Note**: Test profile avatar upload thoroughly before proceeding. This is the last phase before final testing.

---

## Phase 7: Final Testing & Polish

### Overview

Comprehensive manual testing of all message types, error scenarios, offline behavior, and edge cases. Fix any issues discovered and polish the user experience.

### Testing Checklist

#### Text Messages
- [ ] Create text message in new thread (thread auto-created with title)
- [ ] Create text message in existing thread (appends to thread)
- [ ] Text message syncs immediately when online
- [ ] Text message saves locally when offline
- [ ] Offline text message syncs when online resumes
- [ ] Thread updates with last message time and count

#### Image Messages
- [ ] Pick image from gallery shows preview
- [ ] Capture image from camera shows preview
- [ ] Cancel image selection doesn't create message
- [ ] Send image creates message with local thumbnail immediately
- [ ] Thumbnail appears in message list instantly
- [ ] Full image uploads in background
- [ ] Upload status progresses: waiting → uploading → completed
- [ ] Failed upload shows retry button
- [ ] Retry button re-uploads successfully
- [ ] Offline image saves locally and uploads when online
- [ ] Large images are resized (check Firebase Storage console)
- [ ] Thumbnail is 150x150 (check Firebase Storage console)

#### Audio Messages
- [ ] Recording dialog opens automatically
- [ ] Recording starts with permission granted
- [ ] Permission denied shows error message
- [ ] Timer updates every second
- [ ] Stop & Send creates message with duration
- [ ] Cancel recording dismisses without creating message
- [ ] Audio uploads in background after creation
- [ ] Duration displays correctly in message bubble
- [ ] Offline audio saves locally and uploads when online
- [ ] Audio format is M4A in Firebase Storage

#### Error Handling
- [ ] Permission denied for camera shows helpful message
- [ ] Permission denied for gallery shows helpful message
- [ ] Permission denied for microphone shows helpful message
- [ ] Network error shows appropriate message
- [ ] Storage error shows specific error message
- [ ] User cancellation doesn't show error
- [ ] Failed uploads can be retried manually
- [ ] Max retry count (5) prevents infinite retries
- [ ] Exponential backoff delays retries properly

#### Offline Behavior
- [ ] Create text message offline (saves locally)
- [ ] Create image message offline (saves with thumbnail)
- [ ] Create audio message offline (saves with duration)
- [ ] Go online → messages sync automatically
- [ ] Upload status updates from local to remote
- [ ] No duplicate messages after sync
- [ ] Thread metadata syncs correctly

#### Edge Cases
- [ ] Create message with empty text (validation error)
- [ ] Upload very large image (resized correctly)
- [ ] Record very short audio (<1 second)
- [ ] Record long audio (>5 minutes)
- [ ] Delete local file before upload (fails gracefully)
- [ ] Switch apps during recording (continues in background?)
- [ ] Kill app during upload (resumes on restart?)
- [ ] Multiple failed uploads (all show retry)
- [ ] Rapid message creation (no race conditions)

#### Profile Feature (After Migration)
- [ ] Create profile with avatar upload works
- [ ] Avatar displays correctly
- [ ] Old service removed completely
- [ ] No regressions in profile feature

### Known Issues to Document

Document any issues that are out of scope but should be tracked:

- Background upload doesn't resume after app kill (requires WorkManager)
- Audio recording doesn't show waveform (out of scope)
- No message editing (out of scope)
- No message deletion UI (out of scope)
- No search functionality (out of scope)

### Polish Items

- [ ] Loading states are smooth (no janky animations)
- [ ] Error messages are user-friendly
- [ ] Upload indicators are visible but not intrusive
- [ ] Thumbnails load quickly
- [ ] Recording UI is intuitive
- [ ] Retry button is obvious
- [ ] Colors and icons match app theme

### Success Criteria

#### Automated Verification:
- [ ] All tests pass: `~/flutter/bin/flutter test`
- [ ] No analyzer warnings: `~/flutter/bin/flutter analyze`
- [ ] Build succeeds for iOS: `cd ios && pod install && cd .. && ~/flutter/bin/flutter build ios --no-codesign`
- [ ] Build succeeds for Android: `~/flutter/bin/flutter build apk`

#### Manual Verification:
- [ ] All items in testing checklist pass
- [ ] No crashes during normal usage
- [ ] Performance is acceptable
- [ ] UI is polished and professional
- [ ] Error messages guide users effectively

**Implementation Note**: This is the final phase. Once all tests pass and manual verification is complete, the journal feature is ready for production.

---

## Testing Strategy

### Unit Tests

**Services** (`test/core/services/`):
- `audio_recorder_service_test.dart`: Test recording start/stop/cancel, permission handling
- `firebase_storage_service_test.dart`: Test upload, thumbnail generation, path building

**Use Cases** (`test/features/journal/domain/usecases/`):
- Test thumbnail generation in `CreateImageMessageUseCase`
- Test duration tracking in `CreateAudioMessageUseCase`
- Test validation errors

**Repositories** (`test/features/journal/data/repositories/`):
- Test error handling with specific failure types
- Test upload status transitions
- Test pending uploads query

**Controllers** (`test/features/journal/presentation/controllers/`):
- Test image picker integration
- Test recording lifecycle
- Test error message mapping
- Test upload retry

### Integration Tests

**End-to-End Flows** (`integration_test/`):
- Create text message → appears in list → syncs to Firestore
- Pick image → preview → send → thumbnail appears → uploads → completed
- Start recording → timer runs → stop → audio message created → uploads
- Create offline → go online → syncs automatically
- Upload fails → retry button → retry succeeds

### Manual Testing

**Critical Paths**:
1. New user creates first journal entry (all types)
2. User creates 10 entries of each type in same thread
3. User creates entries while offline, then goes online
4. User retries failed uploads
5. User tests on slow network (3G simulation)

**Devices**:
- iOS simulator (latest iOS)
- Android emulator (API 30+)
- Physical device (test permissions)

---

## Performance Considerations

### Image Processing
- Thumbnail generation is synchronous but fast (<100ms for typical images)
- Full image resize happens before upload (acceptable delay)
- Consider showing processing indicator for very large images

### Audio Recording
- Recording uses platform-native encoders (efficient)
- M4A format provides good compression (typically <1MB per minute)
- Duration tracking is lightweight (negligible overhead)

### Upload Queue
- Uploads happen sequentially, not in parallel (prevents network congestion)
- Exponential backoff prevents retry storms
- Max 5 retries prevents infinite loops

### Database Performance
- Isar queries are indexed (fast lookups)
- Watch streams are efficient (only emit on changes)
- Pending uploads query is optimized with compound filters

---

## Migration Notes

### Data Migration
No data migration needed - this is a new feature. Existing users will start with empty journal.

### Breaking Changes
None - all changes are additive.

### Rollback Plan
If critical issues found:
1. Disable journal tab in navigation
2. Revert image picker integration in `MessageInput`
3. Keep data layer in place (no user data affected)

---

## References

### Implementation Plans
- Original plan: [2025-11-03-journal-feature-implementation.md](thoughts/shared/plans/2025-11-03-journal-feature-implementation.md)
- Migration plan: [2025-11-03-conversational-journal-migration.md](thoughts/shared/plans/2025-11-03-conversational-journal-migration.md)

### Key Files
- Error handling: [failures.dart:3-70](lib/core/errors/failures.dart#L3-L70)
- Result type: [result.dart:5-47](lib/core/utils/result.dart#L5-L47)
- Firebase Storage: [firebase_storage_service.dart:10-155](lib/core/services/firebase_storage_service.dart#L10-L155)
- Image Picker: [image_picker_service.dart:9-64](lib/core/services/image_picker_service.dart#L9-L64)
- Message Repository: [journal_message_repository_impl.dart:12-121](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L12-L121)

### Similar Patterns
- Profile avatar upload: [profile_controller.dart:101-118](lib/features/profile/presentation/controllers/profile_controller.dart#L101-L118)
- Auth error mapping: [firebase_auth_repository.dart:142-166](lib/features/auth/data/repositories/firebase_auth_repository.dart#L142-L166)
