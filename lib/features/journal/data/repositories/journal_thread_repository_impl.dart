import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/exceptions.dart';
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
  });

  final JournalThreadLocalDataSource localDataSource;
  final JournalThreadRemoteDataSource remoteDataSource;

  @override
  Future<Result<JournalThreadEntity>> createThread(
    JournalThreadEntity thread,
  ) async {
    try {
      final model = JournalThreadModel.fromEntity(thread);
      await localDataSource.saveThread(model);

      // Always attempt remote save
      try {
        await remoteDataSource.saveThread(model);
      } on NetworkException catch (e) {
        debugPrint('Network error saving thread (will sync later): ${e.message}');
        // Don't fail - local save succeeded
      } on ServerException catch (e) {
        debugPrint('Server error saving thread (will sync later): ${e.message}');
        // Don't fail - local save succeeded
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

      // Always attempt remote update
      try {
        await remoteDataSource.updateThread(model);
      } on NetworkException catch (e) {
        debugPrint('Network error updating thread (will sync later): ${e.message}');
        // Don't fail - local update succeeded
      } on ServerException catch (e) {
        debugPrint('Server error updating thread (will sync later): ${e.message}');
        // Don't fail - local update succeeded
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

      // Always attempt remote update
      try {
        final thread = await localDataSource.getThreadById(threadId);
        if (thread != null) {
          await remoteDataSource.updateThread(thread);
        }
      } on NetworkException catch (e) {
        debugPrint('Network error syncing thread archive (will sync later): ${e.message}');
        // Don't fail - local archive succeeded
      } on ServerException catch (e) {
        debugPrint('Server error syncing thread archive (will sync later): ${e.message}');
        // Don't fail - local archive succeeded
      }

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to archive thread: $e'));
    }
  }

  @override
  Future<Result<void>> syncThreads(String userId) async {
    try {
      final remoteThreads = await remoteDataSource.getThreadsByUserId(userId);
      for (final thread in remoteThreads) {
        await localDataSource.saveThread(thread);
      }

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync threads: $e'));
    }
  }

  @override
  Future<Result<void>> deleteThread(String threadId) async {
    try {
      // Step 1: Remote soft-delete first (sets isDeleted=true in Firestore)
      // This is a destructive operation that requires network connectivity
      await remoteDataSource.softDeleteThread(threadId);
      debugPrint('✅ Remote soft-delete successful for thread: $threadId');

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
    } on NetworkException catch (e) {
      debugPrint('❌ Network error deleting thread $threadId: ${e.message}');
      return const Error(
        NetworkFailure(message: 'You must be online to delete this thread'),
      );
    } on ServerException catch (e) {
      debugPrint('❌ Server error deleting thread $threadId: ${e.message}');
      return Error(ServerFailure(message: 'Failed to delete thread: ${e.message}'));
    } catch (e) {
      return Error(
        ServerFailure(message: 'Unexpected error deleting thread: $e'),
      );
    }
  }
}
