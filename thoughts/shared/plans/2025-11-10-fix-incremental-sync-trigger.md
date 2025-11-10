# Fix Incremental Sync Trigger Error - Implementation Plan

## Overview

Fix the `ref.listen` assertion error when trying to trigger incremental sync based on connectivity changes. The current implementation tries to use `ref.listen` in `initState()` which violates Riverpod's rules.

## Current State Analysis

### The Problem

**Error**: `_AssertionError: 'package:flutter_riverpod/src/consumer.dart': Failed assertion: line 600 pos 7: 'debugDoingBuild': ref.listen can only be used within the build method of a ConsumerWidget`

**Location**: `thread_detail_screen.dart` lines 46-70

**Root Cause**: 
- `ref.listen` is being called in `initState()` (wrapped in `Future.microtask()`)
- Even with `Future.microtask()`, this still executes outside the build method
- Riverpod requires `ref.listen` to be called within the build method to ensure proper lifecycle management

### Current Architecture

**Two Sync Mechanisms**:
1. **Real-time sync** (automatic): `watchMessagesByThreadId` in repository automatically syncs when online
2. **Incremental sync** (manual): `syncThreadIncremental` for catch-up after offline periods

**Current Sync Triggers**:
- Manual pull-to-refresh: `_handleRefresh()` (line 108)
- Attempted auto-sync on reconnect: `_performIncrementalSync()` (line 92) - **BROKEN**

### Key Discoveries

From codebase analysis:
- All working `ref.listen` calls are in the build method:
  - `login_screen.dart:49`
  - `thread_detail_screen.dart:167` (message controller listener)
  - `thread_detail_screen.dart:195` (AI processing listener)
- No other screens attempt to listen in `initState()`
- Pattern established: State management controllers (`MessageController`, `ThreadController`) handle business logic

## What We're NOT Doing

- Not changing the repository sync implementation (working correctly)
- Not modifying the existing real-time sync mechanism
- Not removing the manual pull-to-refresh feature
- Not changing how messages are displayed/streamed

## Implementation Options

Choose ONE of the following approaches based on your architectural preferences:

---

## Option 1: Move ref.listen to Build Method (RECOMMENDED - Simplest)

### Overview
Follow Riverpod best practices by moving the connectivity listener to the build method where it belongs.

### Pros
- ✅ Follows Riverpod patterns used elsewhere in codebase
- ✅ Minimal code changes
- ✅ No new files/providers needed
- ✅ Consistent with existing listeners in the same screen

### Cons
- ⚠️ Listener executes on every rebuild (though Riverpod optimizes this)
- ⚠️ State tracking (_wasOffline, _syncDebounceTimer) remains in widget

### Changes Required

#### File: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Change 1**: Remove connectivity listener from `initState()`

```dart
@override
void initState() {
  super.initState();
  _currentThreadId = widget.threadId;
  
  // REMOVED: connectivity listener (moved to build method)
}
```

**Change 2**: Add connectivity listener to `build()` method

```dart
@override
Widget build(BuildContext context) {
  // Watch connectivity for auto-sync on reconnect
  ref.listen<AsyncValue<bool>>(
    connectivityStreamProvider,
    (previous, next) {
      next.whenData((isOnline) {
        // Detect transition from offline to online
        if (_wasOffline && isOnline && _currentThreadId != null) {
          debugPrint('🌐 Device reconnected - scheduling incremental sync');

          // Cancel any pending sync timer
          _syncDebounceTimer?.cancel();

          // Debounce sync by 2 seconds after reconnection
          _syncDebounceTimer = Timer(const Duration(seconds: 2), () {
            debugPrint('🔄 Triggering auto-sync for thread: $_currentThreadId');
            _performIncrementalSync();
          });
        }

        // Update offline tracking state
        _wasOffline = !isOnline;
      });
    },
  );

  // ... rest of build method (existing code)
  final messagesAsync = _currentThreadId != null
      ? ref.watch(messagesStreamProvider(_currentThreadId!))
      : const AsyncValue<List<JournalMessageEntity>>.data([]);
  
  // ... continue with existing build code
}
```

