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
