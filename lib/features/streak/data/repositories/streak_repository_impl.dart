import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:kairos/features/streak/data/datasources/streak_remote_datasource.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/daily_activity_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final StreakLocalDataSource localDataSource;
  final StreakRemoteDataSource remoteDataSource;

  @override
  Stream<StreakEntity?> watchStreak(String userId) {
    return localDataSource.watchStreak(userId).map((model) => model?.toEntity());
  }

  @override
  Future<Result<StreakEntity?>> getStreak(String userId) async {
    try {
      final localStreak = await localDataSource.getStreak(userId);
      return Success(localStreak?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get streak: $e'));
    }
  }

  @override
  Future<void> saveStreak(StreakModel model) async {
    await localDataSource.saveStreak(model);
  }

  @override
  Future<void> saveAchievement(AchievementModel model) async {
    await localDataSource.saveAchievement(model);
  }

  @override
  Future<Result<List<DailyActivityEntity>>> getDailyActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = _dateToString(startDate);
      final endDateStr = _dateToString(endDate);

      final models = await localDataSource.getDailyActivities(
        userId,
        startDateStr,
        endDateStr,
      );

      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get daily activity: $e'));
    }
  }

  @override
  Future<Result<List<AchievementEntity>>> getAchievements(String userId) async {
    try {
      final models = await localDataSource.getAchievements(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get achievements: $e'));
    }
  }

  @override
  Stream<List<AchievementEntity>> watchAchievements(String userId) {
    return localDataSource.watchAchievements(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Result<void>> syncStreak(String userId) async {
    try {
      final localStreak = await localDataSource.getStreak(userId);
      if (localStreak != null) {
        await remoteDataSource.saveStreak(localStreak);
      }

      final localAchievements = await localDataSource.getAchievements(userId);
      for (final achievement in localAchievements) {
        await remoteDataSource.saveAchievement(achievement);
      }

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync streak: $e'));
    }
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
