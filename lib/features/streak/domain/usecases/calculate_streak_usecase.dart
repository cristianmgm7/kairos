import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';

/// Calculates user's current streak based on journal activity.
///
/// Algorithm:
/// 1. Fetch all journal threads for the user
/// 2. Group messages by date (local timezone)
/// 3. Calculate consecutive days working backwards from today
/// 4. Update streak entity with new values
/// 5. Check for new achievements
class CalculateStreakUseCase {
  CalculateStreakUseCase({
    required this.streakRepository,
    required this.journalRepository,
  });

  final StreakRepository streakRepository;
  final JournalThreadRepository journalRepository;

  Future<StreakEntity> call(String userId) async {
    // Get existing streak or create new
    final existingStreakResult = await streakRepository.getStreak(userId);
    final existingStreak = existingStreakResult.dataOrNull;

    // Get all journal threads to find message timestamps
    final threadsResult = await journalRepository.getThreadsByUserId(userId);
    final threads = threadsResult.dataOrNull ?? [];

    if (threads.isEmpty) {
      // No journal activity yet
      return existingStreak ?? StreakEntity(
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        totalActiveDays: 0,
        lastActivityDate: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Extract all activity dates from threads
    final activityDates = <String>{};
    DateTime? mostRecentActivity;

    for (final thread in threads) {
      if (thread.lastMessageAt != null) {
        final messageDate = thread.lastMessageAt!;
        final dateString = _dateToString(messageDate);
        activityDates.add(dateString);

        if (mostRecentActivity == null || messageDate.isAfter(mostRecentActivity)) {
          mostRecentActivity = messageDate;
        }
      }
    }

    // Calculate current streak
    final now = DateTime.now();
    final today = _dateToString(now);
    final yesterday = _dateToString(now.subtract(const Duration(days: 1)));

    var currentStreak = 0;
    var lastActivityDate = '';

    if (activityDates.contains(today)) {
      lastActivityDate = today;
      currentStreak = 1;

      // Count backwards from yesterday
      var checkDate = now.subtract(const Duration(days: 1));
      while (activityDates.contains(_dateToString(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (activityDates.contains(yesterday)) {
      lastActivityDate = yesterday;
      currentStreak = 1;

      // Count backwards from 2 days ago
      var checkDate = now.subtract(const Duration(days: 2));
      while (activityDates.contains(_dateToString(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      // Streak is broken
      currentStreak = 0;
      lastActivityDate = mostRecentActivity != null ? _dateToString(mostRecentActivity) : '';
    }

    // Calculate longest streak (preserve if current is lower)
    final longestStreak = existingStreak != null
        ? (currentStreak > existingStreak.longestStreak ? currentStreak : existingStreak.longestStreak)
        : currentStreak;

    // Calculate current week count (Monday-Sunday)
    final weekStart = _getWeekStart(now);
    var currentWeekCount = 0;
    for (var i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));
      if (activityDates.contains(_dateToString(checkDate))) {
        currentWeekCount++;
      }
    }

    // Create updated streak entity
    final updatedStreak = StreakEntity(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActiveDays: activityDates.length,
      lastActivityDate: lastActivityDate,
      currentWeekCount: currentWeekCount,
      createdAt: existingStreak?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    logger.i('Calculated streak for $userId: current=$currentStreak, longest=$longestStreak, total=${activityDates.length}');

    return updatedStreak;
  }

  /// Convert DateTime to YYYY-MM-DD string
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get Monday of current week
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1
    return date.subtract(Duration(days: weekday - 1));
  }
}