### Success Criteria

#### Automated Verification:
- [ ] App runs without assertion errors: `flutter run`
- [ ] No linter errors: `flutter analyze`
- [ ] Widget tests pass (if any exist): `flutter test`

#### Manual Verification:
- [ ] Open thread detail screen - no errors appear
- [ ] Turn off device wifi/airplane mode
- [ ] Turn on device wifi/airplane mode
- [ ] Verify sync triggers after 2 seconds (check debug logs for "🔄 Triggering auto-sync")
- [ ] Verify messages sync correctly after reconnection
- [ ] Pull-to-refresh still works
- [ ] No performance degradation when scrolling messages

---

## Option 2: Create Sync Controller (Clean Architecture)

### Overview
Create a proper controller to manage sync state and operations, following the pattern of `MessageController` and `ThreadController`.

### Pros
- ✅ Clean separation of concerns
- ✅ Testable sync logic
- ✅ Can handle multiple sync triggers (reconnect, app resume, manual)
- ✅ Follows established controller pattern in your codebase
- ✅ Easier to add features like sync status UI, retry logic, etc.

### Cons
- ⚠️ More files to maintain
- ⚠️ Slightly more complex setup

### Phase 1: Create Sync Controller

#### File: `lib/features/journal/presentation/controllers/sync_controller.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/journal/domain/usecases/sync_thread_messages_usecase.dart';

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

// Sync controller
class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required this.syncThreadMessagesUseCase,
  }) : super(const SyncInitial());

  final SyncThreadMessagesUseCase syncThreadMessagesUseCase;

  /// Trigger incremental sync for a thread
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

### Phase 2: Add Sync Controller Provider

#### File: `lib/features/journal/presentation/providers/journal_providers.dart`

**Add import**:

```dart
import 'package:kairos/features/journal/presentation/controllers/sync_controller.dart';
```

**Add provider** (after line 162):

```dart
final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  final syncThreadMessagesUseCase = ref.watch(syncThreadMessagesUseCaseProvider);
  return SyncController(syncThreadMessagesUseCase: syncThreadMessagesUseCase);
});
```

### Phase 3: Update Thread Detail Screen

#### File: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Change 1**: Remove sync-related state from widget

```dart
class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentThreadId;

  // REMOVED: Timer? _syncDebounceTimer;
  bool _wasOffline = false;
  
  // Add debounce timer for connectivity-triggered sync
  Timer? _connectivitySyncTimer;

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.threadId;
    
    // Trigger initial sync on screen entry if we have a threadId
    if (_currentThreadId != null) {
      Future.microtask(() {
        ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _connectivitySyncTimer?.cancel();
    super.dispose();
  }
```

**Change 2**: Replace `_performIncrementalSync()` with controller call

```dart
// REMOVE the _performIncrementalSync method entirely
```

**Change 3**: Update connectivity listener in build method

```dart
@override
Widget build(BuildContext context) {
  // Listen for connectivity changes (auto-sync on reconnect)
  ref.listen<AsyncValue<bool>>(
    connectivityStreamProvider,
    (previous, next) {
      next.whenData((isOnline) {
        // Detect transition from offline to online
        if (_wasOffline && isOnline && _currentThreadId != null) {
          debugPrint('🌐 Device reconnected - scheduling incremental sync');

          // Cancel any pending sync timer
          _connectivitySyncTimer?.cancel();

          // Debounce sync by 2 seconds after reconnection
          _connectivitySyncTimer = Timer(const Duration(seconds: 2), () {
            debugPrint('🔄 Triggering auto-sync for thread: $_currentThreadId');
            ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);
          });
        }

        // Update offline tracking state
        _wasOffline = !isOnline;
      });
    },
  );

  // Listen to sync controller state (optional - for UI feedback)
  ref.listen<SyncState>(syncControllerProvider, (previous, next) {
    if (next is SyncError && mounted) {
      debugPrint('❌ Background sync failed: ${next.message}');
      // Optionally show a subtle snackbar or notification
    } else if (next is SyncSuccess) {
      debugPrint('✅ Background sync completed successfully');
    }
  });

  // ... rest of build method
  final messagesAsync = _currentThreadId != null
      ? ref.watch(messagesStreamProvider(_currentThreadId!))
      : const AsyncValue<List<JournalMessageEntity>>.data([]);
  
  // ... continue with existing build code
}
```

