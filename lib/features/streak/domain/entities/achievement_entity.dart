import 'package:equatable/equatable.dart';

/// Types of achievements users can earn
enum AchievementType {
  streak7,    // 7-day streak
  streak30,   // 30-day streak
  streak100,  // 100-day streak
  streak365,  // 365-day streak (1 year!)
  firstEntry, // First journal entry ever
  weekGoal,   // Completed weekly goal
}

/// Represents a user achievement/milestone
class AchievementEntity extends Equatable {
  const AchievementEntity({
    required this.userId,
    required this.type,
    required this.unlockedAt,
    this.id,
  });

  /// Unique ID for this achievement instance
  final String? id;

  /// User who unlocked this achievement
  final String userId;

  /// Type of achievement
  final AchievementType type;

  /// When the achievement was unlocked
  final DateTime unlockedAt;

  /// Index of the achievement type (for serialization)
  int get typeIndex => type.index;

  /// Display name for the achievement
  String get displayName {
    return switch (type) {
      AchievementType.streak7 => '7 Day Streak',
      AchievementType.streak30 => '30 Day Streak',
      AchievementType.streak100 => '100 Day Streak',
      AchievementType.streak365 => 'Year-Long Streak',
      AchievementType.firstEntry => 'Getting Started',
      AchievementType.weekGoal => 'Weekly Warrior',
    };
  }

  /// Description of the achievement
  String get description {
    return switch (type) {
      AchievementType.streak7 => 'Journaled for 7 consecutive days',
      AchievementType.streak30 => 'Journaled for 30 consecutive days',
      AchievementType.streak100 => 'Journaled for 100 consecutive days',
      AchievementType.streak365 => 'Journaled for 365 consecutive days',
      AchievementType.firstEntry => 'Created your first journal entry',
      AchievementType.weekGoal => 'Completed weekly journaling goal',
    };
  }

  /// Icon emoji for the achievement
  String get icon {
    return switch (type) {
      AchievementType.streak7 => '🔥',
      AchievementType.streak30 => '⭐',
      AchievementType.streak100 => '💎',
      AchievementType.streak365 => '🏆',
      AchievementType.firstEntry => '✨',
      AchievementType.weekGoal => '🎯',
    };
  }

  @override
  List<Object?> get props => [id, userId, type, unlockedAt];

  AchievementEntity copyWith({
    String? id,
    String? userId,
    AchievementType? type,
    DateTime? unlockedAt,
  }) {
    return AchievementEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
