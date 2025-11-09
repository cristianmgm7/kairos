import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

abstract class JournalMessageLocalDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<int?> getLastUpdatedAtMillis(String threadId);
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getPendingUploads(String userId);
  Future<void> upsertFromRemote(JournalMessageModel remote);
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
    String threadId,
  ) async {
    return isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByCreatedAtMillis()
        .findAll();
  }

  @override
  Future<int?> getLastUpdatedAtMillis(String threadId) async {
    final messages = await isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMillisDesc()
        .findAll();

    if (messages.isEmpty) return null;
    return messages.first.updatedAtMillis;
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
        .map(
          (messages) => messages
            ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis)),
        );
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
        .group(
          (q) => q
              .uploadStatusEqualTo(0) // notStarted
              .or()
              .uploadStatusEqualTo(3),
        ) // failed
        .findAll();
  }

  @override
  Future<void> upsertFromRemote(JournalMessageModel remote) async {
    final existing = await getMessageById(remote.id);
    if (existing == null) {
      final isNonUser = remote.role != MessageRole.user.index;
      final isText = remote.messageType == MessageType.text.index;
      final normalized = remote.copyWith(
        uploadStatus: (isNonUser || isText)
            ? UploadStatus.completed.index
            : (remote.uploadStatus),
      );
      await saveMessage(normalized);
      return;
    }

    final isNonUser = remote.role != MessageRole.user.index;
    final isText = remote.messageType == MessageType.text.index;
    final int uploadStatusToUse;
    if (isNonUser || isText) {
      uploadStatusToUse = UploadStatus.completed.index;
    } else if (remote.uploadStatus > existing.uploadStatus) {
      uploadStatusToUse = remote.uploadStatus;
    } else {
      uploadStatusToUse = existing.uploadStatus;
    }

    final merged = remote.copyWith(
      uploadStatus: uploadStatusToUse,
      uploadRetryCount: existing.uploadRetryCount,
      localFilePath: existing.localFilePath,
      localThumbnailPath: existing.localThumbnailPath,
      audioDurationSeconds: existing.audioDurationSeconds,
    );
    await updateMessage(merged);
  }
}
