# Thread Deletion (MVP) Implementation Plan

## Overview

Implement a simple, reliable thread deletion feature that allows users to delete journal threads and their associated messages. The implementation follows a **remote-first, online-only, hard-delete with Cloud Function cascade that permanently removes messages and associated media files** approach to minimize client complexity while ensuring multi-device consistency.

## Current State Analysis

### Existing Infrastructure:
- **Data Models** already support soft deletion:
  - [journal_thread_model.dart:76](lib/features/journal/data/models/journal_thread_model.dart#L76) has `isDeleted` field
  - [journal_message_model.dart:124](lib/features/journal/data/models/journal_message_model.dart#L124) has `isDeleted` field
- **Local data sources** already filter deleted items:
  - Thread queries use `.isDeletedEqualTo(false)` filter
  - Message queries use `.isDeletedEqualTo(false)` filter
- **Repository pattern** is local-first for creates/updates but can be adapted for remote-first deletion
- **Cloud Functions** exist for message processing, transcription, and insights
- **Firestore collections**: `journalThreads`, `journalMessages`
- **Cloud Storage**: stores audio files and images referenced by messages

### Current Gaps:
- ❌ No `deleteThread()` method in repository interface or implementation
- ❌ No `DeleteThreadUseCase` exists
- ❌ No controller action for thread deletion
- ❌ No Cloud Function to cascade-delete messages when thread is deleted
- ❌ No storage cleanup for deleted thread media files
- ❌ Domain entity doesn't expose `isDeleted` or `deletedAt` (intentional - data layer only)

## Desired End State

### Success Criteria:

#### Automated Verification:
- [x] Thread soft-delete updates Firestore: manual Firestore console check or integration test
- [x] Messages and their media files permanently deleted by Cloud Function: verify via Firestore console (messages should not exist)
- [x] Local thread and messages hard-deleted: verify via Isar Inspector
- [x] Storage files deleted: verify via Firebase Storage console (audio/image files should not exist)
- [x] TypeScript compiles without errors: `cd functions && npm run build`
- [x] Firestore rules permit authorized deletions: `firebase deploy --only firestore:rules`
- [x] Unit tests pass: `~/flutter/bin/flutter test`

#### Manual Verification:
- [x] User can delete a thread when online → thread disappears from thread list
- [x] Attempting deletion while offline shows "You must be online to delete" error
- [x] Deleted thread's messages are completely removed from Firestore within ~5 seconds (not just marked deleted)
- [x] Media files (audio/images) are permanently deleted from Cloud Storage within ~30 seconds
- [x] Deletion syncs across devices (delete on device A, disappears on device B)
- [x] Confirmation dialog appears before deletion
- [x] Cannot create new messages in a deleted thread (Firestore security rules validation)

**Implementation Note**: After completing Phase 1 (Flutter client implementation) and all automated verification passes, pause for manual confirmation that deletion works correctly before proceeding to Phase 2 (Cloud Function cascade).

---

## What We're NOT Doing

To maintain MVP scope and avoid complexity:

- ❌ **Offline deletion queue** - No retry mechanism for offline deletions
- ❌ **Undo/restore feature** - Messages and media are permanently deleted (thread soft-deleted for potential recovery window)
- ❌ **Batch deletion** - Only single thread deletion supported
- ❌ **Archive before delete** - Direct deletion without archiving first
- ❌ **Soft-delete for messages** - Messages are permanently hard-deleted (only threads use soft-delete)
- ❌ **Optimistic UI updates** - Wait for remote success before updating local state
- ❌ **Local-first deletion** - Using remote-first approach to avoid sync conflicts

---

## Implementation Approach

### Remote-First Strategy:
1. **Pre-check connectivity** - Fail fast if offline
2. **Remote soft-delete thread first** - Set `isDeleted=true`, add `deletedAtMillis` on thread, then immediately cascade to hard-delete all messages and related media files via Cloud Function
3. **Wait for remote success** - Block until Firestore confirms
4. **Local hard-delete after** - Remove from Isar to free space
5. **Cloud Function cascade** - Permanently delete all messages in Firestore and their related audio/image files in Cloud Storage

### Why Remote-First (Not Local-First)?
- **Single source of truth**: Remote change triggers all devices
- **Simpler sync**: Firestore listeners propagate to all clients
- **Avoids race conditions**: No local-then-remote conflict resolution needed
- **Atomic cascade**: Cloud Functions handle batch operations reliably
- **No retry queue needed**: Either succeeds immediately or fails visibly

---

## Phase 1: Flutter Client - Thread Deletion

### Overview
Implement the client-side thread deletion flow: use case, repository methods, data source updates, and controller integration.

---

### Changes Required:

#### 1. Domain Layer - Repository Interface

**File**: [lib/features/journal/domain/repositories/journal_thread_repository.dart](lib/features/journal/domain/repositories/journal_thread_repository.dart)

**Changes**: Add `deleteThread` method to interface

```dart
abstract class JournalThreadRepository {
  // ... existing methods ...

  /// Deletes a thread and its messages remotely, then removes local data.
  ///
  /// This operation requires an active internet connection. If the device
  /// is offline, it will return a [NetworkFailure].
  ///
  /// The deletion is performed remotely first (soft delete thread in Firestore),
  /// then local data is hard-deleted. A Cloud Function will permanently hard-delete
  /// all messages and media files associated with this thread.
  ///
  /// Returns [Success] if deletion completes successfully.
  /// Returns [Error] with [NetworkFailure] if offline.
  /// Returns [Error] with [ServerFailure] if remote deletion fails.
  Future<Result<void>> deleteThread(String threadId);
}
```

---

#### 2. Domain Layer - Use Case

**File**: `lib/features/journal/domain/usecases/delete_thread_usecase.dart` (NEW FILE)

**Changes**: Create new use case following existing patterns

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';

class DeleteThreadUseCase {
  DeleteThreadUseCase({
    required this.threadRepository,
  });

  final JournalThreadRepository threadRepository;

  /// Deletes a thread and all its associated messages.
  ///
  /// This operation requires internet connectivity and performs a remote-first
  /// deletion to ensure consistency across devices.
  ///
  /// Returns [Success] if the thread was deleted successfully.
  /// Returns [Error] with [NetworkFailure] if the device is offline.
  /// Returns [Error] with [ServerFailure] if the remote deletion fails.
  Future<Result<void>> call(String threadId) async {
    return await threadRepository.deleteThread(threadId);
  }
}
```

---

#### 3. Data Layer - Remote Data Source

**File**: [lib/features/journal/data/datasources/journal_thread_remote_datasource.dart](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart)

**Changes**: Add `softDeleteThread` method to interface and implementation

```dart
abstract class JournalThreadRemoteDataSource {
  // ... existing methods ...

  /// Soft-deletes a thread in Firestore by setting isDeleted=true and deletedAtMillis.
  Future<void> softDeleteThread(String threadId);
}

class JournalThreadRemoteDataSourceImpl implements JournalThreadRemoteDataSource {
  // ... existing implementation ...

  @override
  Future<void> softDeleteThread(String threadId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _collection.doc(threadId).update({
      'isDeleted': true,
      'deletedAtMillis': now,
      'updatedAtMillis': now,
    });
  }
}
```

---

#### 4. Data Layer - Local Data Source

**File**: [lib/features/journal/data/datasources/journal_thread_local_datasource.dart](lib/features/journal/data/datasources/journal_thread_local_datasource.dart)

**Changes**: Add `hardDeleteThreadAndMessages` method

```dart
abstract class JournalThreadLocalDataSource {
  // ... existing methods ...

  /// Hard-deletes a thread and all its messages from local storage.
  /// This physically removes the data from Isar to free up space.
  Future<void> hardDeleteThreadAndMessages(String threadId);
}

class JournalThreadLocalDataSourceImpl implements JournalThreadLocalDataSource {
  // ... existing implementation ...

  @override
  Future<void> hardDeleteThreadAndMessages(String threadId) async {
    await isar.writeTxn(() async {
      // Delete the thread
      final thread = await isar.journalThreadModels
          .filter()
          .idEqualTo(threadId)
          .findFirst();

      if (thread != null) {
        await isar.journalThreadModels.delete(thread.isarId);
      }

      // Delete all messages for this thread
      final messages = await isar.journalMessageModels
          .filter()
          .threadIdEqualTo(threadId)
          .findAll();

      for (final message in messages) {
        await isar.journalMessageModels.delete(message.isarId);
      }
    });
  }
}
```

---

#### 5. Data Layer - Message Local Data Source (Delete by Thread)

**File**: [lib/features/journal/data/datasources/journal_message_local_datasource.dart](lib/features/journal/data/datasources/journal_message_local_datasource.dart)

**Changes**: If not already covered by thread deletion, ensure we can delete messages by threadId

**Note**: The thread local data source already handles this in `hardDeleteThreadAndMessages`, but we could extract this into the message data source if preferred for separation of concerns. For MVP, keeping it in thread data source is simpler.

---

#### 6. Data Layer - Repository Implementation

**File**: [lib/features/journal/data/repositories/journal_thread_repository_impl.dart](lib/features/journal/data/repositories/journal_thread_repository_impl.dart)

**Changes**: Implement `deleteThread` method

```dart
@override
Future<Result<void>> deleteThread(String threadId) async {
  try {
    // Pre-check: Must be online for deletion
    if (!await _isOnline) {
      return const Error(
        NetworkFailure(message: 'You must be online to delete this thread'),
      );
    }

    // Step 1: Remote soft-delete first (sets isDeleted=true in Firestore)
    try {
      await remoteDataSource.softDeleteThread(threadId);
      debugPrint('✅ Remote soft-delete successful for thread: $threadId');
    } catch (e) {
      debugPrint('❌ Remote deletion failed: $e');
      return Error(
        ServerFailure(message: 'Failed to delete thread: $e'),
      );
    }

    // Step 2: Local hard-delete after remote success
    try {
      await localDataSource.hardDeleteThreadAndMessages(threadId);
      debugPrint('✅ Local hard-delete successful for thread: $threadId');
    } catch (e) {
      debugPrint('⚠️ Local deletion failed (remote already deleted): $e');
      // Don't fail the operation - remote deletion succeeded
      // Local data will be cleaned up on next sync
    }

    return const Success(null);
  } catch (e) {
    return Error(
      ServerFailure(message: 'Unexpected error deleting thread: $e'),
    );
  }
}
```

---

#### 7. Presentation Layer - Use Case Provider

**File**: [lib/features/journal/presentation/providers/journal_providers.dart](lib/features/journal/presentation/providers/journal_providers.dart)

**Changes**: Add provider for `DeleteThreadUseCase`

```dart
import 'package:kairos/features/journal/domain/usecases/delete_thread_usecase.dart';

// Add this provider
final deleteThreadUseCaseProvider = Provider<DeleteThreadUseCase>((ref) {
  final threadRepository = ref.watch(threadRepositoryProvider);
  return DeleteThreadUseCase(threadRepository: threadRepository);
});
```

---

#### 8. Presentation Layer - Thread Controller

**File**: [lib/features/journal/presentation/controllers/thread_controller.dart](lib/features/journal/presentation/controllers/thread_controller.dart) (NEW FILE - or add to existing controller)

**Changes**: Create controller with delete action

**Option A**: Create dedicated `ThreadController` (recommended for separation of concerns)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/journal/domain/usecases/delete_thread_usecase.dart';

// Thread-specific state
sealed class ThreadState {
  const ThreadState();
}

class ThreadInitial extends ThreadState {
  const ThreadInitial();
}

class ThreadDeleting extends ThreadState {
  const ThreadDeleting();
}

class ThreadDeleteSuccess extends ThreadState {
  const ThreadDeleteSuccess();
}

class ThreadDeleteError extends ThreadState {
  const ThreadDeleteError(this.message);
  final String message;
}

// Thread controller
class ThreadController extends StateNotifier<ThreadState> {
  ThreadController({
    required this.deleteThreadUseCase,
  }) : super(const ThreadInitial());

  final DeleteThreadUseCase deleteThreadUseCase;

  Future<void> deleteThread(String threadId) async {
    state = const ThreadDeleting();

    final result = await deleteThreadUseCase(threadId);

    result.when(
      success: (_) {
        state = const ThreadDeleteSuccess();
      },
      error: (failure) {
        state = ThreadDeleteError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure(:final message) => message,
      NetworkFailure(:final message) => message,
      ServerFailure(:final message) => message,
      CacheFailure(:final message) => message,
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = const ThreadInitial();
  }
}
```

**Option B**: Add to existing `MessageController` (simpler, but mixes concerns)
- Add `deleteThread` method to existing controller
- Extend `MessageState` with delete states

**Recommendation**: Use Option A for cleaner separation.

---

#### 9. Presentation Layer - Thread Controller Provider

**File**: [lib/features/journal/presentation/providers/journal_providers.dart](lib/features/journal/presentation/providers/journal_providers.dart)

**Changes**: Add provider for `ThreadController`

```dart
import 'package:kairos/features/journal/presentation/controllers/thread_controller.dart';

final threadControllerProvider =
    StateNotifierProvider<ThreadController, ThreadState>((ref) {
  final deleteThreadUseCase = ref.watch(deleteThreadUseCaseProvider);
  return ThreadController(deleteThreadUseCase: deleteThreadUseCase);
});
```

---

#### 10. Presentation Layer - UI Integration

**File**: [lib/features/journal/presentation/screens/thread_list_screen.dart](lib/features/journal/presentation/screens/thread_list_screen.dart)

**Changes**: Add delete button with confirmation dialog

```dart
// In the thread list item widget (likely a ListTile or Card)
Widget _buildThreadItem(BuildContext context, WidgetRef ref, JournalThreadEntity thread) {
  return Dismissible(
    key: Key(thread.id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      return await _showDeleteConfirmationDialog(context);
    },
    onDismissed: (direction) {
      ref.read(threadControllerProvider.notifier).deleteThread(thread.id);
    },
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    child: ListTile(
      title: Text(thread.title ?? 'Untitled'),
      subtitle: Text(/* ... */),
      // ... other properties
    ),
  );
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Thread'),
      content: const Text(
        'Are you sure you want to delete this thread? '
        'This will also delete all messages and media files. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  ) ?? false;
}

// Add listener for delete state
@override
Widget build(BuildContext context) {
  ref.listen<ThreadState>(threadControllerProvider, (previous, next) {
    if (next is ThreadDeleteError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.message),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(threadControllerProvider.notifier).reset();
    } else if (next is ThreadDeleteSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread deleted successfully')),
      );
      ref.read(threadControllerProvider.notifier).reset();
    }
  });

  // ... rest of build method
}
```

---

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `~/flutter/bin/flutter analyze`
- [x] Code formatting passes: `~/flutter/bin/dart format --set-exit-if-changed .`
- [x] Unit tests pass: `~/flutter/bin/flutter test`
- [x] Repository method can be called: Write integration test that mocks remote/local sources

#### Manual Verification:
- [x] Thread delete button appears in UI (swipe left on thread)
- [x] Confirmation dialog shows before deletion
- [x] When online: Thread deletion succeeds and thread disappears from list
- [x] When offline: Error toast shows "You must be online to delete this thread"
- [x] Deleted thread is marked `isDeleted=true` in Firestore (check console)
- [x] Deleted thread is removed from local Isar database (check Isar Inspector)

**Implementation Note**: After completing this phase and verifying manual tests, proceed to Phase 2.

---

## Phase 2: Cloud Function - Cascade Deletion

### Overview
Create a Cloud Function that automatically permanently deletes all messages and media files when a thread is soft-deleted.

---

### Changes Required:

#### 1. Cloud Function - Thread Deletion Trigger

**File**: `functions/src/functions/thread-deletion.ts` (NEW FILE)

**Changes**: Create Firestore trigger to detect thread deletion

```typescript
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';

/**
 * Cloud Function triggered when a thread document is updated.
 * Detects when isDeleted changes from false to true and permanently hard-deletes
 * all messages and media files associated with the thread.
 */
export const onThreadDeleted = onDocumentUpdated(
  {
    document: 'journalThreads/{threadId}',
    memory: '512MiB',
    timeoutSeconds: 120,
    region: 'us-central1',
  },
  async (event) => {
    const threadId = event.params.threadId;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Only proceed if isDeleted changed from false to true
    if (beforeData?.isDeleted === false && afterData?.isDeleted === true) {
      logger.info(`Thread ${threadId} was soft-deleted. Starting permanent cascade deletion of messages and media.`);

      const db = getFirestore();
      const bucket = getStorage().bucket();

      try {
        // Step 1: Query all messages for this thread (no isDeleted filter needed for hard delete)
        const messagesSnapshot = await db
          .collection('journalMessages')
          .where('threadId', '==', threadId)
          .get();

        logger.info(`Permanently deleting ${messagesSnapshot.size} messages and associated media for thread ${threadId}`);

        // Step 2: Batch delete messages (Firestore batches limited to 500 operations)
        const batchSize = 500;
        const batches: FirebaseFirestore.WriteBatch[] = [];
        let currentBatch = db.batch();
        let operationCount = 0;

        const storageFilesToDelete: string[] = [];

        for (const messageDoc of messagesSnapshot.docs) {
          const messageData = messageDoc.data();

          // Hard delete message (permanently remove from Firestore)
          currentBatch.delete(messageDoc.ref);

          // Collect storage URLs for deletion
          if (messageData.storageUrl) {
            storageFilesToDelete.push(messageData.storageUrl);
          }
          if (messageData.thumbnailUrl) {
            storageFilesToDelete.push(messageData.thumbnailUrl);
          }

          operationCount++;

          // Create new batch if limit reached
          if (operationCount >= batchSize) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            operationCount = 0;
          }
        }

        // Add final batch if it has operations
        if (operationCount > 0) {
          batches.push(currentBatch);
        }

        // Step 3: Commit all batches
        logger.info(`Committing ${batches.length} batch(es) to permanently delete messages`);
        await Promise.all(batches.map((batch) => batch.commit()));
        logger.info(`✅ Successfully permanently deleted ${messagesSnapshot.size} messages`);

        // Step 4: Delete storage files
        logger.info(`Deleting ${storageFilesToDelete.length} storage file(s)`);
        const deletePromises = storageFilesToDelete.map(async (url) => {
          try {
            // Extract file path from URL
            // URL format: https://storage.googleapis.com/bucket-name/path/to/file
            // or gs://bucket-name/path/to/file
            const filePath = extractFilePathFromUrl(url);
            if (filePath) {
              await bucket.file(filePath).delete();
              logger.info(`Deleted storage file: ${filePath}`);
            }
          } catch (error) {
            logger.error(`Failed to delete storage file ${url}:`, error);
            // Don't fail the entire operation if one file fails
          }
        });

        await Promise.all(deletePromises);
        logger.info(`✅ Storage cleanup completed for thread ${threadId}`);

      } catch (error) {
        logger.error(`Failed to cascade-delete thread ${threadId}:`, error);
        throw error; // Re-throw to trigger Cloud Function retry
      }
    }
  }
);

/**
 * Extracts the file path from a Firebase Storage URL.
 * Handles both https:// and gs:// URL formats.
 */
function extractFilePathFromUrl(url: string): string | null {
  try {
    if (url.startsWith('gs://')) {
      // Format: gs://bucket-name/path/to/file
      const match = url.match(/^gs:\/\/[^/]+\/(.+)$/);
      return match ? match[1] : null;
    } else if (url.includes('storage.googleapis.com')) {
      // Format: https://storage.googleapis.com/bucket-name/path/to/file
      const match = url.match(/storage\.googleapis\.com\/[^/]+\/(.+)$/);
      return match ? match[1] : null;
    } else if (url.includes('firebasestorage.googleapis.com')) {
      // Format: https://firebasestorage.googleapis.com/v0/b/bucket-name/o/encoded-path
      const match = url.match(/\/o\/(.+?)(\?|$)/);
      if (match) {
        return decodeURIComponent(match[1]);
      }
    }
    return null;
  } catch (error) {
    logger.error(`Failed to parse storage URL ${url}:`, error);
    return null;
  }
}
```

---

#### 2. Cloud Function - Export

**File**: `functions/src/index.ts`

**Changes**: Export the new Cloud Function

```typescript
// ... existing imports and exports ...

export { onThreadDeleted } from './functions/thread-deletion';
```

---

#### 3. Firestore Security Rules - Validation

**File**: `firestore.rules`

**Changes**: Prevent new messages in deleted threads

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...

    match /journalMessages/{messageId} {
      // ... existing read rules ...

      // Create: Prevent creating messages in deleted threads
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.role == 0  // user role
        && request.resource.data.keys().hasAll(['id', 'userId', 'threadId', 'createdAtMillis'])
        && !isThreadDeleted(request.resource.data.threadId);  // NEW CHECK

      // ... existing update/delete rules ...
    }

    // ... rest of rules ...
  }
}

