# Thread Incremental Sync Implementation Plan

## Overview

Implement incremental sync for journal threads, mirroring the existing incremental sync pattern used for journal messages. This will reduce bandwidth usage and improve sync performance by fetching only threads updated since the last sync. Additionally, soft-deleted threads from the remote datasource will be hard-deleted locally along with their messages.

## Current State Analysis

### What Exists Now

**Journal Messages (Reference Implementation):**
- ✅ Incremental sync via `SyncThreadMessagesUseCase`
- ✅ Controller: `SyncController` with state management
- ✅ Repository method: `syncThreadIncremental(String threadId)`
- ✅ Timestamp-based queries: `updatedAtMillis > lastLocalTimestamp`
- ✅ Local datasource: `getLastUpdatedAtMillis()` method
- ✅ Remote datasource: `getUpdatedMessages()` with timestamp filter

**Journal Threads (Current State):**
- ❌ Only full sync: `syncThreads(String userId)` fetches ALL threads
- ✅ Soft delete support: `isDeleted` + `deletedAtMillis` fields exist
- ✅ Remote filtering: Already filters `isDeleted == false` in queries
- ✅ Hard delete method: `hardDeleteThreadAndMessages()` exists
- ❌ No incremental sync mechanism
- ❌ No controller for thread sync state management

### Key Discoveries

