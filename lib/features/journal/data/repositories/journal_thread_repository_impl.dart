import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
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
        logger.i('Network error saving thread (will sync later): ${e.message}');
        // Don't fail - local save succeeded
      } on ServerException catch (e) {
        logger.i('Server error saving thread (will sync later): ${e.message}');
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
        logger.i('Network error updating thread (will sync later): ${e.message}');
        // Don't fail - local update succeeded
      } on ServerException catch (e) {
        logger.i('Server error updating thread (will sync later): ${e.message}');
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
        logger.i('Network error syncing thread archive (will sync later): ${e.message}');
        // Don't fail - local archive succeeded
      } on ServerException catch (e) {
        logger.i('Server error syncing thread archive (will sync later): ${e.message}');
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
      logger.d('✅ Remote soft-delete successful for thread: $threadId');

      // Step 2: Local hard-delete after remote success
      try {
        await localDataSource.hardDeleteThreadAndMessages(threadId);
        logger.i('✅ Local hard-delete successful for thread: $threadId');
      } catch (e) {
        logger.i('⚠️ Local deletion failed (remote already deleted): $e');
        // Don't fail the operation - remote deletion succeeded
        // Local data will be cleaned up on next sync
      }

      return const Success(null);
    } on NetworkException catch (e) {
      logger.i('❌ Network error deleting thread $threadId: ${e.message}');
      return const Error(
        NetworkFailure(message: 'You must be online to delete this thread'),
      );
    } on ServerException catch (e) {
      logger.i('❌ Server error deleting thread $threadId: ${e.message}');
      return Error(ServerFailure(message: 'Failed to delete thread: ${e.message}'));
    } catch (e) {
      return Error(
        ServerFailure(message: 'Unexpected error deleting thread: $e'),
      );
    }
  }

  @override
  Future<Result<void>> syncThreadsIncremental(String userId) async {
    try {
      // Get the latest updatedAtMillis from local DB
      final lastUpdatedAtMillis = await localDataSource.getLastUpdatedAtMillis(userId);

      // If no threads exist locally, use 0 to fetch all threads
      final sinceTimestamp = lastUpdatedAtMillis ?? 0;

      logger.i(
        '🔄 Incremental thread sync for user $userId since timestamp: $sinceTimestamp',
      );

      // Fetch updated threads from remote (includes soft-deleted threads)
      final updatedThreads = await remoteDataSource.getUpdatedThreads(
        userId,
        sinceTimestamp,
      );

      logger.i('📥 Fetched ${updatedThreads.length} updated threads');

      if (updatedThreads.isEmpty) {
        logger.i('✅ No thread updates to sync');
        return const Success(null);
      }

      // Process each updated thread
      for (final thread in updatedThreads) {
        if (thread.isDeleted) {
          // Hard delete locally when remote is soft-deleted
          logger.i('🗑️  Hard-deleting soft-deleted thread: ${thread.id}');
          try {
            await localDataSource.hardDeleteThreadAndMessages(thread.id);
            logger.i('✅ Hard-deleted thread ${thread.id} and its messages');
          } catch (e) {
            logger.w('⚠️  Failed to hard-delete thread ${thread.id}: $e');
            // Continue processing other threads
          }
        } else {
          // Upsert active thread to local database
          final existingThread = await localDataSource.getThreadById(thread.id);

          if (existingThread != null) {
            // Update existing thread
            await localDataSource.updateThread(thread);
            logger.i('📝 Updated thread: ${thread.id}');
          } else {
            // New thread from remote
            await localDataSource.saveThread(thread);
            logger.i('✨ Added new thread: ${thread.id}');
          }
        }
      }

      logger.i('✅ Incremental thread sync completed successfully');
      return const Success(null);
    } on NetworkException catch (e) {
      logger.i('❌ Network error during incremental thread sync: ${e.message}');
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      logger.i('❌ Server error during incremental thread sync: ${e.message}');
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      logger.i('❌ Incremental thread sync failed: $e');
      return Error(ServerFailure(message: 'Failed to sync threads: $e'));
    }
  }
}
