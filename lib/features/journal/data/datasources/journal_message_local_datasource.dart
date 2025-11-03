import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

abstract class JournalMessageLocalDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getPendingUploads(String userId);
}

class JournalMessageLocalDataSourceImpl
    implements JournalMessageLocalDataSource {
  JournalMessageLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    await isar.writeTxn(() async {
      await isar.journalMessageModels.put(message);
    });
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    return isar.journalMessageModels
        .filter()
        .idEqualTo(messageId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(
      String threadId) async {
    return isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByCreatedAtMillis()
        .findAll();
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    final updated = message.copyWith(
      version: message.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalMessageModels.put(updated);
    });
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId) {
    return isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((messages) => messages
          ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis)));
  }

  @override
  Future<List<JournalMessageModel>> getPendingUploads(String userId) async {
    return isar.journalMessageModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .roleEqualTo(0) // user messages only
        .and()
        .group((q) => q
            .uploadStatusEqualTo(0) // notStarted
            .or()
            .uploadStatusEqualTo(3)) // failed
        .findAll();
  }
}
