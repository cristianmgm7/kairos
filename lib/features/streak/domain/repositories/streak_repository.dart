import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/daily_activity_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

/// Repository interface for streak data operations
abstract class StreakRepository {
  /// Watch user's current streak data (reactive stream)
  Stream<StreakEntity?> watchStreak(String userId);

  /// Get current streak data (one-time fetch)
  Future<Result<StreakEntity?>> getStreak(String userId);

  /// Get daily activity data for a date range
  Future<Result<List<DailyActivityEntity>>> getDailyActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get user's unlocked achievements
  Future<Result<List<AchievementEntity>>> getAchievements(String userId);

  /// Watch achievements (reactive stream)
  Stream<List<AchievementEntity>> watchAchievements(String userId);

  /// Save streak data (internal use by use cases)
  Future<void> saveStreak(dynamic model);

  /// Save achievement (internal use by use cases)
  Future<void> saveAchievement(dynamic model);

  /// Sync local streak data to remote
  Future<Result<void>> syncStreak(String userId);
}
