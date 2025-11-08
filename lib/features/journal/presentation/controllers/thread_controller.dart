import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
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

    result.when<void>(
      success: (void _) {
        state = const ThreadDeleteSuccess();
      },
      error: (Failure failure) {
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
