import 'dart:async';

import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

class JournalMessageRepositoryImpl implements JournalMessageRepository {
  JournalMessageRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final JournalMessageLocalDataSource localDataSource;
  final JournalMessageRemoteDataSource remoteDataSource;

  @override
  Future<Result<JournalMessageEntity>> createMessage(
    JournalMessageEntity message,
  ) async {
    try {
      final model = JournalMessageModel.fromEntity(message);

      // Always save to local first (guaranteed to succeed)
      await localDataSource.saveMessage(model);

      // Try remote save (best effort)
      try {
        await remoteDataSource.saveMessage(model);
      } on NetworkException catch (e) {
        logger.i('Remote save failed (network), will sync later: $e');
        // Don't fail operation - local save succeeded
      } on ServerException catch (e) {
        logger.i('Remote save failed (server): $e');
        // Don't fail operation - local save succeeded
      }

      // Return entity as-is (status set by use case)
      return Success(message);
    } catch (e) {
      // Only local save errors are actual failures
      return Error(CacheFailure(message: 'Failed to save message locally: $e'));
    }
  }

  @override
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId) async {
    try {
      final localMessage = await localDataSource.getMessageById(messageId);
      return Success(localMessage?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve message: $e'));
    }
  }

  @override
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(
    String threadId,
  ) async* {
    StreamSubscription<List<JournalMessageModel>>? remoteSub;

    try {
      // Always attempt remote sync - no connectivity pre-check
      final since = (await localDataSource.getLastUpdatedAtMillis(threadId)) ?? 0;

      // Listen for remote updates and upsert into local
      remoteSub = remoteDataSource.watchUpdatedMessages(threadId, since).listen(
        (remoteModels) async {
          for (final remoteModel in remoteModels) {
            await localDataSource.upsertFromRemote(remoteModel);
          }
        },
        onError: (Object error) {
          // Network errors are transient - just log and continue
          // The local stream continues to work offline
          logger.i('Remote sync error (will retry when online): $error');
        },
      );

      // Always yield the local stream, updated by remote listener when online
      yield* localDataSource
          .watchMessagesByThreadId(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      await remoteSub?.cancel();
    }
  }

  @override
  Future<Result<void>> updateMessage(JournalMessageEntity message) async {
    try {
      logger.i('updateMessage called for: ${message.id}');
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.updateMessage(model);
      logger.i('Local update completed for: ${message.id}');

      // Always attempt remote update
      try {
        logger.i('Attempting remote update for: ${message.id}');
        await remoteDataSource.updateMessage(model);
        logger.i(
          '✅ Synced message update to Firestore: ${model.id} - storageUrl: ${model.storageUrl}',
        );
      } on NetworkException catch (e) {
        logger.i('⚠️ Network error updating message (will retry later): ${e.message}');
        // Don't fail the whole operation - local update succeeded
      } on ServerException catch (e) {
        logger.i('⚠️ Server error updating message (will retry later): ${e.message}');
        // Don't fail the whole operation - local update succeeded
      }

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to update message: $e'));
    }
  }

  @override
  Future<Result<void>> syncMessages(String threadId) async {
    try {
      final remoteMessages = await remoteDataSource.getMessagesByThreadId(threadId);

      for (final message in remoteMessages) {
        await localDataSource.saveMessage(message);
      }

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync messages: $e'));
    }
  }

  @override
  Future<Result<void>> syncThreadIncremental(String threadId) async {
    try {
      // Get last sync timestamp from local
      final since = (await localDataSource.getLastUpdatedAtMillis(threadId)) ?? 0;

      // Fetch updated messages from remote
      final updatedMessages = await remoteDataSource.getUpdatedMessages(
        threadId,
        since,
      );

      // Upsert all remote messages to local
      for (final remoteModel in updatedMessages) {
        await localDataSource.upsertFromRemote(remoteModel);
      }

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(UnknownFailure(message: 'Sync failed: $e'));
    }
  }

  @override
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(
    String userId,
  ) async {
    try {
      final messages = await localDataSource.getPendingUploads(userId);
      return Success(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(
        CacheFailure(message: 'Failed to query pending uploads: $e'),
      );
    }
  }
}
