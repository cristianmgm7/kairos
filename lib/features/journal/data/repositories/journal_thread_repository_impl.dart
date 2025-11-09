import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';

class JournalThreadRepositoryImpl implements JournalThreadRepository {
  JournalThreadRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final JournalThreadLocalDataSource localDataSource;
  final JournalThreadRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalThreadEntity>> createThread(
      JournalThreadEntity thread) async {
    try {
      final model = JournalThreadModel.fromEntity(thread);
      await localDataSource.saveThread(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.saveThread(model);
        } catch (e) {
          debugPrint('Failed to sync thread to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to save thread locally: $e'));
    }
  }

  @override
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId) async {
    try {
      final localThread = await localDataSource.getThreadById(threadId);
      return Success(localThread?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve thread: $e'));
    }
  }

  @override
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId) {
    return localDataSource
        .watchThreadsByUserId(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> updateThread(JournalThreadEntity thread) async {
    try {
      final model = JournalThreadModel.fromEntity(thread);
      await localDataSource.updateThread(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.updateThread(model);
        } catch (e) {
          debugPrint('Failed to sync thread update to remote: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to update thread: $e'));
    }
  }

  @override
  Future<Result<void>> archiveThread(String threadId) async {
    try {
      await localDataSource.archiveThread(threadId);

      if (await _isOnline) {
        try {
          final thread = await localDataSource.getThreadById(threadId);
          if (thread != null) {
            await remoteDataSource.updateThread(thread);
          }
        } catch (e) {
          debugPrint('Failed to sync thread archive to remote: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to archive thread: $e'));
    }
  }

  @override
  Future<Result<void>> syncThreads(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final remoteThreads = await remoteDataSource.getThreadsByUserId(userId);
      for (final thread in remoteThreads) {
        await localDataSource.saveThread(thread);
      }

      return const Success(null);
    } catch (e) {
      if (e.toString().contains('network')) {
        return Error(
          NetworkFailure(message: 'Network error syncing threads: $e'),
        );
      }
      return Error(ServerFailure(message: 'Failed to sync threads: $e'));
    }
  }

  @override
  Future<Result<void>> deleteThread(String threadId) async {
    try {
      // Pre-check: Must be online for deletion
      if (!await _isOnline) {
        return const Error(
          NetworkFailure(message: 'You must be online to delete this thread'),
        );
      }

      // Step 1: Remote soft-delete first (sets isDeleted=true in Firestore)
      try {
        await remoteDataSource.softDeleteThread(threadId);
        debugPrint('✅ Remote soft-delete successful for thread: $threadId');
      } catch (e) {
        debugPrint('❌ Remote deletion failed for thread $threadId: $e');
        return Error(
          ServerFailure(message: 'Failed to delete thread $threadId: $e'),
        );
      }

      // Step 2: Local hard-delete after remote success
      try {
        await localDataSource.hardDeleteThreadAndMessages(threadId);
        debugPrint('✅ Local hard-delete successful for thread: $threadId');
      } catch (e) {
        debugPrint('⚠️ Local deletion failed (remote already deleted): $e');
        // Don't fail the operation - remote deletion succeeded
        // Local data will be cleaned up on next sync
      }

      return const Success(null);
    } catch (e) {
      return Error(
        ServerFailure(message: 'Unexpected error deleting thread: $e'),
      );
    }
  }
}
