import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';

abstract class JournalThreadRepository {
  Future<Result<JournalThreadEntity>> createThread(JournalThreadEntity thread);
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId);
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId);
  Future<Result<void>> updateThread(JournalThreadEntity thread);
  Future<Result<void>> archiveThread(String threadId);
  Future<Result<void>> syncThreads(String userId);
}
