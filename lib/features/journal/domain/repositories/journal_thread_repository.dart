import 'package:kairos/core/errors/failures.dart' show NetworkFailure, ServerFailure;
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';

abstract class JournalThreadRepository {
  Future<Result<JournalThreadEntity>> createThread(JournalThreadEntity thread);
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId);
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId);
  Future<Result<void>> updateThread(JournalThreadEntity thread);
  Future<Result<void>> archiveThread(String threadId);
  Future<Result<void>> syncThreads(String userId);

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