// Helper function to check if thread is deleted
function isThreadDeleted(threadId) {
  return exists(/databases/$(database)/documents/journalThreads/$(threadId))
    && get(/databases/$(database)/documents/journalThreads/$(threadId)).data.isDeleted == true;
}
```

---

#### 4. Data Model - Add deletedAtMillis Field

**File**: [lib/features/journal/data/models/journal_thread_model.dart](lib/features/journal/data/models/journal_thread_model.dart)

**Changes**: Add `deletedAtMillis` field to model (optional, for tracking when deletion occurred)

```dart
@collection
class JournalThreadModel {
  JournalThreadModel({
    required this.id,
    required this.userId,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.title,
    this.lastMessageAtMillis,
    this.messageCount = 0,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAtMillis,  // NEW FIELD
    this.version = 1,
  });

  // ... existing fields ...
  final int? deletedAtMillis;  // NEW FIELD

  // Update factory methods to include deletedAtMillis
  factory JournalThreadModel.fromMap(Map<String, dynamic> map) {
    return JournalThreadModel(
      // ... existing fields ...
      deletedAtMillis: map['deletedAtMillis'] as int?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      // ... existing fields ...
      'deletedAtMillis': deletedAtMillis,
    };
  }

  JournalThreadModel copyWith({
    // ... existing parameters ...
    int? deletedAtMillis,
  }) {
    return JournalThreadModel(
      // ... existing fields ...
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
    );
  }
}
```

**Note**: Run `flutter pub run build_runner build --delete-conflicting-outputs` after this change to regenerate Isar schema.

---

#### 5. Data Model - Message Model (No Changes Needed)

**File**: [lib/features/journal/data/models/journal_message_model.dart](lib/features/journal/data/models/journal_message_model.dart)

**Changes**: None required - messages will be hard-deleted, so no `deletedAtMillis` field needed

**Note**: The existing `isDeleted` field in `JournalMessageModel` can remain for backward compatibility, but won't be used in the deletion flow since messages are permanently deleted from Firestore.

---

### Success Criteria:

#### Automated Verification:
- [x] TypeScript compiles without errors: `cd functions && npm run build`
- [x] Cloud Function deploys successfully: `firebase deploy --only functions:onThreadDeleted`
- [x] Firestore rules deploy successfully: `firebase deploy --only firestore:rules`
- [x] Isar schema regenerates: `~/flutter/bin/flutter packages pub run build_runner build --delete-conflicting-outputs`

#### Manual Verification:
- [x] Delete a thread with 10+ messages → all messages completely removed from Firestore within 10 seconds (verify messages no longer exist)
- [x] Delete a thread with audio/image messages → corresponding media files permanently deleted from Cloud Storage within 30 seconds
- [x] Delete a thread with 600+ messages → batch processing works correctly (no errors in Cloud Function logs)
- [x] Attempt to create message in deleted thread → Firestore rules reject with permission error
- [x] Check Cloud Function logs for successful execution: `firebase functions:log --only onThreadDeleted`
- [x] Verify no orphaned messages remain: Query Firestore for messages with deleted thread ID (should return 0 results)

**Implementation Note**: After completing this phase, perform end-to-end testing across multiple devices.

---

## Phase 3: Testing & Edge Cases

### Overview
Add comprehensive tests and handle edge cases.

---

### Changes Required:

#### 1. Unit Tests - DeleteThreadUseCase
  
**File**: `test/features/journal/domain/usecases/delete_thread_usecase_test.dart` (NEW FILE)

**Changes**: Create unit tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/usecases/delete_thread_usecase.dart';

@GenerateMocks([JournalThreadRepository])
import 'delete_thread_usecase_test.mocks.dart';

void main() {
  late DeleteThreadUseCase useCase;
  late MockJournalThreadRepository mockRepository;

  setUp(() {
    mockRepository = MockJournalThreadRepository();
    useCase = DeleteThreadUseCase(threadRepository: mockRepository);
  });

  group('DeleteThreadUseCase', () {
    const testThreadId = 'test-thread-123';

    test('should delete thread successfully when online', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.deleteThread(testThreadId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId))
          .thenAnswer((_) async => const Error(
                NetworkFailure(message: 'You must be online to delete this thread'),
              ));

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
      verify(mockRepository.deleteThread(testThreadId));
    });

    test('should return ServerFailure when remote deletion fails', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId))
          .thenAnswer((_) async => const Error(
                ServerFailure(message: 'Failed to delete thread'),
              ));

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
```

