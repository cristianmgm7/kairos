import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:logger/logger.dart';

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
      await localDataSource.saveMessage(model);

      // Always attempt remote save - no connectivity pre-check
      try {
        await remoteDataSource.saveMessage(model);

        // Mark text messages and non-user messages as completed
        if (message.messageType == MessageType.text || message.role != MessageRole.user) {
          final synced = model.copyWith(uploadStatus: UploadStatus.completed.index);
          await localDataSource.updateMessage(synced);
        }

        return Success(model.toEntity());
      } on NetworkException catch (e) {
        Logger().e('Network error during message creation', error: e.message);

        // Handle network failure based on message type
        if (message.role == MessageRole.user) {
          if (message.messageType != MessageType.text) {
            // Media messages: mark as failed (shows Retry button)
            final failed = model.copyWith(
              uploadStatus: UploadStatus.failed.index,
              uploadRetryCount: model.uploadRetryCount + 1,
              lastUploadAttemptMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
            );
            await localDataSource.updateMessage(failed);
            return Error(NetworkFailure(message: e.message));
          } else {
            // Text messages: mark as notStarted (shows "Waiting to upload")
            final pending = model.copyWith(
              uploadStatus: UploadStatus.notStarted.index,
            );
            await localDataSource.updateMessage(pending);
            return Success(pending.toEntity());
          }
        }

        // Non-user messages (AI responses): return error
        return Error(NetworkFailure(message: e.message));
      } on ServerException catch (e) {
        Logger().e('Server error during message creation', error: e.message);

        // Mark message as failed for retry
        final failed = model.copyWith(
          uploadStatus: UploadStatus.failed.index,
          uploadRetryCount: model.uploadRetryCount + 1,
          lastUploadAttemptMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        );
        await localDataSource.updateMessage(failed);
        return Error(ServerFailure(message: e.message));
      }
    } catch (e) {
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
          debugPrint('Remote sync error (will retry when online): $error');
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
      debugPrint('updateMessage called for: ${message.id}');
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.updateMessage(model);
      debugPrint('Local update completed for: ${message.id}');

      // Always attempt remote update
      try {
        debugPrint('Attempting remote update for: ${message.id}');
        await remoteDataSource.updateMessage(model);
        debugPrint(
          '✅ Synced message update to Firestore: ${model.id} - storageUrl: ${model.storageUrl}',
        );
      } on NetworkException catch (e) {
        debugPrint('⚠️ Network error updating message (will retry later): ${e.message}');
        // Don't fail the whole operation - local update succeeded
      } on ServerException catch (e) {
        debugPrint('⚠️ Server error updating message (will retry later): ${e.message}');
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
      // Get the latest updatedAtMillis from local DB
      final lastUpdatedAtMillis = await localDataSource.getLastUpdatedAtMillis(threadId);

      // If no messages exist locally, use 0 to fetch all messages
      final sinceTimestamp = lastUpdatedAtMillis ?? 0;

      debugPrint(
        '🔄 Incremental sync for thread $threadId since timestamp: $sinceTimestamp',
      );

      // Always attempt to fetch updated messages
      final updatedMessages = await remoteDataSource.getUpdatedMessages(
        threadId,
        sinceTimestamp,
      );

      debugPrint('📥 Fetched ${updatedMessages.length} updated messages');

      if (updatedMessages.isEmpty) {
        debugPrint('✅ No new messages to sync');
        return const Success(null);
      }

      // Merge updated messages into local DB
      for (final message in updatedMessages) {
        final existingMessage = await localDataSource.getMessageById(message.id);

        if (existingMessage != null) {
          // Message exists locally - merge remote updates with local-only fields
          final isNonUser = message.role != MessageRole.user.index;
          final isText = message.messageType == MessageType.text.index;

          final int uploadStatusToUse;
          if (isNonUser || isText) {
            uploadStatusToUse = UploadStatus.completed.index;
          } else if (message.uploadStatus > existingMessage.uploadStatus) {
            uploadStatusToUse = message.uploadStatus;
          } else {
            uploadStatusToUse = existingMessage.uploadStatus;
          }

          final mergedModel = message.copyWith(
            uploadStatus: uploadStatusToUse,
            uploadRetryCount: existingMessage.uploadRetryCount,
            localFilePath: existingMessage.localFilePath,
            localThumbnailPath: existingMessage.localThumbnailPath,
            audioDurationSeconds: existingMessage.audioDurationSeconds,
          );

          await localDataSource.updateMessage(mergedModel);
          debugPrint('📝 Updated message: ${message.id}');
        } else {
          // New message from remote (e.g., AI response)
          final normalized = message.copyWith(
            uploadStatus: UploadStatus.completed.index,
          );
          await localDataSource.saveMessage(normalized);
          debugPrint('✨ Added new message: ${message.id}');
        }
      }

      debugPrint('✅ Incremental sync completed successfully');
      return const Success(null);
    } on NetworkException catch (e) {
      debugPrint('❌ Network error during incremental sync: ${e.message}');
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      debugPrint('❌ Server error during incremental sync: ${e.message}');
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      debugPrint('❌ Incremental sync failed: $e');
      return Error(ServerFailure(message: 'Failed to sync messages: $e'));
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
