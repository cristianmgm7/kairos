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

      // Ensure a remote document exists for all messages when online.
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
          debugPrint('Failed to sync message to remote: $e');
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
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId) async* {
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
      remoteSub = remoteDataSource.watchMessagesByThreadId(threadId, userId).listen(
        (remoteModels) async {
          // Get current local messages to compare
          final localMessages = await localDataSource.getMessagesByThreadId(threadId);
          final localIds = localMessages.map((m) => m.id).toSet();

          for (final remoteModel in remoteModels) {
            if (!localIds.contains(remoteModel.id)) {
              // New message from remote (e.g., AI response)
              await localDataSource.saveMessage(remoteModel);
              debugPrint('Synced new AI message: ${remoteModel.id}');
            } else {
              // Check if we need to update (e.g., processing status or transcription changed)
              final localModel = await localDataSource.getMessageById(remoteModel.id);
              if (localModel != null) {
                final needsUpdate =
                    localModel.aiProcessingStatus != remoteModel.aiProcessingStatus ||
                    localModel.transcription != remoteModel.transcription;

                if (needsUpdate) {
                  // Merge: preserve local-only fields (uploadStatus, localFilePath, etc.)
                  final mergedModel = remoteModel.copyWith(
                    uploadStatus: localModel.uploadStatus,
                    uploadRetryCount: localModel.uploadRetryCount,
                    localFilePath: localModel.localFilePath,
                    localThumbnailPath: localModel.localThumbnailPath,
                    audioDurationSeconds: localModel.audioDurationSeconds,
                  );
                  await localDataSource.updateMessage(mergedModel);
                  debugPrint('Updated message: ${remoteModel.id} (transcription: ${remoteModel.transcription != null}, uploadStatus preserved: ${localModel.uploadStatus})');
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
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.updateMessage(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.updateMessage(model);
        } catch (e) {
          debugPrint('Failed to sync message update to remote: $e');
        }
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
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(
      String userId) async {
    try {
      final messages = await localDataSource.getPendingUploads(userId);
      return Success(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to query pending uploads: $e'));
    }
  }
}
