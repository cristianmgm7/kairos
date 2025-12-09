import 'package:isar/isar.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/daily_activity_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';

abstract class StreakLocalDataSource {
  Future<void> saveStreak(StreakModel streak);
  Future<StreakModel?> getStreak(String userId);
  Stream<StreakModel?> watchStreak(String userId);
  Future<void> saveDailyActivity(DailyActivityModel activity);
  Future<List<DailyActivityModel>> getDailyActivities(
    String userId,
    String startDate,
    String endDate,
  );
  Future<void> saveAchievement(AchievementModel achievement);
  Future<List<AchievementModel>> getAchievements(String userId);
  Stream<List<AchievementModel>> watchAchievements(String userId);
  Stream<List<DailyActivityModel>> watchDailyActivities(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

class StreakLocalDataSourceImpl implements StreakLocalDataSource {
  StreakLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveStreak(StreakModel streak) async {
    await isar.writeTxn(() async {
      await isar.streakModels.put(streak);
    });
  }

  @override
  Future<StreakModel?> getStreak(String userId) async {
    return isar.streakModels.filter().userIdEqualTo(userId).findFirst();
  }

  @override
  Stream<StreakModel?> watchStreak(String userId) {
    return isar.streakModels
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((streaks) => streaks.isNotEmpty ? streaks.first : null);
  }

  @override
  Future<void> saveDailyActivity(DailyActivityModel activity) async {
    await isar.writeTxn(() async {
      await isar.dailyActivityModels.put(activity);
    });
  }

  @override
  Future<List<DailyActivityModel>> getDailyActivities(
    String userId,
    String startDate,
    String endDate,
  ) async {
    return isar.dailyActivityModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .dateBetween(startDate, endDate)
        .sortByDate()
        .findAll();
  }

  @override
  Future<void> saveAchievement(AchievementModel achievement) async {
    await isar.writeTxn(() async {
      await isar.achievementModels.put(achievement);
    });
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    return isar.achievementModels
        .filter()
        .userIdEqualTo(userId)
        .sortByUnlockedAtMillisDesc()
        .findAll();
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    return isar.achievementModels.filter().userIdEqualTo(userId).watch(fireImmediately: true).map(
        (achievements) =>
            achievements..sort((a, b) => b.unlockedAtMillis.compareTo(a.unlockedAtMillis)));
  }

  @override
  Stream<List<DailyActivityModel>> watchDailyActivities(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startDateStr = _dateToString(startDate);
    final endDateStr = _dateToString(endDate);

    return isar.dailyActivityModels
        .filter()
        .userIdEqualTo(userId)
        .dateBetween(startDateStr, endDateStr)
        .watch(fireImmediately: true)
        .map((activities) => activities..sort((a, b) => b.date.compareTo(a.date)));
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
