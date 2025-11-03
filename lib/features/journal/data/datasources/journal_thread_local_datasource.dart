import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

abstract class JournalThreadLocalDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
  Future<void> archiveThread(String threadId);
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId);
}

class JournalThreadLocalDataSourceImpl implements JournalThreadLocalDataSource {
  JournalThreadLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveThread(JournalThreadModel thread) async {
    await isar.writeTxn(() async {
      await isar.journalThreadModels.put(thread);
    });
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    return isar.journalThreadModels
        .filter()
        .idEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    return isar.journalThreadModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .isArchivedEqualTo(false)
        .findAll();
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    final updated = thread.copyWith(
      updatedAtMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      version: thread.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalThreadModels.put(updated);
    });
  }

  @override
  Future<void> archiveThread(String threadId) async {
    final thread = await getThreadById(threadId);
    if (thread != null) {
      final archived = thread.copyWith(
        isArchived: true,
        updatedAtMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.journalThreadModels.put(archived);
      });
    }
  }

  @override
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId) {
    return isar.journalThreadModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .map((threads) => threads
          ..sort((a, b) {
            final aTime = a.lastMessageAtMillis ?? a.createdAtMillis;
            final bTime = b.lastMessageAtMillis ?? b.createdAtMillis;
            return bTime.compareTo(aTime);
          }));
  }
}
