import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';

abstract class JournalEntryLocalDataSource {
  Future<void> saveEntry(JournalEntryModel entry);
  Future<JournalEntryModel?> getEntryById(String entryId);
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
  Stream<List<JournalEntryModel>> watchEntriesByUserId(String userId);
  Future<List<JournalEntryModel>> getPendingUploads(String userId);
}

class JournalEntryLocalDataSourceImpl implements JournalEntryLocalDataSource {
  JournalEntryLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveEntry(JournalEntryModel entry) async {
    await isar.writeTxn(() async {
      await isar.journalEntryModels.put(entry);
    });
  }

  @override
  Future<JournalEntryModel?> getEntryById(String entryId) async {
    return isar.journalEntryModels
        .filter()
        .idEqualTo(entryId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId) async {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .sortByCreatedAtMillisDesc()
        .findAll();
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    final updated = entry.copyWith(
      modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      version: entry.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalEntryModels.put(updated);
    });
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    final entry = await getEntryById(entryId);
    if (entry != null) {
      final deleted = entry.copyWith(
        isDeleted: true,
        modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.journalEntryModels.put(deleted);
      });
    }
  }

  @override
  Stream<List<JournalEntryModel>> watchEntriesByUserId(String userId) {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((entries) => entries
          ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis)));
  }

  @override
  Future<List<JournalEntryModel>> getPendingUploads(String userId) async {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .group(
          (q) => q
              .uploadStatusEqualTo(0) // notStarted
              .or()
              .uploadStatusEqualTo(3), // failed
        )
        .findAll();
  }
}
