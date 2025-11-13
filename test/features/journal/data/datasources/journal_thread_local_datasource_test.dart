import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

void main() {
  late Isar isar;
  late JournalThreadLocalDataSourceImpl dataSource;

  setUp(() async {
    // Initialize Isar for testing with both thread and message schemas
    isar = await Isar.open(
      [JournalThreadModelSchema, JournalMessageModelSchema],
      directory: '',
      name: 'test_threads_${DateTime.now().millisecondsSinceEpoch}',
    );
    dataSource = JournalThreadLocalDataSourceImpl(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('upsertFromRemote', () {
    test('should insert new thread from remote', () async {
      // Arrange
      final remoteThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Remote Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 2000,
        version: 5,
      );

      // Act
      await dataSource.upsertFromRemote(remoteThread);

      // Assert
      final saved = await dataSource.getThreadById('thread-1');
      expect(saved, isNotNull);
      expect(saved!.title, 'Remote Thread');
      expect(saved.updatedAtMillis, 2000); // Remote timestamp preserved
      expect(saved.version, 5); // Remote version preserved
    });

    test('should update existing thread with remote data', () async {
      // Arrange
      final localThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Local Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 1500,
        version: 3,
      );
      await dataSource.saveThread(localThread);

      final remoteThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Updated Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 2000,
        version: 6,
      );

      // Act
      await dataSource.upsertFromRemote(remoteThread);

      // Assert
      final updated = await dataSource.getThreadById('thread-1');
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Thread'); // Remote title
      expect(updated.updatedAtMillis, 2000); // Remote timestamp preserved
      expect(updated.version, 6); // Remote version preserved (not incremented)
    });

    test('should preserve exact remote timestamps unlike updateThread', () async {
      // Arrange
      final existingThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Old Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 1500,
        version: 2,
      );
      await dataSource.saveThread(existingThread);

      const remoteTimestamp = 3000;
      final remoteThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Remote Thread',
        createdAtMillis: 1000,
        updatedAtMillis: remoteTimestamp,
        version: 4,
      );

      // Act
      await dataSource.upsertFromRemote(remoteThread);

      // Assert
      final updated = await dataSource.getThreadById('thread-1');
      expect(updated!.updatedAtMillis, remoteTimestamp);
      expect(updated.version, 4); // Not incremented to 5
    });

    test('should hard-delete thread when isDeleted is true', () async {
      // Arrange
      final localThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Local Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 1500,
        version: 3,
      );
      await dataSource.saveThread(localThread);

      final deletedThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Deleted Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 2000,
        version: 4,
        isDeleted: true,
        deletedAtMillis: 2000,
      );

      // Act
      await dataSource.upsertFromRemote(deletedThread);

      // Assert
      final deleted = await dataSource.getThreadById('thread-1');
      expect(deleted, isNull); // Thread should be gone
    });

    test('should hard-delete thread and its messages when isDeleted is true', () async {
      // Arrange
      final localThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Local Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 1500,
        version: 3,
      );
      await dataSource.saveThread(localThread);

      // Add some messages to the thread
      final message1 = JournalMessageModel(
        id: 'msg-1',
        threadId: 'thread-1',
        userId: 'user-1',
        role: 0, // user
        messageType: 0, // text
        content: 'Test message 1',
        createdAtMillis: 1100,
        updatedAtMillis: 1100,
        status: 3, // sent
      );
      final message2 = JournalMessageModel(
        id: 'msg-2',
        threadId: 'thread-1',
        userId: 'user-1',
        role: 1, // assistant
        messageType: 0, // text
        content: 'Test message 2',
        createdAtMillis: 1200,
        updatedAtMillis: 1200,
        status: 3, // sent
      );
      await isar.writeTxn(() async {
        await isar.journalMessageModels.putAll([message1, message2]);
      });

      final deletedThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Deleted Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 2000,
        version: 4,
        isDeleted: true,
        deletedAtMillis: 2000,
      );

      // Act
      await dataSource.upsertFromRemote(deletedThread);

      // Assert
      final deletedThreadResult = await dataSource.getThreadById('thread-1');
      expect(deletedThreadResult, isNull); // Thread should be gone

      // Messages should also be deleted
      final messages = await isar.journalMessageModels
          .filter()
          .threadIdEqualTo('thread-1')
          .findAll();
      expect(messages, isEmpty); // All messages should be gone
    });

    test('should not create thread when isDeleted is true and thread does not exist', () async {
      // Arrange
      final deletedThread = JournalThreadModel(
        id: 'thread-1',
        userId: 'user-1',
        title: 'Deleted Thread',
        createdAtMillis: 1000,
        updatedAtMillis: 2000,
        version: 4,
        isDeleted: true,
        deletedAtMillis: 2000,
      );

      // Act
      await dataSource.upsertFromRemote(deletedThread);

      // Assert
      final result = await dataSource.getThreadById('thread-1');
      expect(result, isNull); // Thread should not be created
    });
  });
}