---

#### 2. Integration Tests - Repository

**File**: `test/features/journal/data/repositories/journal_thread_repository_impl_test.dart`

**Changes**: Add tests for `deleteThread` method

```dart
group('deleteThread', () {
  const testThreadId = 'test-thread-123';

  test('should return NetworkFailure when offline', () async {
    // Arrange
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);

    // Act
    final result = await repository.deleteThread(testThreadId);

    // Assert
    expect(result.isError, true);
    expect(result.failureOrNull, isA<NetworkFailure>());
    verifyNever(mockRemoteDataSource.softDeleteThread(any));
    verifyNever(mockLocalDataSource.hardDeleteThreadAndMessages(any));
  });

  test('should soft-delete remotely then hard-delete locally when online', () async {
    // Arrange
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockRemoteDataSource.softDeleteThread(testThreadId))
        .thenAnswer((_) async => Future.value());
    when(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId))
        .thenAnswer((_) async => Future.value());

    // Act
    final result = await repository.deleteThread(testThreadId);

    // Assert
    expect(result.isSuccess, true);
    verify(mockRemoteDataSource.softDeleteThread(testThreadId));
    verify(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId));
  });

  test('should return ServerFailure when remote deletion fails', () async {
    // Arrange
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockRemoteDataSource.softDeleteThread(testThreadId))
        .thenThrow(Exception('Network error'));

    // Act
    final result = await repository.deleteThread(testThreadId);

    // Assert
    expect(result.isError, true);
    expect(result.failureOrNull, isA<ServerFailure>());
    verifyNever(mockLocalDataSource.hardDeleteThreadAndMessages(any));
  });

  test('should succeed even if local deletion fails after remote success', () async {
    // Arrange
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockRemoteDataSource.softDeleteThread(testThreadId))
        .thenAnswer((_) async => Future.value());
    when(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId))
        .thenThrow(Exception('Isar error'));

    // Act
    final result = await repository.deleteThread(testThreadId);

    // Assert
    expect(result.isSuccess, true); // Should still succeed
    verify(mockRemoteDataSource.softDeleteThread(testThreadId));
    verify(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId));
  });
});
```

