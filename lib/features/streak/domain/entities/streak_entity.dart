import 'package:equatable/equatable.dart';

/// Represents a user's journaling streak data.
class StreakEntity extends Equatable {
  const StreakEntity({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
    this.currentWeekCount = 0,
  });

  /// User ID who owns this streak
  final String userId;

  /// Current consecutive days with journal entries
  final int currentStreak;

  /// Personal record for longest streak
  final int longestStreak;

  /// Lifetime count of days with at least one journal entry
  final int totalActiveDays;

  /// Date of most recent journal entry (local date, not DateTime)
  /// Stored as YYYY-MM-DD string to handle timezone correctly
  final String lastActivityDate;

  /// Number of journal entries created this week (Monday-Sunday)
  final int currentWeekCount;

  /// When this streak record was first created
  final DateTime createdAt;

  /// When this streak record was last updated
  final DateTime updatedAt;

  /// Check if user has journaled today
  bool get hasJournaledToday {
    final now = DateTime.now();
    final today = _dateToString(now);
    return lastActivityDate == today;
  }

  /// Check if streak is active (journaled today or yesterday)
  bool get isActive {
    final now = DateTime.now();
    final today = _dateToString(now);
    final yesterday = _dateToString(now.subtract(const Duration(days: 1)));
    return lastActivityDate == today || lastActivityDate == yesterday;
  }

  /// Get days until streak expires
  int get daysUntilExpiry {
    if (hasJournaledToday) return 1; // Safe for today
    if (isActive) return 0; // Expires today
    return -1; // Already expired
  }

  /// Helper to convert DateTime to YYYY-MM-DD string
  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        userId,
        currentStreak,
        longestStreak,
        totalActiveDays,
        lastActivityDate,
        currentWeekCount,
        createdAt,
        updatedAt,
      ];

  StreakEntity copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? totalActiveDays,
    String? lastActivityDate,
    int? currentWeekCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreakEntity(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      currentWeekCount: currentWeekCount ?? this.currentWeekCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
