# Repository Simplification - Remove Connectivity Dependencies Implementation Plan

## Overview

Refactor `JournalMessageRepositoryImpl`, `JournalThreadRepositoryImpl`, and `InsightRepositoryImpl` to act as pure orchestration layers between local and remote data sources, without directly managing connectivity or complex synchronization logic. Remove all dependencies on `connectivity_plus` and eliminate `_isOnline` methods entirely. Repositories will no longer decide whether the device is online or offline — instead, they will always attempt remote operations and let the remote data sources handle exceptions like `SocketException`, `FirebaseException`, or other network-related errors. Repositories will catch these exceptions and translate them into domain-level failures (`NetworkFailure`, `ServerFailure`, etc.) via the existing `Result` wrapper.

## Current State Analysis

### Problems Identified:

1. **Repository Layer is Too Complex**:
   - [journal_message_repository_impl.dart:2](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L2) - Imports `connectivity_plus`
   - [journal_message_repository_impl.dart:25-28](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L25-L28) - `_isOnline` getter checks connectivity
   - [journal_message_repository_impl.dart:39,102,163,187](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L39) - Multiple inline connectivity checks
   - Same pattern in [journal_thread_repository_impl.dart:1,23-26](lib/features/journal/data/repositories/journal_thread_repository_impl.dart#L1) and [insight_repository_impl.dart:2,24-27](lib/features/insights/data/repositories/insight_repository_impl.dart#L2)

2. **Remote DataSources Have No Error Handling**:
   - [journal_message_remote_datasource.dart:26-28](lib/features/journal/data/datasources/journal_message_remote_datasource.dart#L26-L28) - Direct Firestore calls without try-catch
   - [journal_thread_remote_datasource.dart:23-25](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart#L23-L25) - No exception wrapping
   - All Firestore exceptions bubble up unhandled

3. **Inconsistent Error Mapping**:
   - [journal_message_repository_impl.dart:175-180](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L175-L180) - String pattern matching for "network" errors
   - No proper mapping of `FirebaseException` types to domain failures
   - Generic catch-all error handling loses type information

### Correct Pattern (from FirebaseAuthRepository):

The [firebase_auth_repository.dart:61-166](lib/features/auth/data/repositories/firebase_auth_repository.dart#L61-L166) shows the ideal pattern:
```dart
@override
Future<Result<UserEntity>> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // ... process result
    return Success(user);
  } on firebase_auth.FirebaseAuthException catch (e) {
    return Error(_mapFirebaseException(e));
  } catch (e) {
    return Error(AuthFailure.unknown('Sign in failed: $e'));
  }
}

AuthFailure _mapFirebaseException(firebase_auth.FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return AuthFailure.network();
    // ... other mappings
    default:
      return AuthFailure.unknown(e.message ?? 'Authentication failed');
  }
}
```

**Key aspects**:
- Specific exception catching (`FirebaseAuthException`)
- Dedicated exception mapper method
- Maps to domain-specific failures
- Generic fallback for unknown errors

## Desired End State

After this refactoring:

1. **Remote DataSources**:
   - All Firestore calls wrapped in try-catch blocks
   - Catch `FirebaseException`, `SocketException`, and generic exceptions
   - Throw typed exceptions: `NetworkException`, `ServerException`
   - Example:
     ```dart
     @override
     Future<void> saveMessage(JournalMessageModel message) async {
       try {
         await _collection.doc(message.id).set(message.toFirestoreMap());
       } on SocketException {
         throw NetworkException(message: 'No internet connection');
       } on FirebaseException catch (e) {
         throw ServerException(message: e.message ?? 'Firestore error', statusCode: null);
       } catch (e) {
         throw ServerException(message: 'Failed to save message: $e', statusCode: null);
       }
     }
     ```

2. **Repositories**:
   - No `connectivity_plus` import
   - No `_isOnline` method
   - No connectivity parameter in constructor
   - Always attempt remote operations
   - Catch typed exceptions and map to domain failures
   - Example:
     ```dart
     @override
     Future<Result<JournalMessageEntity>> createMessage(
         JournalMessageEntity message) async {
       try {
         final model = JournalMessageModel.fromEntity(message);
         await localDataSource.saveMessage(model);

         // Always attempt remote save
         try {
           await remoteDataSource.saveMessage(model);
           // Update local with success status
         } on NetworkException catch (e) {
           // Mark as failed locally for retry
           return Error(NetworkFailure(message: e.message));
         } on ServerException catch (e) {
           return Error(ServerFailure(message: e.message));
         }

         return Success(model.toEntity());
       } catch (e) {
         return Error(CacheFailure(message: 'Failed to save message locally: $e'));
       }
     }
     ```

3. **Providers**:
   - No `connectivity` parameter passed to repositories
   - Simplified dependency injection

### Verification Criteria:

#### Automated Verification:
- [ ] All existing tests pass: `~/flutter/bin/flutter test`
- [ ] Code analysis passes: `~/flutter/bin/flutter analyze`
- [ ] No references to `connectivity` in repository implementations: `grep -r "_isOnline\|connectivity" lib/features/*/data/repositories/`

#### Manual Verification:
- [ ] Offline message creation shows proper "failed" status
- [ ] Online message creation syncs correctly
- [ ] Airplane mode toggle during operations handles gracefully
- [ ] Error messages are user-friendly (no raw exception strings)
- [ ] Upload retry mechanism still works for failed media uploads

## What We're NOT Doing

- **NOT** changing local datasource implementations
- **NOT** modifying entity or model classes
- **NOT** changing the `Result` wrapper or `Failure` types
- **NOT** removing `connectivity_plus` from the entire project (still used by `NetworkInfo` at [network_info.dart:1](lib/core/network/network_info.dart#L1))
- **NOT** changing use cases or controllers
- **NOT** making remote datasources return `Result<T>` (they throw exceptions)
- **NOT** moving upload status business logic out of repositories

## Implementation Approach

Follow the established pattern from `FirebaseAuthRepository`:
1. Remote datasources throw typed exceptions
2. Repositories catch typed exceptions and map to domain failures
3. Keep business logic (upload status management) in repositories
4. Maintain offline-first behavior with local cache
5. Stream errors handled via `onError` callbacks

---

## Phase 1: Enhance Exception Handling Infrastructure

### Overview
Ensure we have all necessary exception types and add a Firestore exception mapper utility.

### Changes Required:

#### 1. Core Exceptions
**File**: `lib/core/errors/exceptions.dart`

**Current State**: Already has `NetworkException`, `ServerException`, `CacheException`, `ValidationException` at [exceptions.dart:1-40](lib/core/errors/exceptions.dart#L1-L40)

**Changes**: Add import for `dart:io` to use `SocketException` type in datasources

```dart
// Add at top of file
import 'dart:io'; // For SocketException type checking
```

**Note**: No changes to exception classes themselves - they're already correct.

#### 2. Firestore Exception Mapper Utility
**File**: `lib/core/errors/firestore_exception_mapper.dart` (NEW FILE)

**Purpose**: Centralized mapping of Firestore exceptions to domain exceptions, following the pattern from `FirebaseAuthRepository`

**Changes**: Create new file

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/exceptions.dart';

/// Maps Firestore exceptions to domain exceptions
///
/// Throws either [NetworkException] or [ServerException] based on the error type.
/// This follows the same pattern as FirebaseAuthRepository's exception mapping.
Never mapFirestoreException(Object error, {String? context}) {
  final contextPrefix = context != null ? '$context: ' : '';

  if (error is SocketException) {
    throw NetworkException(
      message: '${contextPrefix}No internet connection. Please check your network.',
    );
  }

  if (error is FirebaseException) {
    // Map specific Firestore error codes
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        throw NetworkException(
          message: '${contextPrefix}Network timeout. Please try again.',
        );

      case 'permission-denied':
        throw ServerException(
          message: '${contextPrefix}Permission denied: ${error.message}',
          statusCode: 403,
        );

      case 'not-found':
        throw ServerException(
          message: '${contextPrefix}Resource not found: ${error.message}',
          statusCode: 404,
        );

      case 'already-exists':
        throw ServerException(
          message: '${contextPrefix}Resource already exists: ${error.message}',
          statusCode: 409,
        );

      case 'resource-exhausted':
        throw ServerException(
          message: '${contextPrefix}Quota exceeded: ${error.message}',
          statusCode: 429,
        );

      case 'failed-precondition':
      case 'aborted':
      case 'out-of-range':
      case 'unimplemented':
      case 'internal':
      case 'data-loss':
        throw ServerException(
          message: '${contextPrefix}Server error: ${error.message}',
          statusCode: 500,
        );

      default:
        throw ServerException(
          message: '${contextPrefix}Firestore error: ${error.message ?? 'Unknown error'}',
          statusCode: null,
        );
    }
  }

  // Generic fallback for unknown errors
  throw ServerException(
    message: '${contextPrefix}Unexpected error: $error',
    statusCode: null,
  );
}
```

### Success Criteria:

#### Automated Verification:
- [x] New file compiles without errors: `~/flutter/bin/flutter analyze`
- [x] No import errors in exceptions.dart: `~/flutter/bin/dart analyze lib/core/errors/exceptions.dart`

#### Manual Verification:
- [x] File structure is correct in `lib/core/errors/`
- [x] Exception mapper utility is ready for use in datasources

**Implementation Note**: This is a pure additive phase with no behavior changes. Proceed to Phase 2 immediately after verification.

---

## Phase 2: Add Error Handling to JournalMessageRemoteDataSource

### Overview
Wrap all Firestore operations in `JournalMessageRemoteDataSourceImpl` with try-catch blocks that map exceptions using the new utility.

### Changes Required:

#### 1. JournalMessageRemoteDataSource Implementation
**File**: `lib/features/journal/data/datasources/journal_message_remote_datasource.dart`

**Changes**: Add imports and wrap all methods

```dart
import 'dart:io'; // Add for SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart'; // Add
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

// ... existing abstract class unchanged ...

class JournalMessageRemoteDataSourceImpl
    implements JournalMessageRemoteDataSource {
  JournalMessageRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalMessages');

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    try {
      await _collection.doc(message.id).set(message.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save message');
    }
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    try {
      final doc = await _collection.doc(messageId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return JournalMessageModel.fromMap(data);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get message by ID');
    }
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(
    String threadId,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAtMillis', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JournalMessageModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get messages by thread');
    }
  }

  @override
  Future<List<JournalMessageModel>> getUpdatedMessages(
    String threadId,
    int lastUpdatedAtMillis,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .where('updatedAtMillis', isGreaterThan: lastUpdatedAtMillis)
          .orderBy('updatedAtMillis', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JournalMessageModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get updated messages');
    }
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    try {
      await _collection.doc(message.id).update(message.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to update message');
    }
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(
    String threadId,
    String userId,
  ) {
    // Streams handle errors via onError callback in repository
    // Don't wrap in try-catch here - let errors propagate to stream
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return JournalMessageModel.fromMap(data);
          }).toList(),
        );
  }

  @override
  Stream<List<JournalMessageModel>> watchUpdatedMessages(
    String threadId,
    int sinceUpdatedAtMillis,
  ) {
    // Streams handle errors via onError callback in repository
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .where('updatedAtMillis', isGreaterThan: sinceUpdatedAtMillis)
        .orderBy('updatedAtMillis', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return JournalMessageModel.fromMap(data);
          }).toList(),
        );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/journal/data/datasources/journal_message_remote_datasource.dart`
- [x] Import statement is correct: check for `firestore_exception_mapper.dart` import
- [x] All non-stream methods have try-catch blocks

#### Manual Verification:
- [x] Each Future method has exactly one try-catch wrapping the Firestore call
- [x] Stream methods do NOT have try-catch (errors handled in repository onError)
- [x] Context messages are descriptive and unique per method
- [x] No behavioral changes yet (repositories still have connectivity checks)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: Add Error Handling to JournalThreadRemoteDataSource

### Overview
Apply the same error handling pattern to `JournalThreadRemoteDataSourceImpl`.

### Changes Required:

#### 1. JournalThreadRemoteDataSource Implementation
**File**: `lib/features/journal/data/datasources/journal_thread_remote_datasource.dart`

**Changes**: Add imports and wrap all methods

```dart
import 'dart:io'; // Add for SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart'; // Add
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

// ... existing abstract class unchanged ...

class JournalThreadRemoteDataSourceImpl
    implements JournalThreadRemoteDataSource {
  JournalThreadRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalThreads');

  @override
  Future<void> saveThread(JournalThreadModel thread) async {
    try {
      await _collection.doc(thread.id).set(thread.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save thread');
    }
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    try {
      final doc = await _collection.doc(threadId).get();
      if (!doc.exists) return null;
      return JournalThreadModel.fromMap(doc.data()!);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get thread by ID');
    }
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('lastMessageAtMillis', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JournalThreadModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get threads by user');
    }
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    try {
      await _collection.doc(thread.id).update(thread.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to update thread');
    }
  }

  @override
  Future<void> softDeleteThread(String threadId) async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _collection.doc(threadId).update({
        'isDeleted': true,
        'deletedAtMillis': now,
        'updatedAtMillis': now,
      });
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to delete thread');
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/journal/data/datasources/journal_thread_remote_datasource.dart`
- [ ] Import statement is correct: check for `firestore_exception_mapper.dart` import
- [ ] All methods have try-catch blocks

#### Manual Verification:
- [ ] Each method has exactly one try-catch wrapping the Firestore call
- [ ] Context messages are descriptive and unique per method
- [ ] Pattern matches JournalMessageRemoteDataSource implementation

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: Add Error Handling to InsightRemoteDataSource

### Overview
Apply the same error handling pattern to `InsightRemoteDataSourceImpl`.

### Changes Required:

#### 1. Find InsightRemoteDataSource
**Files to locate**:
- `lib/features/insights/data/datasources/insight_remote_datasource.dart`

**Changes**: Add imports and wrap all methods (same pattern as previous phases)

```dart
import 'dart:io'; // Add for SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart'; // Add
// ... existing imports ...

// Wrap all Future methods with:
// try {
//   // existing Firestore call
// } catch (e) {
//   mapFirestoreException(e, context: 'Descriptive context');
// }

// Leave Stream methods unwrapped (errors handled in repository)
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/insights/`
- [ ] Import statement is correct
- [ ] All Future methods have try-catch blocks
- [ ] Stream methods remain unwrapped

#### Manual Verification:
- [ ] Pattern consistent with JournalMessageRemoteDataSource and JournalThreadRemoteDataSource
- [ ] Context messages are descriptive

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Refactor JournalMessageRepositoryImpl

### Overview
Remove connectivity dependency and simplify to pure orchestration layer. This is the most complex phase as it touches core message creation and sync logic.

### Changes Required:

#### 1. JournalMessageRepositoryImpl - Remove Connectivity and Simplify
**File**: `lib/features/journal/data/repositories/journal_message_repository_impl.dart`

**Changes**:

**Step 5.1**: Remove connectivity import and dependency

```dart
import 'dart:async';
// REMOVE: import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/exceptions.dart'; // ADD for catching typed exceptions
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
// ... rest of imports unchanged ...

class JournalMessageRepositoryImpl implements JournalMessageRepository {
  JournalMessageRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    // REMOVE: required this.connectivity,
  });

  final JournalMessageLocalDataSource localDataSource;
  final JournalMessageRemoteDataSource remoteDataSource;
  // REMOVE: final Connectivity connectivity;

  // REMOVE entire _isOnline getter (lines 25-28)
```

**Step 5.2**: Refactor `createMessage()` method (lines 31-86)

**Current logic** (lines 31-86):
- Save locally
- Check if online
- If online: try remote save, mark success/failure locally
- If offline: mark as failed (media) or pending (text)

**New logic**:
- Save locally
- Always attempt remote save
- Catch exceptions and mark status accordingly

```dart
@override
Future<Result<JournalMessageEntity>> createMessage(
    JournalMessageEntity message,) async {
  try {
    final model = JournalMessageModel.fromEntity(message);
    await localDataSource.saveMessage(model);

    // Always attempt remote save - no connectivity pre-check
    try {
      await remoteDataSource.saveMessage(model);

      // Mark text messages and non-user messages as completed
      if (message.messageType == MessageType.text ||
          message.role != MessageRole.user) {
        final synced = model.copyWith(uploadStatus: UploadStatus.completed.index);
        await localDataSource.updateMessage(synced);
      }

      return Success(model.toEntity());
    } on NetworkException catch (e) {
      Logger().e('Network error during message creation', error: e.message);

      // Handle network failure based on message type
      if (message.role == MessageRole.user) {
        if (message.messageType != MessageType.text) {
          // Media messages: mark as failed (shows Retry button)
          final failed = model.copyWith(
            uploadStatus: UploadStatus.failed.index,
            uploadRetryCount: model.uploadRetryCount + 1,
            lastUploadAttemptMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
          );
          await localDataSource.updateMessage(failed);
          return Error(NetworkFailure(message: e.message));
        } else {
          // Text messages: mark as notStarted (shows "Waiting to upload")
          final pending = model.copyWith(
            uploadStatus: UploadStatus.notStarted.index,
          );
          await localDataSource.updateMessage(pending);
          return Success(pending.toEntity());
        }
      }

      // Non-user messages (AI responses): return error
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      Logger().e('Server error during message creation', error: e.message);

      // Mark message as failed for retry
      final failed = model.copyWith(
        uploadStatus: UploadStatus.failed.index,
        uploadRetryCount: model.uploadRetryCount + 1,
        lastUploadAttemptMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await localDataSource.updateMessage(failed);
      return Error(ServerFailure(message: e.message));
    }
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to save message locally: $e'));
  }
}
```

**Step 5.3**: Refactor `watchMessagesByThreadId()` method (lines 99-130)

**Current logic**:
- Check if online
- If online: setup remote subscription
- Always yield local stream

**New logic**:
- Always attempt remote subscription
- Handle errors in onError callback
- Always yield local stream

```dart
@override
Stream<List<JournalMessageEntity>> watchMessagesByThreadId(
    String threadId,) async* {
  StreamSubscription<List<JournalMessageModel>>? remoteSub;

  try {
    // Always attempt remote sync - no connectivity pre-check
    final since = (await localDataSource.getLastUpdatedAtMillis(threadId)) ?? 0;

    // Listen for remote updates and upsert into local
    remoteSub = remoteDataSource
        .watchUpdatedMessages(threadId, since)
        .listen(
      (remoteModels) async {
        for (final remoteModel in remoteModels) {
          await localDataSource.upsertFromRemote(remoteModel);
        }
      },
      onError: (Object error) {
        // Network errors are transient - just log and continue
        // The local stream continues to work offline
        debugPrint('Remote sync error (will retry when online): $error');
      },
    );

    // Always yield the local stream, updated by remote listener when online
    yield* localDataSource
        .watchMessagesByThreadId(threadId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  } finally {
    await remoteSub?.cancel();
  }
}
```

**Step 5.4**: Refactor `updateMessage()` method (lines 133-158)

**Current logic**: Already doesn't check connectivity (lines 140-152), just catches exceptions

**Changes**: Update exception handling to use typed exceptions

```dart
@override
Future<Result<void>> updateMessage(JournalMessageEntity message) async {
  try {
    debugPrint('updateMessage called for: ${message.id}');
    final model = JournalMessageModel.fromEntity(message);
    await localDataSource.updateMessage(model);
    debugPrint('Local update completed for: ${message.id}');

    // Always attempt remote update
    try {
      debugPrint('Attempting remote update for: ${message.id}');
      await remoteDataSource.updateMessage(model);
      debugPrint(
          '✅ Synced message update to Firestore: ${model.id} - storageUrl: ${model.storageUrl}',);
    } on NetworkException catch (e) {
      debugPrint('⚠️ Network error updating message (will retry later): ${e.message}');
      // Don't fail the whole operation - local update succeeded
    } on ServerException catch (e) {
      debugPrint('⚠️ Server error updating message (will retry later): ${e.message}');
      // Don't fail the whole operation - local update succeeded
    }

    return const Success(null);
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to update message: $e'));
  }
}
```

**Step 5.5**: Refactor `syncMessages()` method (lines 161-182)

**Current logic**:
- Check if online first
- Return NetworkFailure if offline
- Try remote fetch
- String pattern matching for "network" errors

**New logic**:
- Always attempt remote fetch
- Catch typed exceptions
- Map to domain failures

```dart
@override
Future<Result<void>> syncMessages(String threadId) async {
  try {
    final remoteMessages = await remoteDataSource.getMessagesByThreadId(threadId);

    for (final message in remoteMessages) {
      await localDataSource.saveMessage(message);
    }

    return const Success(null);
  } on NetworkException catch (e) {
    return Error(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    return Error(ServerFailure(message: e.message));
  } catch (e) {
    return Error(ServerFailure(message: 'Failed to sync messages: $e'));
  }
}
```

**Step 5.6**: Refactor `syncThreadIncremental()` method (lines 185-261)

**Current logic**:
- Check if online first
- Return NetworkFailure if offline
- Fetch updated messages
- Complex merging logic
- String pattern matching for errors

**New logic**:
- Always attempt remote fetch
- Keep merging logic (it's business orchestration)
- Catch typed exceptions

```dart
@override
Future<Result<void>> syncThreadIncremental(String threadId) async {
  try {
    // Get the latest updatedAtMillis from local DB
    final lastUpdatedAtMillis =
        await localDataSource.getLastUpdatedAtMillis(threadId);

    // If no messages exist locally, use 0 to fetch all messages
    final sinceTimestamp = lastUpdatedAtMillis ?? 0;

    debugPrint(
        '🔄 Incremental sync for thread $threadId since timestamp: $sinceTimestamp',);

    // Always attempt to fetch updated messages
    final updatedMessages = await remoteDataSource.getUpdatedMessages(
      threadId,
      sinceTimestamp,
    );

    debugPrint('📥 Fetched ${updatedMessages.length} updated messages');

    if (updatedMessages.isEmpty) {
      debugPrint('✅ No new messages to sync');
      return const Success(null);
    }

    // Merge updated messages into local DB
    for (final message in updatedMessages) {
      final existingMessage = await localDataSource.getMessageById(message.id);

      if (existingMessage != null) {
        // Message exists locally - merge remote updates with local-only fields
        final isNonUser = message.role != MessageRole.user.index;
        final isText = message.messageType == MessageType.text.index;

        final int uploadStatusToUse;
        if (isNonUser || isText) {
          uploadStatusToUse = UploadStatus.completed.index;
        } else if (message.uploadStatus > existingMessage.uploadStatus) {
          uploadStatusToUse = message.uploadStatus;
        } else {
          uploadStatusToUse = existingMessage.uploadStatus;
        }

        final mergedModel = message.copyWith(
          uploadStatus: uploadStatusToUse,
          uploadRetryCount: existingMessage.uploadRetryCount,
          localFilePath: existingMessage.localFilePath,
          localThumbnailPath: existingMessage.localThumbnailPath,
          audioDurationSeconds: existingMessage.audioDurationSeconds,
        );

        await localDataSource.updateMessage(mergedModel);
        debugPrint('📝 Updated message: ${message.id}');
      } else {
        // New message from remote (e.g., AI response)
        final normalized = message.copyWith(
          uploadStatus: UploadStatus.completed.index,
        );
        await localDataSource.saveMessage(normalized);
        debugPrint('✨ Added new message: ${message.id}');
      }
    }

    debugPrint('✅ Incremental sync completed successfully');
    return const Success(null);
  } on NetworkException catch (e) {
    debugPrint('❌ Network error during incremental sync: ${e.message}');
    return Error(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    debugPrint('❌ Server error during incremental sync: ${e.message}');
    return Error(ServerFailure(message: e.message));
  } catch (e) {
    debugPrint('❌ Incremental sync failed: $e');
    return Error(ServerFailure(message: 'Failed to sync messages: $e'));
  }
}
```

**Step 5.7**: Leave `getMessageById()` and `getPendingUploads()` unchanged
- These methods only use local datasource
- No remote operations
- Already correct (lines 89-96, 264-273)

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/journal/data/repositories/journal_message_repository_impl.dart`
- [ ] No references to `connectivity`: `grep -n "connectivity\|_isOnline" lib/features/journal/data/repositories/journal_message_repository_impl.dart` returns empty
- [ ] Import for exceptions added: check for `import 'package:kairos/core/errors/exceptions.dart';`
- [ ] Constructor has only 2 parameters: `localDataSource`, `remoteDataSource`

#### Manual Verification:
- [ ] All remote operations now catch `NetworkException` and `ServerException`
- [ ] Upload status logic preserved (text vs media, user vs non-user)
- [ ] Stream error handling uses `onError` callback
- [ ] Debug prints are descriptive and helpful
- [ ] No pre-checks for connectivity before remote calls
- [ ] Local operations always succeed even if remote fails

**Implementation Note**: This is a critical phase. After completing all changes and automated verification passes, pause here for thorough manual testing (create messages online/offline, test sync, verify upload status) before proceeding to Phase 6.

---

## Phase 6: Refactor JournalThreadRepositoryImpl

### Overview
Apply the same simplification pattern to `JournalThreadRepositoryImpl`.

### Changes Required:

#### 1. JournalThreadRepositoryImpl - Remove Connectivity and Simplify
**File**: `lib/features/journal/data/repositories/journal_thread_repository_impl.dart`

**Changes**:

**Step 6.1**: Remove connectivity import and dependency

```dart
// REMOVE: import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/exceptions.dart'; // ADD
import 'package:kairos/core/errors/failures.dart';
// ... rest unchanged ...

class JournalThreadRepositoryImpl implements JournalThreadRepository {
  JournalThreadRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    // REMOVE: required this.connectivity,
  });

  final JournalThreadLocalDataSource localDataSource;
  final JournalThreadRemoteDataSource remoteDataSource;
  // REMOVE: final Connectivity connectivity;

  // REMOVE entire _isOnline getter (lines 23-26)
```

**Step 6.2**: Refactor `createThread()` method (lines 29-47)

```dart
@override
Future<Result<JournalThreadEntity>> createThread(
    JournalThreadEntity thread) async {
  try {
    final model = JournalThreadModel.fromEntity(thread);
    await localDataSource.saveThread(model);

    // Always attempt remote save
    try {
      await remoteDataSource.saveThread(model);
    } on NetworkException catch (e) {
      debugPrint('Network error saving thread (will sync later): ${e.message}');
      // Don't fail - local save succeeded
    } on ServerException catch (e) {
      debugPrint('Server error saving thread (will sync later): ${e.message}');
      // Don't fail - local save succeeded
    }

    return Success(model.toEntity());
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to save thread locally: $e'));
  }
}
```

**Step 6.3**: Leave `getThreadById()` unchanged (lines 50-57)
- Only uses local datasource
- Already correct

**Step 6.4**: Leave `watchThreadsByUserId()` unchanged (lines 60-64)
- Only uses local datasource
- Already correct

**Step 6.5**: Refactor `updateThread()` method (lines 67-84)

```dart
@override
Future<Result<void>> updateThread(JournalThreadEntity thread) async {
  try {
    final model = JournalThreadModel.fromEntity(thread);
    await localDataSource.updateThread(model);

    // Always attempt remote update
    try {
      await remoteDataSource.updateThread(model);
    } on NetworkException catch (e) {
      debugPrint('Network error updating thread (will sync later): ${e.message}');
      // Don't fail - local update succeeded
    } on ServerException catch (e) {
      debugPrint('Server error updating thread (will sync later): ${e.message}');
      // Don't fail - local update succeeded
    }

    return const Success(null);
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to update thread: $e'));
  }
}
```

**Step 6.6**: Refactor `archiveThread()` method (lines 87-106)

```dart
@override
Future<Result<void>> archiveThread(String threadId) async {
  try {
    await localDataSource.archiveThread(threadId);

    // Always attempt remote sync
    try {
      final thread = await localDataSource.getThreadById(threadId);
      if (thread != null) {
        await remoteDataSource.updateThread(thread);
      }
    } on NetworkException catch (e) {
      debugPrint('Network error archiving thread remotely (will sync later): ${e.message}');
      // Don't fail - local archive succeeded
    } on ServerException catch (e) {
      debugPrint('Server error archiving thread remotely (will sync later): ${e.message}');
      // Don't fail - local archive succeeded
    }

    return const Success(null);
  } catch (e) {
    return Error(CacheFailure(message: 'Failed to archive thread: $e'));
  }
}
```

**Step 6.7**: Refactor `syncThreads()` method (lines 109-129)

```dart
@override
Future<Result<void>> syncThreads(String userId) async {
  try {
    final remoteThreads = await remoteDataSource.getThreadsByUserId(userId);

    for (final thread in remoteThreads) {
      await localDataSource.saveThread(thread);
    }

    return const Success(null);
  } on NetworkException catch (e) {
    return Error(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    return Error(ServerFailure(message: e.message));
  } catch (e) {
    return Error(ServerFailure(message: 'Failed to sync threads: $e'));
  }
}
```

**Step 6.8**: Refactor `deleteThread()` method (lines 132-168)

**Current logic**:
- Pre-check if online (line 135)
- Return error if offline
- Remote delete first, then local

**New logic**:
- Always attempt remote delete
- Catch exceptions and map to failures
- Local delete only after remote succeeds

```dart
@override
Future<Result<void>> deleteThread(String threadId) async {
  try {
    // Step 1: Remote soft-delete first
    try {
      await remoteDataSource.softDeleteThread(threadId);
      debugPrint('✅ Remote soft-delete successful for thread: $threadId');
    } on NetworkException catch (e) {
      debugPrint('❌ Network error deleting thread $threadId: ${e.message}');
      return Error(NetworkFailure(
        message: 'Cannot delete thread while offline. Please try again when connected.',
      ));
    } on ServerException catch (e) {
      debugPrint('❌ Server error deleting thread $threadId: ${e.message}');
      return Error(ServerFailure(message: 'Failed to delete thread: ${e.message}'));
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

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/journal/data/repositories/journal_thread_repository_impl.dart`
- [ ] No references to connectivity: `grep -n "connectivity\|_isOnline" lib/features/journal/data/repositories/journal_thread_repository_impl.dart` returns empty
- [ ] Import for exceptions added
- [ ] Constructor has only 2 parameters

#### Manual Verification:
- [ ] All remote operations catch typed exceptions
- [ ] deleteThread() still requires network but uses exception handling instead of pre-check
- [ ] Create/update/archive operations don't fail if remote sync fails
- [ ] Pattern matches JournalMessageRepositoryImpl

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation (test thread creation, update, delete online/offline) before proceeding to Phase 7.

---

## Phase 7: Refactor InsightRepositoryImpl

### Overview
Apply the same simplification pattern to `InsightRepositoryImpl`.

### Changes Required:

#### 1. InsightRepositoryImpl - Remove Connectivity and Simplify
**File**: `lib/features/insights/data/repositories/insight_repository_impl.dart`

**Changes**: Follow the same pattern as JournalMessageRepositoryImpl and JournalThreadRepositoryImpl

**Step 7.1**: Remove connectivity import and dependency

```dart
import 'dart:async';
// REMOVE: import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/exceptions.dart'; // ADD
import 'package:kairos/core/errors/failures.dart';
// ... rest unchanged ...

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    // REMOVE: required this.connectivity,
  });

  final InsightLocalDataSource localDataSource;
  final InsightRemoteDataSource remoteDataSource;
  // REMOVE: final Connectivity connectivity;

  // REMOVE entire _isOnline getter
```

**Step 7.2**: Leave read methods unchanged (getInsightById, getGlobalInsights, getThreadInsights)
- These only use local datasource
- Already correct (lines 30-57)

**Step 7.3**: Refactor `watchGlobalInsights()` method (lines 60-113)

**Current logic**:
- Check if online
- If offline: return local stream only
- If online: setup remote subscription + yield local stream

**New logic**:
- Always attempt remote subscription
- Handle errors in onError
- Always yield local stream

```dart
@override
Stream<List<InsightEntity>> watchGlobalInsights(String userId) async* {
  StreamSubscription<List<InsightModel>>? remoteSub;

  try {
    // Always attempt to sync with Firestore
    remoteSub = remoteDataSource.watchGlobalInsights(userId).listen(
      (remoteModels) async {
        // Get current local insights to compare
        final localInsights = await localDataSource.getGlobalInsights(userId);
        final localIds = localInsights.map((m) => m.id).toSet();

        for (final remoteModel in remoteModels) {
          if (!localIds.contains(remoteModel.id)) {
            // New insight from remote
            await localDataSource.saveInsight(remoteModel);
            debugPrint('Synced new global insight: ${remoteModel.id}');
          } else {
            // Check if we need to update
            final localModel =
                await localDataSource.getInsightById(remoteModel.id);
            if (localModel != null &&
                localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
              await localDataSource.updateInsight(remoteModel);
              debugPrint('Updated global insight: ${remoteModel.id}');
            }
          }
        }
      },
      onError: (Object error) {
        // Network errors are transient - log and continue with local data
        debugPrint('Remote insight sync error (will retry when online): $error');
      },
    );

    // Yield the local stream (updated by remote listener when online)
    yield* localDataSource
        .watchGlobalInsights(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  } finally {
    await remoteSub?.cancel();
  }
}
```

**Step 7.4**: Refactor `watchThreadInsights()` method (lines 116-175)

**Current logic**:
- Check if online
- If offline: return local only
- Get userId from local data
- If online: setup remote subscription

**New logic**:
- Get userId from local data
- Always attempt remote subscription
- Handle errors in onError

```dart
@override
Stream<List<InsightEntity>> watchThreadInsights(String threadId) async* {
  StreamSubscription<List<InsightModel>>? remoteSub;

  try {
    // Get userId from local insights (needed for Firestore query)
    final localInsights = await localDataSource.getThreadInsights(threadId);

    if (localInsights.isEmpty) {
      // No insights yet, just watch local
      yield* localDataSource
          .watchThreadInsights(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }

    final userId = localInsights.first.userId;

    // Always attempt remote sync
    remoteSub = remoteDataSource.watchThreadInsights(userId, threadId).listen(
      (remoteModels) async {
        final localInsights =
            await localDataSource.getThreadInsights(threadId);
        final localIds = localInsights.map((m) => m.id).toSet();

        for (final remoteModel in remoteModels) {
          if (!localIds.contains(remoteModel.id)) {
            await localDataSource.saveInsight(remoteModel);
            debugPrint('Synced new thread insight: ${remoteModel.id}');
          } else {
            final localModel =
                await localDataSource.getInsightById(remoteModel.id);
            if (localModel != null &&
                localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
              await localDataSource.updateInsight(remoteModel);
              debugPrint('Updated thread insight: ${remoteModel.id}');
            }
          }
        }
      },
      onError: (Object error) {
        debugPrint('Remote thread insight sync error (will retry when online): $error');
      },
    );

    yield* localDataSource
        .watchThreadInsights(threadId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  } finally {
    await remoteSub?.cancel();
  }
}
```

**Step 7.5**: Refactor `syncInsights()` method (lines 178-203)

```dart
@override
Future<Result<void>> syncInsights(String userId) async {
  try {
    // Sync global insights
    final remoteGlobalInsights =
        await remoteDataSource.getGlobalInsights(userId);
    for (final insight in remoteGlobalInsights) {
      await localDataSource.saveInsight(insight);
    }

    // Note: Thread insights will sync when their specific streams are watched
    // This is an optimization to avoid loading all thread insights at once

    return const Success(null);
  } on NetworkException catch (e) {
    return Error(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    return Error(ServerFailure(message: e.message));
  } catch (e) {
    return Error(ServerFailure(message: 'Failed to sync insights: $e'));
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze lib/features/insights/`
- [ ] No references to connectivity: `grep -n "connectivity\|_isOnline" lib/features/insights/data/repositories/insight_repository_impl.dart` returns empty
- [ ] Import for exceptions added
- [ ] Constructor has only 2 parameters

#### Manual Verification:
- [ ] All stream methods use onError callbacks
- [ ] syncInsights() catches typed exceptions
- [ ] Pattern matches journal repositories

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 8.

---

## Phase 8: Update Dependency Injection (Providers)

### Overview
Remove `connectivity` parameter from all repository provider constructors.

### Changes Required:

#### 1. Journal Providers
**File**: `lib/features/journal/presentation/providers/journal_providers.dart`

**Changes**: Remove connectivity parameters from repository providers

```dart
// Lines 49-59: threadRepositoryProvider
final threadRepositoryProvider = Provider<JournalThreadRepository>((ref) {
  final localDataSource = ref.watch(threadLocalDataSourceProvider);
  final remoteDataSource = ref.watch(threadRemoteDataSourceProvider);
  // REMOVE: final connectivity = ref.watch(connectivityProvider);

  return JournalThreadRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    // REMOVE: connectivity: connectivity,
  );
});

// Lines 61-71: messageRepositoryProvider
final messageRepositoryProvider = Provider<JournalMessageRepository>((ref) {
  final localDataSource = ref.watch(messageLocalDataSourceProvider);
  final remoteDataSource = ref.watch(messageRemoteDataSourceProvider);
  // REMOVE: final connectivity = ref.watch(connectivityProvider);

  return JournalMessageRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    // REMOVE: connectivity: connectivity,
  );
});
```

#### 2. Insight Providers
**File**: Find the insights provider file (likely `lib/features/insights/presentation/providers/insight_providers.dart`)

**Changes**: Remove connectivity parameter from insight repository provider

```dart
final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final localDataSource = ref.watch(insightLocalDataSourceProvider);
  final remoteDataSource = ref.watch(insightRemoteDataSourceProvider);
  // REMOVE: final connectivity = ref.watch(connectivityProvider);

  return InsightRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    // REMOVE: connectivity: connectivity,
  );
});
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze`
- [ ] App builds successfully: `~/flutter/bin/flutter build apk --debug` (or appropriate platform)
- [ ] No references to connectivity in repository providers: `grep -n "connectivity" lib/features/*/presentation/providers/*providers.dart`

#### Manual Verification:
- [ ] All providers have correct number of parameters
- [ ] No runtime errors when app starts
- [ ] Repositories are properly injected via Riverpod

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation (launch app, verify no DI errors) before proceeding to Phase 9.

---

## Phase 9: Testing and Validation

### Overview
Run all tests and perform comprehensive manual testing to ensure the refactoring didn't break any functionality.

### Changes Required:

#### 1. Update Unit Tests
**Files**: All test files that mock `Connectivity`

**Expected changes**:
- Remove `Connectivity` mocks from repository tests
- Update repository constructor calls to not include connectivity
- Files likely affected:
  - `test/features/journal/data/repositories/journal_message_repository_impl_test.dart`
  - `test/features/journal/data/repositories/journal_thread_repository_impl_test.dart`
  - `test/features/insights/data/repositories/insight_repository_impl_test.dart`

**Search for test files**:
```bash
find test -name "*repository*test.dart" -type f
```

**Example fix pattern**:
```dart
// BEFORE:
final mockConnectivity = MockConnectivity();
final repository = JournalMessageRepositoryImpl(
  localDataSource: mockLocal,
  remoteDataSource: mockRemote,
  connectivity: mockConnectivity,
);

// AFTER:
final repository = JournalMessageRepositoryImpl(
  localDataSource: mockLocal,
  remoteDataSource: mockRemote,
);
```

#### 2. Update Mock Files
**Files**: Any `.mocks.dart` files that have Connectivity mocks

**Expected changes**:
- Remove `MockConnectivity` class references if no longer used elsewhere
- Files likely affected (based on grep results):
  - `test/features/journal/data/repositories/journal_thread_repository_impl_test.mocks.dart`
  - `test/core/network/network_info_test.mocks.dart` (keep this - used by NetworkInfo tests)

**Note**: Only remove Connectivity mocks from repository tests, NOT from NetworkInfo tests (which legitimately use connectivity).

### Success Criteria:

#### Automated Verification:
- [ ] All unit tests pass: `~/flutter/bin/flutter test`
- [ ] Code analysis passes: `~/flutter/bin/flutter analyze`
- [ ] No compilation errors: `~/flutter/bin/flutter build apk --debug`
- [ ] No unused imports: analyzer should flag any remaining connectivity imports
- [ ] Grep verification: `grep -r "_isOnline\|connectivity_plus" lib/features/*/data/repositories/` returns no results

#### Manual Verification:
- [ ] **Offline Message Creation**:
  - Enable airplane mode
  - Create text message → should show "Waiting to upload" status
  - Create image/audio message → should show "Failed" status with retry button
  - Verify messages appear in local list

- [ ] **Online Message Creation**:
  - Disable airplane mode
  - Create text message → should sync immediately and show no upload status
  - Create image/audio message → should upload and show completed status
  - Verify messages appear in Firestore console

- [ ] **Offline→Online Transition**:
  - Create messages while offline (text and media)
  - Go back online
  - Trigger upload retry for failed media messages
  - Verify automatic sync happens for text messages
  - Check Firestore console for synced data

- [ ] **Thread Operations**:
  - Create thread offline → should save locally
  - Go online → verify thread syncs to remote
  - Update thread title offline → should update locally
  - Go online → verify update syncs
  - Delete thread offline → should show "Cannot delete while offline" error
  - Delete thread online → should delete from both local and remote

- [ ] **Sync Operations**:
  - Use `syncThreadIncremental()` while offline → should return NetworkFailure
  - Use `syncThreadIncremental()` while online → should fetch and merge updates
  - Verify incremental sync doesn't duplicate messages

- [ ] **Stream Watching**:
  - Open thread screen while offline → should show local messages
  - Go online → should automatically sync new remote messages
  - Have another device add a message → should appear in real-time
  - Disconnect network mid-stream → should continue showing local data with error log

- [ ] **Error Messages**:
  - Verify user-facing error messages are friendly (not raw exceptions)
  - Check that NetworkFailure messages mention connectivity
  - Check that ServerFailure messages are appropriate
  - Verify no "SocketException" or "FirebaseException" shown to users

- [ ] **Upload Status Tracking**:
  - Verify upload status transitions correctly: notStarted → inProgress → completed
  - Verify failed uploads increment retry count
  - Verify retry mechanism works for failed media uploads
  - Check `lastUploadAttemptMillis` is set on failures

**Implementation Note**: This is the final phase. After all automated tests pass and manual testing confirms correct behavior, the refactoring is complete. Document any edge cases discovered during testing.

---

## Testing Strategy

### Unit Tests:
- **Repository Tests**: Mock datasources, verify exception mapping
- **Remote DataSource Tests**: Verify Firestore exception wrapping
- **Exception Mapper Tests**: Test all Firestore error codes map correctly

### Integration Tests:
- **Offline Flow**: Create/update/sync while offline
- **Online Flow**: All operations with network available
- **Transition Flow**: Network state changes during operations

### Manual Testing Steps:
1. Install app in debug mode on physical device
2. Enable airplane mode and test all create/update operations
3. Disable airplane mode and verify sync behavior
4. Toggle network state during active stream watching
5. Check Firestore console for data consistency
6. Review logs for appropriate error messages
7. Test upload retry mechanism for media messages
8. Verify delete operation requires network

## Performance Considerations

### No Performance Impact Expected:
- Removing `_isOnline` checks eliminates async overhead
- Always attempting remote operations may fail faster (no pre-check delay)
- Exception handling is lightweight compared to connectivity checks
- Stream subscriptions remain the same (onError adds minimal overhead)

### Potential Minor Improvements:
- Fewer async operations (no connectivity checks)
- Cleaner code paths (less branching)
- Better error propagation (typed exceptions)

## Migration Notes

### No Data Migration Required:
- All database schemas remain unchanged
- Firestore structure unchanged
- Upload status fields and logic preserved
- Local file paths maintained

### Breaking Changes:
- None - this is purely an internal refactoring

### Backwards Compatibility:
- Fully compatible with existing data
- No API changes for consumers (use cases, controllers)
- Providers have same public interface (return same types)

## References

- Established pattern: [firebase_auth_repository.dart:61-166](lib/features/auth/data/repositories/firebase_auth_repository.dart#L61-L166)
- Exception definitions: [exceptions.dart:1-40](lib/core/errors/exceptions.dart#L1-L40)
- Failure definitions: [failures.dart:1-71](lib/core/errors/failures.dart#L1-L71)
- Result wrapper: [result.dart:1-48](lib/core/utils/result.dart#L1-L48)
- Current message repository: [journal_message_repository_impl.dart:1-274](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L1-L274)
- Current thread repository: [journal_thread_repository_impl.dart:1-169](lib/features/journal/data/repositories/journal_thread_repository_impl.dart#L1-L169)
- Current insight repository: [insight_repository_impl.dart:1-204](lib/features/insights/data/repositories/insight_repository_impl.dart#L1-L204)