**Change 4**: Update `_handleRefresh()` to use controller

```dart
Future<void> _handleRefresh() async {
  if (_currentThreadId == null) return;

  debugPrint('🔄 Manual refresh triggered for thread: $_currentThreadId');

  await ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);

  // Show feedback based on sync state
  if (mounted) {
    final syncState = ref.read(syncControllerProvider);
    if (syncState is SyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${syncState.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (syncState is SyncSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messages synced successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] App runs without assertion errors: `flutter run`
- [ ] No linter errors: `flutter analyze`
- [ ] Controller logic can be unit tested: create `test/features/journal/presentation/controllers/sync_controller_test.dart`
- [ ] Widget tests pass (if any exist): `flutter test`

#### Manual Verification:
- [ ] Open thread detail screen - initial sync triggers automatically
- [ ] Turn off device wifi/airplane mode
- [ ] Turn on device wifi/airplane mode
- [ ] Verify sync triggers after 2 seconds (check debug logs)
- [ ] Verify messages sync correctly after reconnection
- [ ] Pull-to-refresh shows success message
- [ ] Pull-to-refresh shows error message when offline
- [ ] Multiple rapid connectivity changes don't cause multiple simultaneous syncs
- [ ] No performance degradation

---

## Option 3: Simple Sync on Screen Entry (Minimal)

### Overview
Remove the connectivity listener entirely and just trigger a sync once when entering the screen. Rely on the built-in real-time sync for ongoing updates.

### Pros
- ✅ Simplest implementation
- ✅ Minimal code
- ✅ No connectivity tracking needed
- ✅ Relies on already-working real-time sync

### Cons
- ⚠️ No auto-sync when coming back online
- ⚠️ User must manually refresh after offline period
- ⚠️ Less automatic than other options

### Changes Required

#### File: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Change 1**: Simplify state and initState

```dart
class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentThreadId;

  // REMOVED: _syncDebounceTimer, _wasOffline

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.threadId;
    
    // Trigger sync on screen entry (no ref.listen needed)
    if (_currentThreadId != null) {
      _performIncrementalSync();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performIncrementalSync() {
    if (_currentThreadId == null) return;

    final syncUseCase = ref.read(syncThreadMessagesUseCaseProvider);
    syncUseCase.execute(_currentThreadId!).then((result) {
      result.when(
        success: (_) {
          debugPrint('✅ Sync completed successfully');
        },
        error: (failure) {
          debugPrint('❌ Sync failed: ${failure.message}');
          // Fail silently - real-time sync will handle it when online
        },
      );
    });
  }

  // Keep _handleRefresh as-is (no changes needed)

  // ... rest of the class unchanged
}
```

**Change 2**: Remove connectivity listener section entirely from build method (if it exists)

### Success Criteria

#### Automated Verification:
- [ ] App runs without assertion errors: `flutter run`
- [ ] No linter errors: `flutter analyze`
- [ ] Widget tests pass (if any exist): `flutter test`

#### Manual Verification:
- [ ] Open thread detail screen - sync triggers once on entry
- [ ] Pull-to-refresh still works
- [ ] Real-time sync continues to work when online (messages appear automatically)
- [ ] Offline -> online: messages sync when user manually refreshes
- [ ] No errors when opening screen while offline

---

## Recommendation

**Choose Option 1** for quick fix and consistency with existing Riverpod patterns in your codebase.

**Choose Option 2** if you want clean architecture and plan to add more sync features (status indicators, retry logic, background sync service, etc.) in the future.

**Choose Option 3** if you want minimal code and are okay relying on manual refresh after offline periods.

## Testing Strategy

### Unit Tests (Option 2 only)

Create `test/features/journal/presentation/controllers/sync_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/usecases/sync_thread_messages_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/sync_controller.dart';

