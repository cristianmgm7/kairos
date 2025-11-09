import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

abstract class JournalMessageRepository {
  Future<Result<JournalMessageEntity>> createMessage(
      JournalMessageEntity message);
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId);
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId);
  Future<Result<void>> updateMessage(JournalMessageEntity message);
  Future<Result<void>> syncMessages(String threadId);
  Future<Result<void>> syncThreadIncremental(String threadId);
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(String userId);
}
