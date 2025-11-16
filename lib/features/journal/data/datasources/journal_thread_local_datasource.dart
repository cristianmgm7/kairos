import 'package:isar/isar.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

abstract class JournalThreadLocalDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
  Future<void> archiveThread(String threadId);
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId);

  /// Hard-deletes a thread and all its messages from local storage.
  /// This physically removes the data from Isar to free up space.
  Future<void> hardDeleteThreadAndMessages(String threadId);

  /// Gets the most recent updatedAtMillis for threads belonging to a user.
  /// Returns null if no threads exist locally for this user.
  /// Used to determine the starting point for incremental sync.
  Future<int?> getLastUpdatedAtMillis(String userId);

  /// Upserts a thread from remote sync, handling all sync logic:
  /// - If thread.isDeleted is true: hard-deletes the thread and its messages
  /// - Otherwise: upserts the thread, preserving remote timestamps and version
  /// Unlike updateThread(), this does NOT auto-increment version or update timestamps.
  Future<void> upsertFromRemote(JournalThreadModel remote);
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
        .map(
          (threads) => threads
            ..sort((a, b) {
              final aTime = a.lastMessageAtMillis ?? a.createdAtMillis;
              final bTime = b.lastMessageAtMillis ?? b.createdAtMillis;
              return bTime.compareTo(aTime);
            }),
        );
  }

  @override
  Future<void> hardDeleteThreadAndMessages(String threadId) async {
    await isar.writeTxn(() async {
      // Delete the thread
      final thread = await isar.journalThreadModels.filter().idEqualTo(threadId).findFirst();

      if (thread != null) {
        await isar.journalThreadModels.delete(thread.isarId);
      }

      // Delete all messages for this thread
      final messages = await isar.journalMessageModels.filter().threadIdEqualTo(threadId).findAll();

      for (final message in messages) {
        await isar.journalMessageModels.delete(message.isarId);
      }
    });
  }

  @override
  Future<int?> getLastUpdatedAtMillis(String userId) async {
    final threads = await isar.journalThreadModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMillisDesc()
        .findAll();

    if (threads.isEmpty) return null;

    final timestamp = threads.first.updatedAtMillis;

    // Validate timestamp is within valid DateTime range
    const minValid = -8640000000000000;
    const maxValid = 8640000000000000;

    if (timestamp < minValid || timestamp > maxValid) {
      return null; // Return null for invalid timestamps (will trigger full sync)
    }

    return timestamp;
  }

  @override
  Future<void> upsertFromRemote(JournalThreadModel remote) async {
    if (remote.isDeleted) {
      // Hard delete locally when remote is soft-deleted
      await hardDeleteThreadAndMessages(remote.id);
      logger.i('✅ Hard-deleted thread ${remote.id} and its messages');
    } else {
      // Upsert active thread to local database
      await isar.writeTxn(() async {
        await isar.journalThreadModels.put(remote);
      });
      logger.i('💾 Upserted thread from remote: ${remote.id}');
    }
  }
}