class MockSyncThreadMessagesUseCase extends Mock implements SyncThreadMessagesUseCase {}

void main() {
  late SyncController controller;
  late MockSyncThreadMessagesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockSyncThreadMessagesUseCase();
    controller = SyncController(syncThreadMessagesUseCase: mockUseCase);
  });

  group('SyncController', () {
    test('initial state is SyncInitial', () {
      expect(controller.state, isA<SyncInitial>());
    });

    test('syncThread emits SyncInProgress then SyncSuccess on success', () async {
      const threadId = 'test-thread-id';
      when(() => mockUseCase.execute(threadId))
          .thenAnswer((_) async => const Success(null));

      final states = <SyncState>[];
      controller.addListener((state) => states.add(state));

      await controller.syncThread(threadId);

      expect(states, [
        isA<SyncInProgress>(),
        isA<SyncSuccess>(),
      ]);
    });

    test('syncThread emits SyncError on failure', () async {
      const threadId = 'test-thread-id';
      when(() => mockUseCase.execute(threadId))
          .thenAnswer((_) async => const Error(NetworkFailure(message: 'No connection')));

      final states = <SyncState>[];
      controller.addListener((state) => states.add(state));

      await controller.syncThread(threadId);

      expect(states, [
        isA<SyncInProgress>(),
        isA<SyncError>(),
      ]);
    });

    test('does not trigger sync if already syncing same thread', () async {
      const threadId = 'test-thread-id';
      when(() => mockUseCase.execute(threadId))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success(null);
      });

      // Trigger two syncs rapidly
      final future1 = controller.syncThread(threadId);
      final future2 = controller.syncThread(threadId); // Should be ignored

      await Future.wait([future1, future2]);

      // Should only call once
      verify(() => mockUseCase.execute(threadId)).called(1);
    });
  });
}
```

### Integration Tests

Test sync behavior in context:

1. **Connectivity Changes**:
   - Simulate offline -> online transition
   - Verify sync triggers with debounce
   - Verify messages appear after sync

2. **Manual Refresh**:
   - Test pull-to-refresh gesture
   - Verify sync executes
   - Verify UI feedback appears

3. **Screen Navigation**:
   - Open thread screen while offline
   - Verify no crashes
   - Come back online
   - Verify sync triggers (Options 1 & 2 only)

### Manual Testing Checklist

- [ ] Start app while online - open thread
- [ ] Start app while offline - open thread
- [ ] Open thread -> turn off wifi -> turn on wifi
- [ ] Open thread -> background app -> return (verify still works)
- [ ] Open thread -> trigger sync -> close screen quickly (verify cleanup)
- [ ] Multiple rapid connectivity changes (verify debounce works)
- [ ] Very slow connection (verify timeout handling)
- [ ] Open thread -> manually refresh -> turn off wifi mid-refresh

## Performance Considerations

1. **Debounce Timer**: 2-second debounce prevents rapid repeated syncs
2. **Duplicate Sync Prevention**: Repository checks timestamps to avoid re-fetching unchanged messages
3. **Cancellation**: Timer cancelled on dispose to prevent memory leaks
4. **State Management**: Controllers auto-reset to prevent stale state

## Migration Notes

- No database migration needed
- No API changes
- Users will see improved sync behavior immediately
- No breaking changes to existing functionality

## References

- Current issue: `thread_detail_screen.dart:46-70`
- Incremental sync implementation: `journal_message_repository_impl.dart:177-251`
- Real-time sync implementation: `journal_message_repository_impl.dart:96-127`
- Sync use case: `sync_thread_messages_usecase.dart:4-14`
- Similar controller pattern: `message_controller.dart`, `thread_controller.dart`
- Working ref.listen examples: `login_screen.dart:49`, `thread_list_screen.dart:27`

