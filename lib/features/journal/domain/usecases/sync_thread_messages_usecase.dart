import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

class SyncThreadMessagesUseCase {
  SyncThreadMessagesUseCase({required this.messageRepository});

  final JournalMessageRepository messageRepository;

  /// Performs incremental sync for the given thread
  /// Fetches only messages updated since the last local timestamp
  Future<Result<void>> execute(String threadId) async {
    return messageRepository.syncThreadIncremental(threadId);
  }
}
