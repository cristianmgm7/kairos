import 'dart:async';

import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/insights/data/datasources/insight_local_datasource.dart';
import 'package:kairos/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final InsightLocalDataSource localDataSource;
  final InsightRemoteDataSource remoteDataSource;

  @override
  Future<Result<InsightEntity?>> getInsightById(String insightId) async {
    try {
      final localInsight = await localDataSource.getInsightById(insightId);
      return Success(localInsight?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insight: $e'));
    }
  }

  @override
  Future<Result<List<InsightEntity>>> getGlobalInsights(String userId) async {
    try {
      final localInsights = await localDataSource.getGlobalInsights(userId);
      return Success(localInsights.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insights: $e'));
    }
  }

  @override
  Future<Result<List<InsightEntity>>> getThreadInsights(String threadId) async {
    try {
      final localInsights = await localDataSource.getThreadInsights(threadId);
      return Success(localInsights.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insights: $e'));
    }
  }

  @override
  Stream<List<InsightEntity>> watchGlobalInsights(String userId) async* {
    StreamSubscription<List<InsightModel>>? remoteSub;

    try {
      // Always attempt remote sync - listen to Firestore and sync to local DB
      remoteSub = remoteDataSource.watchGlobalInsights(userId).listen(
        (remoteModels) async {
          // Get current local insights to compare
          final localInsights = await localDataSource.getGlobalInsights(userId);
          final localIds = localInsights.map((m) => m.id).toSet();

          for (final remoteModel in remoteModels) {
            if (!localIds.contains(remoteModel.id)) {
              // New insight from remote
              await localDataSource.saveInsight(remoteModel);
              logger.i('Synced new global insight: ${remoteModel.id}');
            } else {
              // Check if we need to update
              final localModel = await localDataSource.getInsightById(remoteModel.id);
              if (localModel != null && localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
                await localDataSource.updateInsight(remoteModel);
                logger.i('Updated global insight: ${remoteModel.id}');
              }
            }
          }
        },
        onError: (Object error) {
          // Network errors are transient - just log and continue
          // The local stream continues to work offline
          logger.i('Remote sync error (will retry when online): $error');
        },
      );

      // Always yield the local stream (updated by remote listener when online)
      yield* localDataSource
          .watchGlobalInsights(userId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      // Clean up subscription when stream is cancelled
      await remoteSub?.cancel();
    }
  }

  @override
  Stream<List<InsightEntity>> watchThreadInsights(String threadId) async* {
    StreamSubscription<List<InsightModel>>? remoteSub;

    try {
      // Get userId from local insights (needed for Firestore query)
      final localInsights = await localDataSource.getThreadInsights(threadId);

      if (localInsights.isNotEmpty) {
        final userId = localInsights.first.userId;

        // Always attempt remote sync when we have userId
        remoteSub = remoteDataSource.watchThreadInsights(userId, threadId).listen(
          (remoteModels) async {
            final localInsights = await localDataSource.getThreadInsights(threadId);
            final localIds = localInsights.map((m) => m.id).toSet();

            for (final remoteModel in remoteModels) {
              if (!localIds.contains(remoteModel.id)) {
                await localDataSource.saveInsight(remoteModel);
                logger.i('Synced new thread insight: ${remoteModel.id}');
              } else {
                final localModel = await localDataSource.getInsightById(remoteModel.id);
                if (localModel != null &&
                    localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
                  await localDataSource.updateInsight(remoteModel);
                  logger.i('Updated thread insight: ${remoteModel.id}');
                }
              }
            }
          },
          onError: (Object error) {
            // Network errors are transient - just log and continue
            logger.i('Remote sync error (will retry when online): $error');
          },
        );
      }

      // Always yield the local stream (updated by remote listener when online)
      yield* localDataSource
          .watchThreadInsights(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      await remoteSub?.cancel();
    }
  }

  @override
  Future<Result<void>> syncInsights(String userId) async {
    try {
      // Sync global insights
      final remoteGlobalInsights = await remoteDataSource.getGlobalInsights(userId);
      for (final insight in remoteGlobalInsights) {
        await localDataSource.saveInsight(insight);
      }

      // Note: Thread insights will sync when their specific streams are watched
      // This is an optimization to avoid loading all thread insights at once

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync insights: $e'));
    }
  }
}