**Thread Model Structure** ([journal_thread_model.dart:8-80](lib/features/journal/data/models/journal_thread_model.dart#L8-L80)):
- Has `updatedAtMillis` field indexed for queries
- Has `isDeleted` boolean and `deletedAtMillis` for soft deletes
- Already syncs to Firestore with these fields

**Existing Hard Delete** ([journal_thread_local_datasource.dart:95-111](lib/features/journal/data/datasources/journal_thread_local_datasource.dart#L95-L111)):
- `hardDeleteThreadAndMessages()` removes thread + all messages
- Uses Isar transaction for atomicity

**Remote Soft Delete** ([journal_thread_remote_datasource.dart:68-79](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart#L68-L79)):
- `softDeleteThread()` sets `isDeleted=true` and `deletedAtMillis` in Firestore

## Desired End State

After implementation, the system will:

1. **Incrementally sync threads** by fetching only threads where `updatedAtMillis > lastUserSyncTimestamp`
2. **Hard-delete soft-deleted threads locally** when `isDeleted=true` is received from remote
3. **Cascade delete messages** when threads are hard-deleted locally
4. **Trigger sync automatically** on thread list screen entry, connectivity restore, and pull-to-refresh
5. **Provide UI feedback** through sync state management (loading, success, error)
6. **Follow clean architecture** matching the message sync pattern

### Verification

**Automated Verification:**
- [ ] Unit tests pass: `flutter test test/features/journal/domain/usecases/sync_threads_usecase_test.dart`
- [ ] Unit tests pass: `flutter test test/features/journal/data/repositories/journal_thread_repository_impl_test.dart`
- [ ] Integration tests pass: `flutter test integration_test/`
- [ ] No linting errors: `flutter analyze`
- [ ] Code generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`

**Manual Verification:**
- [ ] Thread list screen shows loading indicator during sync
- [ ] Pull-to-refresh triggers sync and shows success message
- [ ] Soft-deleted threads are removed from local database after sync
- [ ] Sync triggers automatically when app reconnects to internet
- [ ] Error messages display when sync fails (airplane mode test)
- [ ] Only changed threads are fetched (verify with Firestore console logs)
- [ ] Performance is acceptable with 100+ threads

## What We're NOT Doing

- Real-time streaming of thread updates (continuing to use polling/manual sync)
- Syncing archived threads (they remain filtered out per existing logic)
- Conflict resolution for concurrent edits (relying on Firestore's last-write-wins)
- Optimistic UI updates (threads are synced after operations complete)
- Background sync via WorkManager/background tasks (only on-demand sync)

## Implementation Approach

Mirror the message sync architecture by creating parallel components for thread sync:

1. **Add timestamp tracking** to local datasource
2. **Add incremental fetch** to remote datasource
3. **Implement repository sync logic** with hard-delete for soft-deleted threads
4. **Create use case** for thread incremental sync
5. **Extend sync controller** to support thread sync (or create separate controller)
6. **Update UI screens** to trigger and monitor sync

All components will follow the existing patterns in message sync for consistency.

---

## Phase 1: Data Layer - Local Datasource Enhancement

### Overview
Add timestamp tracking to the local datasource to support incremental queries. This mirrors `getLastUpdatedAtMillis()` for messages.

### Changes Required

#### 1. Local Datasource Interface
**File**: [lib/features/journal/data/datasources/journal_thread_local_datasource.dart](lib/features/journal/data/datasources/journal_thread_local_datasource.dart#L5-L16)

**Changes**: Add method signature

```dart
abstract class JournalThreadLocalDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
  Future<void> archiveThread(String threadId);
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId);
  Future<void> hardDeleteThreadAndMessages(String threadId);

  /// Gets the most recent updatedAtMillis for threads belonging to a user.
  /// Returns null if no threads exist locally for this user.
  /// Used to determine the starting point for incremental sync.
  Future<int?> getLastUpdatedAtMillis(String userId);
}
```

#### 2. Local Datasource Implementation
**File**: [lib/features/journal/data/datasources/journal_thread_local_datasource.dart](lib/features/journal/data/datasources/journal_thread_local_datasource.dart#L18-L112)

**Changes**: Add method implementation after `hardDeleteThreadAndMessages()`

```dart
@override
Future<int?> getLastUpdatedAtMillis(String userId) async {
  final threads = await isar.journalThreadModels
      .filter()
      .userIdEqualTo(userId)
      .and()
      .isDeletedEqualTo(false)
      .sortByUpdatedAtMillisDesc()
      .findAll();

  if (threads.isEmpty) return null;

  final timestamp = threads.first.updatedAtMillis;

  // Validate timestamp is within valid DateTime range
  const minValid = -8640000000000000;
  const maxValid = 8640000000000000;

  if (timestamp < minValid || timestamp > maxValid) {
    return null; // Return null for invalid timestamps (will trigger full sync)
  }

  return timestamp;
}
```

**Rationale**: This queries Isar for the most recent thread timestamp for a user, with validation to prevent invalid DateTime conversions. Returns `null` if no threads exist, triggering a full sync on first run.

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] Method returns correct timestamp when threads exist
- [ ] Method returns null when no threads exist
- [ ] Method returns null for invalid timestamps
- [ ] Method filters out soft-deleted threads

#### Manual Verification:
- [ ] Query executes efficiently in Isar (check query performance)
- [ ] No crashes when database is empty

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Data Layer - Remote Datasource Enhancement

### Overview
Add incremental fetch capability to the remote datasource to query Firestore for only updated threads.

### Changes Required

#### 1. Remote Datasource Interface
**File**: [lib/features/journal/data/datasources/journal_thread_remote_datasource.dart](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart#L5-L13)

**Changes**: Add method signatures

```dart
abstract class JournalThreadRemoteDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
  Future<void> softDeleteThread(String threadId);

  /// Fetches threads updated after the given timestamp.
  /// This includes both updated threads (isDeleted=false) and soft-deleted threads (isDeleted=true).
  ///
  /// The client is responsible for handling soft-deleted threads by performing hard deletes locally.
  Future<List<JournalThreadModel>> getUpdatedThreads(
    String userId,
    int lastUpdatedAtMillis,
  );
}
```

#### 2. Remote Datasource Implementation
**File**: [lib/features/journal/data/datasources/journal_thread_remote_datasource.dart](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart#L15-L80)

**Changes**: Add method implementation after `softDeleteThread()`

```dart
@override
Future<List<JournalThreadModel>> getUpdatedThreads(
  String userId,
  int lastUpdatedAtMillis,
) async {
  try {
    // Query for all threads updated after lastUpdatedAtMillis
    // NOTE: We do NOT filter by isDeleted here - we need to know about deletions
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('updatedAtMillis', isGreaterThan: lastUpdatedAtMillis)
        .orderBy('updatedAtMillis', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalThreadModel.fromMap(doc.data()))
        .toList();
  } catch (e) {
    mapFirestoreException(e, context: 'Failed to get updated threads');
  }
}
```

**Rationale**:
- **Does NOT filter by `isDeleted`** because we need to receive soft-deleted threads to hard-delete them locally
- Uses `updatedAtMillis > lastUpdatedAtMillis` for incremental queries
- Orders by `updatedAtMillis` ascending for chronological processing
- Relies on Firestore composite index: `userId` + `updatedAtMillis`

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] Firestore query executes successfully
- [ ] Returns both active and soft-deleted threads
- [ ] Orders results by updatedAtMillis ascending
- [ ] Handles Firestore exceptions properly

#### Manual Verification:
- [ ] Firestore composite index exists: `journalThreads` collection with `userId` + `updatedAtMillis`
- [ ] Query returns expected threads in Firestore console
- [ ] Soft-deleted threads are included in results

**Implementation Note**: After completing this phase, create the required Firestore composite index before proceeding. Index creation command will be provided in Phase 7 (Testing Strategy).

---

## Phase 3: Domain Layer - Repository Enhancement

### Overview
Implement the core incremental sync logic in the repository, including hard-delete handling for soft-deleted threads.

### Changes Required

#### 1. Repository Interface
**File**: [lib/features/journal/domain/repositories/journal_thread_repository.dart](lib/features/journal/domain/repositories/journal_thread_repository.dart#L5-L26)

**Changes**: Add method signature after `syncThreads()`

```dart
abstract class JournalThreadRepository {
  Future<Result<JournalThreadEntity>> createThread(JournalThreadEntity thread);
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId);
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId);
  Future<Result<void>> updateThread(JournalThreadEntity thread);
  Future<Result<void>> archiveThread(String threadId);
  Future<Result<void>> syncThreads(String userId);
  Future<Result<void>> deleteThread(String threadId);

  /// Performs incremental sync for threads belonging to a user.
  ///
  /// Fetches only threads updated since the last local sync timestamp.
  /// For soft-deleted threads (isDeleted=true), performs hard delete locally
  /// along with cascade deletion of all associated messages.
  ///
  /// Returns [Success] if sync completes successfully (even if no updates).
  /// Returns [Error] with [NetworkFailure] if offline.
  /// Returns [Error] with [ServerFailure] if remote fetch fails.
  Future<Result<void>> syncThreadsIncremental(String userId);
}
```

#### 2. Repository Implementation
**File**: [lib/features/journal/data/repositories/journal_thread_repository_impl.dart](lib/features/journal/data/repositories/journal_thread_repository_impl.dart#L13-L163)

**Changes**: Add method implementation after `deleteThread()`

```dart
@override
Future<Result<void>> syncThreadsIncremental(String userId) async {
  try {
    // Get the latest updatedAtMillis from local DB
    final lastUpdatedAtMillis = await localDataSource.getLastUpdatedAtMillis(userId);

    // If no threads exist locally, use 0 to fetch all threads
    final sinceTimestamp = lastUpdatedAtMillis ?? 0;

    logger.i(
      '🔄 Incremental thread sync for user $userId since timestamp: $sinceTimestamp',
    );

    // Fetch updated threads from remote (includes soft-deleted threads)
    final updatedThreads = await remoteDataSource.getUpdatedThreads(
      userId,
      sinceTimestamp,
    );

    logger.i('📥 Fetched ${updatedThreads.length} updated threads');

    if (updatedThreads.isEmpty) {
      logger.i('✅ No thread updates to sync');
      return const Success(null);
    }

    // Process each updated thread
    for (final thread in updatedThreads) {
      if (thread.isDeleted) {
        // Hard delete locally when remote is soft-deleted
        logger.i('🗑️  Hard-deleting soft-deleted thread: ${thread.id}');
        try {
          await localDataSource.hardDeleteThreadAndMessages(thread.id);
          logger.i('✅ Hard-deleted thread ${thread.id} and its messages');
        } catch (e) {
          logger.w('⚠️  Failed to hard-delete thread ${thread.id}: $e');
          // Continue processing other threads
        }
      } else {
        // Upsert active thread to local database
        final existingThread = await localDataSource.getThreadById(thread.id);

        if (existingThread != null) {
          // Update existing thread
          await localDataSource.updateThread(thread);
          logger.i('📝 Updated thread: ${thread.id}');
        } else {
          // New thread from remote
          await localDataSource.saveThread(thread);
          logger.i('✨ Added new thread: ${thread.id}');
        }
      }
    }

    logger.i('✅ Incremental thread sync completed successfully');
    return const Success(null);
  } on NetworkException catch (e) {
    logger.i('❌ Network error during incremental thread sync: ${e.message}');
    return Error(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    logger.i('❌ Server error during incremental thread sync: ${e.message}');
    return Error(ServerFailure(message: e.message));
  } catch (e) {
    logger.i('❌ Incremental thread sync failed: $e');
    return Error(ServerFailure(message: 'Failed to sync threads: $e'));
  }
}
```

**Rationale**:
- Mirrors message sync implementation structure for consistency
- Handles soft-deleted threads by calling `hardDeleteThreadAndMessages()`
- Upserts active threads to local database (save new, update existing)
- Continues processing if individual hard-delete fails (defensive programming)
- Returns `Success(null)` even if no updates (not an error condition)

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] Repository method handles all Result cases
- [ ] Proper exception handling for network/server errors
- [ ] Logging statements execute correctly

#### Manual Verification:
- [ ] Soft-deleted threads are removed from local database
- [ ] Active threads are upserted correctly
- [ ] Messages are cascade-deleted with threads
- [ ] Sync continues even if one thread fails to delete

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: Domain Layer - Use Case Creation

### Overview
Create a dedicated use case for thread incremental sync, following the single-responsibility principle.

### Changes Required

#### 1. Create Use Case File
**File**: `lib/features/journal/domain/usecases/sync_threads_usecase.dart` (NEW FILE)

**Changes**: Create new file with complete implementation

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';

/// Use case for performing incremental sync of journal threads.
///
/// Fetches only threads updated since the last local sync timestamp.
/// Handles soft-deleted threads by performing hard deletes locally.
class SyncThreadsUseCase {
  SyncThreadsUseCase({required this.threadRepository});

  final JournalThreadRepository threadRepository;

  /// Performs incremental sync for threads belonging to the given user.
  ///
  /// Returns [Success] if sync completes successfully.
  /// Returns [Error] with appropriate failure if sync fails.
  Future<Result<void>> execute(String userId) async {
    return threadRepository.syncThreadsIncremental(userId);
  }
}
```

**Rationale**: Thin wrapper around repository method, maintaining clean architecture separation between presentation and data layers.

### Success Criteria

#### Automated Verification:
- [ ] File created successfully
- [ ] Code compiles without errors: `flutter analyze`
- [ ] Use case properly delegates to repository

#### Manual Verification:
- [ ] File follows project structure conventions
- [ ] Import paths are correct

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Presentation Layer - Sync Controller Enhancement

### Overview
Extend the existing `SyncController` to support thread sync operations alongside message sync, reusing the same state management architecture.

### Changes Required

#### 1. Extend Sync State
**File**: [lib/features/journal/presentation/controllers/sync_controller.dart](lib/features/journal/presentation/controllers/sync_controller.dart#L6-L29)

**Changes**: Add new state class for thread sync

```dart
// Sync state
sealed class SyncState {
  const SyncState();
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncInProgress extends SyncState {
  const SyncInProgress(this.threadId);
  final String threadId;
}

class SyncSuccess extends SyncState {
  const SyncSuccess(this.threadId);
  final String threadId;
}

class SyncError extends SyncState {
  const SyncError(this.threadId, this.message);
  final String threadId;
  final String message;
}

// NEW: Thread list sync state (separate from individual thread message sync)
class ThreadListSyncInProgress extends SyncState {
  const ThreadListSyncInProgress(this.userId);
  final String userId;
}

class ThreadListSyncSuccess extends SyncState {
  const ThreadListSyncSuccess(this.userId);
  final String userId;
}

class ThreadListSyncError extends SyncState {
  const ThreadListSyncError(this.userId, this.message);
  final String userId;
  final String message;
}
```

#### 2. Add Sync Threads Method
**File**: [lib/features/journal/presentation/controllers/sync_controller.dart](lib/features/journal/presentation/controllers/sync_controller.dart#L32-L81)

**Changes**: Add dependency injection and method after `syncThread()`

```dart
// Sync controller
class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required this.syncThreadMessagesUseCase,
    required this.syncThreadsUseCase, // NEW: Add thread sync use case
  }) : super(const SyncInitial());

  final SyncThreadMessagesUseCase syncThreadMessagesUseCase;
  final SyncThreadsUseCase syncThreadsUseCase; // NEW

  /// Trigger incremental sync for a thread's messages
  Future<void> syncThread(String threadId) async {
    // Don't sync if already syncing this thread
    if (state is SyncInProgress) {
      final current = state as SyncInProgress;
      if (current.threadId == threadId) {
        return;
      }
    }

    state = SyncInProgress(threadId);

    final result = await syncThreadMessagesUseCase.execute(threadId);

    result.when<void>(
      success: (_) {
        state = SyncSuccess(threadId);
        // Auto-reset to initial after success
        Future.delayed(const Duration(seconds: 1), () {
          if (state is SyncSuccess) {
            state = const SyncInitial();
          }
        });
      },
      error: (Failure failure) {
        state = SyncError(threadId, _getErrorMessage(failure));
      },
    );
  }

  /// NEW: Trigger incremental sync for all threads of a user
  Future<void> syncThreads(String userId) async {
    // Don't sync if already syncing threads for this user
    if (state is ThreadListSyncInProgress) {
      final current = state as ThreadListSyncInProgress;
      if (current.userId == userId) {
        return;
      }
    }

    state = ThreadListSyncInProgress(userId);

    final result = await syncThreadsUseCase.execute(userId);

    result.when<void>(
      success: (_) {
        state = ThreadListSyncSuccess(userId);
        // Auto-reset to initial after success
        Future.delayed(const Duration(seconds: 1), () {
          if (state is ThreadListSyncSuccess) {
            state = const SyncInitial();
          }
        });
      },
      error: (Failure failure) {
        state = ThreadListSyncError(userId, _getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure(:final message) => message,
      ServerFailure(:final message) => message,
      CacheFailure(:final message) => message,
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = const SyncInitial();
  }
}
```

**Rationale**:
- Reuses existing `SyncController` instead of creating separate controller
- Separate state classes prevent conflicts between thread and message sync
- Maintains same auto-reset pattern for consistent UX
- Deduplication check prevents concurrent syncs for same user

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] State transitions work correctly
- [ ] No state conflicts between thread and message sync

#### Manual Verification:
- [ ] Controller state updates correctly during sync
- [ ] Auto-reset works after 1 second
- [ ] Duplicate sync attempts are prevented

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Presentation Layer - Provider Updates

### Overview
Register the new use case and update the sync controller provider to inject it.

### Changes Required

#### 1. Update Journal Providers
**File**: [lib/features/journal/presentation/providers/journal_providers.dart](lib/features/journal/presentation/providers/journal_providers.dart)

**Changes**: Add use case provider and update sync controller provider

```dart
// Add this import at the top
import 'package:kairos/features/journal/domain/usecases/sync_threads_usecase.dart';

// ... existing providers ...

// NEW: Sync threads use case provider
final syncThreadsUseCaseProvider = Provider<SyncThreadsUseCase>((ref) {
  final threadRepository = ref.watch(threadRepositoryProvider);
  return SyncThreadsUseCase(threadRepository: threadRepository);
});

// UPDATE: Sync controller provider - add syncThreadsUseCase dependency
final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>((ref) {
  final syncThreadMessagesUseCase = ref.watch(syncThreadMessagesUseCaseProvider);
  final syncThreadsUseCase = ref.watch(syncThreadsUseCaseProvider); // NEW

  return SyncController(
    syncThreadMessagesUseCase: syncThreadMessagesUseCase,
    syncThreadsUseCase: syncThreadsUseCase, // NEW
  );
});
```

**Rationale**: Follows existing provider pattern for dependency injection. The sync controller now has access to both message and thread sync use cases.

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] Provider graph resolves correctly
- [ ] No circular dependencies

#### Manual Verification:
- [ ] App starts without provider initialization errors
- [ ] Sync controller receives both use cases

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 7.

---

## Phase 7: Presentation Layer - Thread List Screen Updates

### Overview
Update the thread list screen to trigger incremental sync on screen entry, connectivity restore, and pull-to-refresh.

### Changes Required

#### 1. Update Thread List Screen
**File**: [lib/features/journal/presentation/screens/thread_list_screen.dart](lib/features/journal/presentation/screens/thread_list_screen.dart)

**Changes**: Add sync triggers and UI feedback

```dart
// Add these imports at the top
import 'dart:async';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/journal/presentation/controllers/sync_controller.dart';

class _ThreadListScreenState extends ConsumerState<ThreadListScreen> {
  // NEW: For debounced auto-sync on connectivity changes
  Timer? _connectivitySyncTimer;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();

    // NEW: Trigger initial sync on screen entry
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      Future.microtask(
        () => ref.read(syncControllerProvider.notifier).syncThreads(currentUser.id),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySyncTimer?.cancel(); // NEW
    super.dispose();
  }

  // NEW: Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    logger.i('🔄 Manual refresh triggered for thread list');

    await ref.read(syncControllerProvider.notifier).syncThreads(currentUser.id);

    // Show feedback based on sync state
    if (mounted) {
      final syncState = ref.read(syncControllerProvider);
      if (syncState is ThreadListSyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${syncState.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (syncState is ThreadListSyncSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threads synced successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // NEW: Listen for connectivity changes (auto-sync on reconnect)
    ref.listen<AsyncValue<bool>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((isOnline) {
          final user = ref.read(currentUserProvider);

          // Detect transition from offline to online
          if (_wasOffline && isOnline && user != null) {
            logger.i('🌐 Device reconnected - scheduling thread list sync');

            // Cancel any pending sync timer
            _connectivitySyncTimer?.cancel();

            // Debounce sync by 2 seconds after reconnection
            _connectivitySyncTimer = Timer(const Duration(seconds: 2), () {
              logger.i('🔄 Triggering auto-sync for thread list');
              ref.read(syncControllerProvider.notifier).syncThreads(user.id);
            });
          }

          // Update offline tracking state
          _wasOffline = !isOnline;
        });
      },
    );

    // NEW: Listen to sync controller state for background feedback
    ref.listen<SyncState>(syncControllerProvider, (previous, next) {
      if (next is ThreadListSyncError && mounted) {
        logger.i('❌ Background thread sync failed: ${next.message}');
        // Optionally show a subtle notification
      } else if (next is ThreadListSyncSuccess) {
        logger.i('✅ Background thread sync completed successfully');
      }
    });

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final threadsAsync = ref.watch(threadsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Threads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/thread/new'),
          ),
        ],
      ),
      body: threadsAsync.when(
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  const Text('No threads yet'),
                  const SizedBox(height: 8),
                  const Text('Create your first journal thread'),
                ],
              ),
            );
          }

          // NEW: Wrap with RefreshIndicator for pull-to-refresh
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return ThreadListTile(
                  thread: thread,
                  onTap: () => context.push('/thread/${thread.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Rationale**:
- Mirrors the sync patterns from `ThreadDetailScreen` for consistency
- Debounces connectivity sync to avoid premature sync attempts
- Pull-to-refresh provides manual sync option
- Initial sync on screen entry ensures fresh data
- Listeners provide non-blocking feedback

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] No runtime errors on screen navigation

#### Manual Verification:
- [ ] Pull-to-refresh triggers sync correctly
- [ ] Sync indicator shows during sync
- [ ] Success/error messages display appropriately
- [ ] Auto-sync triggers after connectivity restore
- [ ] Initial sync runs when screen opens
- [ ] No duplicate syncs occur

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 8.

---

## Phase 8: Testing

### Overview
Create unit tests for the new use case and update existing tests to cover incremental sync logic.

### Changes Required

#### 1. Create Use Case Test
**File**: `test/features/journal/domain/usecases/sync_threads_usecase_test.dart` (NEW FILE)

**Changes**: Create new test file

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/usecases/sync_threads_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_threads_usecase_test.mocks.dart';

@GenerateMocks([JournalThreadRepository])
void main() {
  late SyncThreadsUseCase useCase;
  late MockJournalThreadRepository mockRepository;

  setUp(() {
    mockRepository = MockJournalThreadRepository();
    useCase = SyncThreadsUseCase(threadRepository: mockRepository);
  });

  const testUserId = 'user123';

  group('SyncThreadsUseCase', () {
    test('should return Success when repository sync succeeds', () async {
      // Arrange
      when(mockRepository.syncThreadsIncremental(any))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result, const Success(null));
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when repository returns network error', () async {
      // Arrange
      const failure = NetworkFailure(message: 'No internet connection');
      when(mockRepository.syncThreadsIncremental(any))
          .thenAnswer((_) async => const Error(failure));

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result, const Error(failure));
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns server error', () async {
      // Arrange
      const failure = ServerFailure(message: 'Server error');
      when(mockRepository.syncThreadsIncremental(any))
          .thenAnswer((_) async => const Error(failure));

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result, const Error(failure));
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

#### 2. Update Repository Tests
**File**: [test/features/journal/data/repositories/journal_thread_repository_impl_test.dart](test/features/journal/data/repositories/journal_thread_repository_impl_test.dart)

**Changes**: Add test group for `syncThreadsIncremental()`

```dart
group('syncThreadsIncremental', () {
  const testUserId = 'user123';
  const testTimestamp = 1234567890;

  test('should perform incremental sync with last timestamp', () async {
    // Arrange
    final threads = [
      JournalThreadModel(
        id: 'thread1',
        userId: testUserId,
        title: 'Updated Thread',
        createdAtMillis: 1000000000,
        updatedAtMillis: 1234567900,
        isDeleted: false,
      ),
    ];

    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenAnswer((_) async => threads);
    when(mockLocalDataSource.getThreadById(any))
        .thenAnswer((_) async => null);
    when(mockLocalDataSource.saveThread(any))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result, const Success(null));
    verify(mockLocalDataSource.getLastUpdatedAtMillis(testUserId));
    verify(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp));
    verify(mockLocalDataSource.saveThread(any));
  });

  test('should use timestamp 0 when no local threads exist', () async {
    // Arrange
    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => null);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, 0))
        .thenAnswer((_) async => []);

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result, const Success(null));
    verify(mockLocalDataSource.getLastUpdatedAtMillis(testUserId));
    verify(mockRemoteDataSource.getUpdatedThreads(testUserId, 0));
  });

  test('should hard-delete soft-deleted threads locally', () async {
    // Arrange
    final softDeletedThread = JournalThreadModel(
      id: 'deleted_thread',
      userId: testUserId,
      title: 'Deleted Thread',
      createdAtMillis: 1000000000,
      updatedAtMillis: 1234567900,
      isDeleted: true,
      deletedAtMillis: 1234567900,
    );

    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenAnswer((_) async => [softDeletedThread]);
    when(mockLocalDataSource.hardDeleteThreadAndMessages(any))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result, const Success(null));
    verify(mockLocalDataSource.hardDeleteThreadAndMessages(softDeletedThread.id));
    verifyNever(mockLocalDataSource.saveThread(any));
    verifyNever(mockLocalDataSource.updateThread(any));
  });

  test('should update existing threads', () async {
    // Arrange
    final existingThread = JournalThreadModel(
      id: 'thread1',
      userId: testUserId,
      title: 'Old Title',
      createdAtMillis: 1000000000,
      updatedAtMillis: 1000000000,
    );

    final updatedThread = existingThread.copyWith(
      title: 'New Title',
      updatedAtMillis: 1234567900,
    );

    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenAnswer((_) async => [updatedThread]);
    when(mockLocalDataSource.getThreadById(updatedThread.id))
        .thenAnswer((_) async => existingThread);
    when(mockLocalDataSource.updateThread(any))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result, const Success(null));
    verify(mockLocalDataSource.updateThread(updatedThread));
    verifyNever(mockLocalDataSource.saveThread(any));
  });

  test('should return NetworkFailure when remote fetch fails due to network', () async {
    // Arrange
    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenThrow(NetworkException('No internet'));

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result.isError, true);
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('should return ServerFailure when remote fetch fails due to server error', () async {
    // Arrange
    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenThrow(ServerException('Server error'));

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result.isError, true);
    expect(result.failureOrNull, isA<ServerFailure>());
  });

  test('should continue processing even if one hard-delete fails', () async {
    // Arrange
    final threads = [
      JournalThreadModel(
        id: 'deleted1',
        userId: testUserId,
        createdAtMillis: 1000000000,
        updatedAtMillis: 1234567900,
        isDeleted: true,
      ),
      JournalThreadModel(
        id: 'deleted2',
        userId: testUserId,
        createdAtMillis: 1000000000,
        updatedAtMillis: 1234567901,
        isDeleted: true,
      ),
    ];

    when(mockLocalDataSource.getLastUpdatedAtMillis(testUserId))
        .thenAnswer((_) async => testTimestamp);
    when(mockRemoteDataSource.getUpdatedThreads(testUserId, testTimestamp))
        .thenAnswer((_) async => threads);
    when(mockLocalDataSource.hardDeleteThreadAndMessages('deleted1'))
        .thenThrow(Exception('Delete failed'));
    when(mockLocalDataSource.hardDeleteThreadAndMessages('deleted2'))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.syncThreadsIncremental(testUserId);

    // Assert
    expect(result, const Success(null));
    verify(mockLocalDataSource.hardDeleteThreadAndMessages('deleted1'));
    verify(mockLocalDataSource.hardDeleteThreadAndMessages('deleted2'));
  });
});
```

#### 3. Generate Mock Files
**Command**: Run mock generation after creating tests

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Success Criteria

#### Automated Verification:
- [ ] All unit tests pass: `flutter test test/features/journal/domain/usecases/sync_threads_usecase_test.dart`
- [ ] All repository tests pass: `flutter test test/features/journal/data/repositories/journal_thread_repository_impl_test.dart`
- [ ] Mock generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Test coverage includes all edge cases

#### Manual Verification:
- [ ] Test output shows all tests passing
- [ ] No test flakiness observed

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 9.

---

## Phase 9: Firestore Configuration

### Overview
Create the required Firestore composite index for efficient incremental queries.

### Changes Required

#### 1. Add Firestore Index
**Manual Step**: Create composite index in Firebase Console

**Index Configuration**:
- **Collection**: `journalThreads`
- **Fields**:
  1. `userId` (Ascending)
  2. `updatedAtMillis` (Ascending)
- **Query Scope**: Collection

**Alternative - Automatic Index Creation**:
Let Firestore auto-generate the index on first query:
1. Run the app and trigger thread sync
2. Check Firestore logs for index creation link
3. Click the link to create the index
4. Wait for index to build (usually 1-2 minutes)

#### 2. Verify Index Creation
**Steps**:
1. Open Firebase Console → Firestore Database → Indexes tab
2. Verify `journalThreads` collection has composite index with `userId` + `updatedAtMillis`
3. Check index status is "Enabled" (not "Building")

### Success Criteria

#### Automated Verification:
- [ ] No Firestore index errors in logs

#### Manual Verification:
- [ ] Index appears in Firebase Console
- [ ] Index status is "Enabled"
- [ ] Query executes without index warnings
- [ ] Query performance is acceptable (< 500ms for 100+ threads)

**Implementation Note**: After completing this phase, proceed to final verification in Phase 10.

---

## Phase 10: Final Integration & Verification

### Overview
Perform end-to-end testing to verify all components work together correctly.

### Integration Test Scenarios

#### Scenario 1: First-Time Sync (Empty Local Database)
**Steps**:
1. Clear app data
2. Log in as user with existing threads
3. Navigate to thread list screen

**Expected**:
- [ ] Sync triggers automatically on screen entry
- [ ] Loading indicator appears briefly
- [ ] All threads from Firestore appear in list
- [ ] Threads are sorted by `lastMessageAtMillis` descending
- [ ] No soft-deleted threads appear

#### Scenario 2: Incremental Sync (Updated Thread)
**Steps**:
1. Open app with existing threads
2. Using another device, update a thread (change title)
3. Pull-to-refresh on thread list

**Expected**:
- [ ] Only the updated thread is fetched from Firestore (check logs)
- [ ] Updated thread title appears in list
- [ ] Other threads remain unchanged

#### Scenario 3: Soft-Delete Handling
**Steps**:
1. Open app with existing threads
2. Using another device, delete a thread
3. Pull-to-refresh on thread list

**Expected**:
- [ ] Deleted thread is removed from local database
- [ ] Deleted thread no longer appears in list
- [ ] Associated messages are also deleted (verify in Isar Inspector)

#### Scenario 4: Connectivity Restore Auto-Sync
**Steps**:
1. Open app with threads
2. Enable airplane mode
3. Using another device, update/delete threads
4. Disable airplane mode

**Expected**:
- [ ] Sync triggers automatically 2 seconds after reconnect
- [ ] Changes from other device sync to local database
- [ ] Success message appears (optional)

#### Scenario 5: Offline Graceful Degradation
**Steps**:
1. Open app with threads
2. Enable airplane mode
3. Pull-to-refresh on thread list

**Expected**:
- [ ] Error message: "No internet connection" or similar
- [ ] Existing threads remain visible
- [ ] No crashes or freezes

#### Scenario 6: Empty Result Handling
**Steps**:
1. Open app with threads
2. Ensure no changes on server
3. Pull-to-refresh multiple times

**Expected**:
- [ ] Sync completes successfully with "No updates" log
- [ ] Success message appears briefly
- [ ] No unnecessary network calls
- [ ] No performance degradation

### Performance Verification

**Metrics to Check**:
- [ ] Sync completes in < 2 seconds for 10 threads
- [ ] Sync completes in < 5 seconds for 100 threads
- [ ] Memory usage remains stable (no leaks)
- [ ] UI remains responsive during sync
- [ ] Database queries execute in < 100ms

### Final Checklist

#### Code Quality:
- [ ] All code follows project conventions
- [ ] No TODO comments left unresolved
- [ ] Logging statements are appropriate (info for success, error for failures)
- [ ] No debug prints remaining

#### Documentation:
- [ ] Method signatures have clear documentation
- [ ] Complex logic has inline comments
- [ ] README updated if necessary

#### Testing:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual testing scenarios verified

#### Deployment Readiness:
- [ ] Firestore index created and enabled
- [ ] No breaking changes to existing features
- [ ] Backward compatible with existing data

---

## Performance Considerations

### Query Optimization
- Firestore composite index on `userId` + `updatedAtMillis` ensures efficient queries
- Local Isar queries filter soft-deleted threads to prevent unnecessary processing
- Timestamp validation prevents invalid DateTime conversions

### Bandwidth Optimization
- Incremental sync reduces payload size by 90%+ after initial sync
- Only changed threads are transmitted
- Soft-deleted threads transmitted once then removed locally

### Memory Management
- Streams properly disposed in UI (connectivity timer, listeners)
- Repository doesn't cache threads in memory (Isar is source of truth)
- Hard-delete immediately frees storage space

### UI Responsiveness
- Sync runs asynchronously without blocking UI
- Auto-reset after 1 second prevents stale loading indicators
- Debounced connectivity sync prevents sync storms

---

## Migration Notes

### Existing Data Compatibility
- No database migrations required (threads already have `updatedAtMillis`)
- Existing threads will sync incrementally on next app launch
- No user action required

### Rollback Plan
If issues arise:
1. Revert controller changes to remove thread sync triggers
2. Revert to full sync method: `syncThreads(userId)`
3. No data loss - all data remains in Firestore and Isar

### Feature Flag (Optional)
Consider adding feature flag for gradual rollout:
```dart
const bool useIncrementalThreadSync = true; // Change to false to disable
```

---

## References

- Original message sync implementation: [journal_message_repository_impl.dart:177-252](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L177-L252)
- Sync controller pattern: [sync_controller.dart](lib/features/journal/presentation/controllers/sync_controller.dart)
- Thread detail screen sync triggers: [thread_detail_screen.dart:46-158](lib/features/journal/presentation/screens/thread_detail_screen.dart#L46-L158)
- Hard delete implementation: [journal_thread_local_datasource.dart:95-111](lib/features/journal/data/datasources/journal_thread_local_datasource.dart#L95-L111)
- Soft delete implementation: [journal_thread_remote_datasource.dart:68-79](lib/features/journal/data/datasources/journal_thread_remote_datasource.dart#L68-L79)