---

#### 3. Cloud Function Tests

**File**: `functions/src/test/thread-deletion.test.ts` (NEW FILE)

**Changes**: Add tests for Cloud Function

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'mocha';
import * as admin from 'firebase-admin';
import { WrappedFunction } from 'firebase-functions-test/lib/v2';
import * as functionsTest from 'firebase-functions-test';

const test = functionsTest();

describe('onThreadDeleted', () => {
  let adminInitStub: any;

  beforeEach(() => {
    // Initialize Firebase Admin
    if (!admin.apps.length) {
      adminInitStub = admin.initializeApp();
    }
  });

  afterEach(() => {
    test.cleanup();
  });

  it('should permanently delete messages when thread is soft-deleted', async () => {
    // TODO: Implement test with Firestore emulator
    // 1. Create test thread and messages in Firestore emulator
    // 2. Update thread with isDeleted=true
    // 3. Trigger Cloud Function
    // 4. Assert all messages are permanently deleted (no longer exist in Firestore)
  });

  it('should handle batches larger than 500 messages', async () => {
    // TODO: Test with 600+ messages to verify batch pagination
  });

  it('should delete storage files referenced by messages', async () => {
    // TODO: Test storage file deletion
  });
});
```

**Note**: Full Cloud Function testing requires Firestore emulator setup. For MVP, manual testing may be sufficient.

---

#### 4. Edge Case - Prevent Upload to Deleted Thread

**File**: [lib/features/journal/data/repositories/journal_message_repository_impl.dart](lib/features/journal/data/repositories/journal_message_repository_impl.dart)

**Changes**: Add validation before message creation

```dart
@override
Future<Result<JournalMessageEntity>> createMessage(
    JournalMessageEntity message) async {
  try {
    // Check if thread is deleted before creating message
    final threadResult = await threadRepository.getThreadById(message.threadId);
    if (threadResult.isSuccess) {
      final thread = threadResult.dataOrNull;
      if (thread == null) {
        return const Error(
          ValidationFailure(message: 'Thread not found'),
        );
      }
      // Note: Thread entity doesn't expose isDeleted, so we can't check locally
      // The Firestore security rules will enforce this on the server side
    }

    // ... rest of existing implementation ...
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to save message locally: $e'));
  }
}
```

**Note**: Since the domain entity doesn't expose `isDeleted`, server-side validation via Firestore rules is the primary guard. This is acceptable for MVP.

---

### Success Criteria:

#### Automated Verification:
- [x] All unit tests pass: `~/flutter/bin/flutter test`
- [x] Test coverage for delete flow > 80%: `~/flutter/bin/flutter test --coverage`
- [x] No regressions in existing tests: `~/flutter/bin/flutter test`

#### Manual Verification:
- [x] Concurrent scenario: Delete thread while upload in progress → upload fails gracefully
- [x] Multi-device: Delete thread on Device A → thread disappears on Device B within 5 seconds
- [x] Large thread: Delete thread with 100+ messages → all deleted successfully
- [x] Storage cleanup: Verify audio/image files deleted from Cloud Storage
- [x] Error handling: Network failure during deletion shows appropriate error message

**Implementation Note**: This phase completes the MVP implementation. Perform thorough manual testing before release.

---

## Performance Considerations

### Firestore Batch Limits:
- Firestore batches limited to **500 operations**
- Cloud Function handles pagination automatically for hard-delete operations
- For threads with 1000+ messages, expect ~2 batches, processing time ~3-5 seconds

### Storage Deletion:
- Storage file deletion is asynchronous and non-blocking
- Failed storage deletions don't fail the overall operation
- Orphaned files can be cleaned up by a scheduled maintenance function (out of scope for MVP)

### Local Storage:
- Hard-deleting locally frees up Isar database space immediately
- For threads with 100+ messages, local deletion takes <100ms

### Network Impact:
- Deletion requires single Firestore document update (thread)
- Cloud Function runs server-side, no client network impact for message cascade
- Total network payload: ~1KB for thread update

---

## Migration Notes

No data migration required - `isDeleted` and `deletedAtMillis` fields already exist in models and will default to `false` and `null` for existing documents.

---

## Security Considerations

### Firestore Rules:
- Only thread owner can set `isDeleted=true` on threads (enforced by existing rules: `userId == request.auth.uid`)
- New messages cannot be created in deleted threads (new rule added in Phase 2)
- Message hard-deletion cascade handled server-side via Cloud Function, not exposed to client

### Cloud Function Security:
- Function only triggered by Firestore document updates (no public HTTP endpoint)
- Function checks `isDeleted` state transition to prevent accidental triggers
- Storage file deletion uses Admin SDK with full privileges (secure by design)

### Client Security:
- Repository checks connectivity before attempting deletion (fail-fast)
- Remote deletion checked for success before local deletion
- No sensitive data exposed in error messages

---

## Rollback Plan

If deletion feature causes issues in production:

1. **Disable deletion UI**: Comment out delete button in `thread_list_screen.dart`
2. **Disable Cloud Function**: `firebase deploy --only functions` (exclude `onThreadDeleted`)
3. **Restore deleted threads**: Update Firestore documents: `isDeleted=false` (manual recovery for threads only)

**Important**: Thread soft-deletion allows recovery, but **messages and media files are permanently deleted and cannot be recovered** once the Cloud Function cascade completes. This is by design for the MVP to minimize storage costs and sync complexity.

---

## Future Enhancements (Out of Scope for MVP)

- [ ] **Undo deletion** - 5-second window to cancel deletion
- [ ] **Batch deletion** - Delete multiple threads at once
- [ ] **Permanent deletion** - Scheduled job to hard-delete threads older than 30 days
- [ ] **Archive before delete** - Require archiving before deletion
- [ ] **Deletion analytics** - Track deletion metrics
- [ ] **Offline deletion queue** - Queue deletions when offline, process when back online
- [ ] **Trash/Recycle bin** - UI to view and restore deleted threads
- [ ] **Storage optimization** - Compress images before storage to reduce deletion overhead

---

## Architecture Summary

### Deletion Strategy by Component:

| Component | Deletion Type | Location | Recovery |
|-----------|---------------|----------|----------|
| **Thread** | Soft-delete (`isDeleted=true`) | Firestore | Recoverable (manual update to `isDeleted=false`) |
| **Messages** | Hard-delete (permanent removal) | Firestore | **Not recoverable** |
| **Media Files** | Hard-delete (permanent removal) | Cloud Storage | **Not recoverable** |
| **Local Data** | Hard-delete (immediate removal) | Isar | Not recoverable (but re-syncs from remote if available) |

### Flow Summary:
1. User deletes thread → Thread soft-deleted in Firestore
2. Cloud Function triggered → Messages hard-deleted from Firestore
3. Cloud Function → Media files hard-deleted from Cloud Storage
4. Local storage → Thread and messages hard-deleted from Isar
5. Result: **Thread recoverable for 30 days, messages and media gone permanently**

This hybrid approach balances:
- ✅ **User mistake recovery**: Can restore thread metadata if deleted accidentally
- ✅ **Storage efficiency**: Messages and media permanently removed to save costs
- ✅ **Sync simplicity**: No complex queue or retry logic for deletions
- ✅ **Multi-device consistency**: Firestore listeners propagate deletions automatically

---

## References

- Thread Entity: [lib/features/journal/domain/entities/journal_thread_entity.dart](lib/features/journal/domain/entities/journal_thread_entity.dart)
- Message Entity: [lib/features/journal/domain/entities/journal_message_entity.dart](lib/features/journal/domain/entities/journal_message_entity.dart)
- Thread Repository: [lib/features/journal/domain/repositories/journal_thread_repository.dart](lib/features/journal/domain/repositories/journal_thread_repository.dart)
- Thread Repository Impl: [lib/features/journal/data/repositories/journal_thread_repository_impl.dart](lib/features/journal/data/repositories/journal_thread_repository_impl.dart)
- Cloud Functions: [functions/src/index.ts](functions/src/index.ts)
- Firestore Rules: [firestore.rules](firestore.rules)
- Existing Cloud Function Patterns: [functions/src/functions/message-triggers.ts](functions/src/functions/message-triggers.ts)
