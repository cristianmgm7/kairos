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
  /// Returns Success if the thread was deleted successfully.
  /// Returns Error with NetworkFailure if the device is offline.
  /// Returns Error with ServerFailure if the remote deletion fails.
  Future<Result<void>> call(String threadId) async {
    return threadRepository.deleteThread(threadId);
  }
}
