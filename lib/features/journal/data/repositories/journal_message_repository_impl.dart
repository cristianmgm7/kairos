import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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
    required this.connectivity,
  });

  final JournalMessageLocalDataSource localDataSource;
  final JournalMessageRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalMessageEntity>> createMessage(
      JournalMessageEntity message) async {
    try {
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.saveMessage(model);

      // Ensure a remote document exists for all messages.
      // For text and non-user messages, also mark upload as completed locally.
      if (await _isOnline) {
        try {
          await remoteDataSource.saveMessage(model);
          if (message.messageType == MessageType.text ||
              message.role != MessageRole.user) {
            final synced = model.copyWith(uploadStatus: 2); // completed
            await localDataSource.updateMessage(synced);
          }
        } catch (e) {
          Logger()
              .e('Error log', error: 'Failed to sync message to remote: $e');
          // Mark message as failed locally to enable retry
          final failed = model.copyWith(
            uploadStatus: UploadStatus.failed.index, // 3
            uploadRetryCount: model.uploadRetryCount + 1,
            lastUploadAttemptMillis:
                DateTime.now().toUtc().millisecondsSinceEpoch,
          );
          await localDataSource.updateMessage(failed);
          return Error(
              CacheFailure(message: 'Failed to sync message to remote: $e'));
        }
      } else {
        // Offline feedback:
        // - Media user messages -> failed (shows Retry)
        // - Text user messages -> notStarted (shows "Waiting to upload")
        if (message.role == MessageRole.user) {
          if (message.messageType != MessageType.text) {
            final failed = model.copyWith(
              uploadStatus: UploadStatus.failed.index, // 3
            );
            await localDataSource.updateMessage(failed);
            return Success(failed.toEntity());
          } else {
            final pending = model.copyWith(
              uploadStatus: UploadStatus.notStarted.index, // 0
            );
            await localDataSource.updateMessage(pending);
            return Success(pending.toEntity());
          }
        }
      }

      return Success(model.toEntity());
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
      String threadId) async* {
    // Check if online
    final isOnline = await _isOnline;

    if (!isOnline) {
      // Offline: just watch local DB
      yield* localDataSource
          .watchMessagesByThreadId(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }

    // Get userId from local messages (needed for Firestore query)
    final localMessages = await localDataSource.getMessagesByThreadId(threadId);
    if (localMessages.isEmpty) {
      // No messages yet, just watch local
      yield* localDataSource
          .watchMessagesByThreadId(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }
    final userId = localMessages.first.userId;

    // Online: Set up bidirectional sync between Firestore and local DB
    StreamSubscription<List<JournalMessageModel>>? remoteSub;

    try {
      // Listen to Firestore and sync to local DB in background
      remoteSub =
          remoteDataSource.watchMessagesByThreadId(threadId, userId).listen(
        (remoteModels) async {
          // Get current local messages to compare
          final localMessages =
              await localDataSource.getMessagesByThreadId(threadId);
          final localIds = localMessages.map((m) => m.id).toSet();

          for (final remoteModel in remoteModels) {
            if (!localIds.contains(remoteModel.id)) {
              // New message from remote (e.g., AI response)
              // Ensure remote-created messages are marked as completed locally to avoid "waiting to upload"
              final normalized = remoteModel.copyWith(
                uploadStatus: UploadStatus.completed.index,
              );
              await localDataSource.saveMessage(normalized);
              debugPrint('Synced new AI message: ${remoteModel.id}');
            } else {
              // Check if we need to update (e.g., processing status, transcription, or storageUrl changed)
              final localModel =
                  await localDataSource.getMessageById(remoteModel.id);
              if (localModel != null) {
                final needsUpdate = localModel.aiProcessingStatus !=
                        remoteModel.aiProcessingStatus ||
                    localModel.transcription != remoteModel.transcription ||
                    localModel.storageUrl != remoteModel.storageUrl;

                if (needsUpdate) {
                  // Merge: preserve local-only fields (uploadStatus, localFilePath, etc.)
                  // For non-user or text messages, force uploadStatus to completed
                  // For user messages with media, use remote uploadStatus if it's more advanced
                  final isNonUser = remoteModel.role != MessageRole.user.index;
                  final isText =
                      remoteModel.messageType == MessageType.text.index;
                  final int uploadStatusToUse;
                  if (isNonUser || isText) {
                    uploadStatusToUse = UploadStatus.completed.index;
                  } else if (remoteModel.uploadStatus >
                      localModel.uploadStatus) {
                    // Use remote status if it's more advanced (e.g., remote is COMPLETED, local is UPLOADING)
                    uploadStatusToUse = remoteModel.uploadStatus;
                  } else {
                    uploadStatusToUse = localModel.uploadStatus;
                  }

                  final mergedModel = remoteModel.copyWith(
                    uploadStatus: uploadStatusToUse,
                    uploadRetryCount: localModel.uploadRetryCount,
                    localFilePath: localModel.localFilePath,
                    localThumbnailPath: localModel.localThumbnailPath,
                    audioDurationSeconds: localModel.audioDurationSeconds,
                  );
                  await localDataSource.updateMessage(mergedModel);
                  debugPrint(
                      'Updated message: ${remoteModel.id} (transcription: ${remoteModel.transcription != null}, storageUrl: ${remoteModel.storageUrl != null}, uploadStatus: $uploadStatusToUse)');
                }
              }
            }
          }
        },
        onError: (Object error) {
          debugPrint('Remote sync error: $error');
        },
      );

      // Yield the local stream (which gets updated by the remote listener above)
      yield* localDataSource
          .watchMessagesByThreadId(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      // Clean up subscription when stream is cancelled
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

      // Always attempt remote update - don't rely on connectivity check
      // The connectivity package can lag behind actual network state
      try {
        debugPrint('Attempting remote update for: ${message.id}');
        await remoteDataSource.updateMessage(model);
        debugPrint(
            '✅ Synced message update to Firestore: ${model.id} - storageUrl: ${model.storageUrl}');
      } catch (e) {
        debugPrint(
            '⚠️ Failed to sync message update to remote (will retry later): $e');
        // Don't fail the whole operation - local update succeeded
        // The message will be synced later when connectivity is restored
      }

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to update message: $e'));
    }
  }

  @override
  Future<Result<void>> syncMessages(String threadId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final remoteMessages =
          await remoteDataSource.getMessagesByThreadId(threadId);
      for (final message in remoteMessages) {
        await localDataSource.saveMessage(message);
      }

      return const Success(null);
    } catch (e) {
      if (e.toString().contains('network')) {
        return Error(
          NetworkFailure(message: 'Network error syncing messages: $e'),
        );
      }
      return Error(ServerFailure(message: 'Failed to sync messages: $e'));
    }
  }

  @override
  Future<Result<void>> syncThreadIncremental(String threadId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      // Get the latest updatedAtMillis from local DB
      final lastUpdatedAtMillis =
          await localDataSource.getLastUpdatedAtMillis(threadId);

      // If no messages exist locally, use 0 to fetch all messages
      final sinceTimestamp = lastUpdatedAtMillis ?? 0;

      debugPrint(
          '🔄 Incremental sync for thread $threadId since timestamp: $sinceTimestamp');

      // Fetch only messages updated after the last local timestamp
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
    } catch (e) {
      debugPrint('❌ Incremental sync failed: $e');
      if (e.toString().contains('network')) {
        return Error(NetworkFailure(message: 'Network error during sync: $e'));
      }
      return Error(ServerFailure(message: 'Failed to sync messages: $e'));
    }
  }

  @override
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(
      String userId) async {
    try {
      final messages = await localDataSource.getPendingUploads(userId);
      return Success(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(
          CacheFailure(message: 'Failed to query pending uploads: $e'));
    }
  }
}
