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

      // Text messages and AI messages sync immediately
      if (await _isOnline &&
          (message.messageType == MessageType.text ||
              message.role != MessageRole.user)) {
        try {
          await remoteDataSource.saveMessage(model);
          final synced = model.copyWith(uploadStatus: 2); // completed
          await localDataSource.updateMessage(synced);
        } catch (e) {
          debugPrint('Failed to sync message to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create message: $e'));
    }
  }

  @override
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId) async {
    try {
      final localMessage = await localDataSource.getMessageById(messageId);
      return Success(localMessage?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get message: $e'));
    }
  }

  @override
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId) {
    return localDataSource
        .watchMessagesByThreadId(threadId)
        .map((models) => models.map((m) => m.toEntity()).toList());
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
      return Error(UnknownFailure(message: 'Failed to update message: $e'));
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
      return Error(UnknownFailure(message: 'Failed to sync messages: $e'));
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
          UnknownFailure(message: 'Failed to get pending uploads: $e'));
    }
  }
}
