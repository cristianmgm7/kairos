import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/usecases/sync_thread_messages_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/sync_threads_usecase.dart';

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

// Thread list sync state (separate from individual thread message sync)
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

// Sync controller
class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required this.syncThreadMessagesUseCase,
    required this.syncThreadsUseCase,
  }) : super(const SyncInitial());

  final SyncThreadMessagesUseCase syncThreadMessagesUseCase;
  final SyncThreadsUseCase syncThreadsUseCase;

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

  /// Trigger incremental sync for all threads of a user
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
