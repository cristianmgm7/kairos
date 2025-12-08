import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';

class AchievementBadgeWidget extends StatelessWidget {
  const AchievementBadgeWidget({
    required this.achievement,
    super.key,
  });

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isUnlocked = true; // Always unlocked if we have the achievement

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Badge icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? _getAchievementColor(achievement.type).withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isUnlocked
                    ? _getAchievementColor(achievement.type)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
      child: Icon(
            _getAchievementIcon(achievement.type),
            color: _getAchievementColor(achievement.type),
            size: 32,
          ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title
          Text(
            _getAchievementTitle(achievement.type),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Description
          Text(
            _getAchievementDescription(achievement.type),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Unlocked date
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              _formatDate(achievement.unlockedAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return Icons.edit_note;
      case AchievementType.streak7:
        return Icons.view_week;
      case AchievementType.streak30:
        return Icons.calendar_view_month;
      case AchievementType.streak100:
        return Icons.event_available;
      case AchievementType.streak365:
        return Icons.timeline;
      case AchievementType.weekGoal:
        return Icons.celebration;
    }
  }

  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.streak7:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.streak30:
        return const Color(0xFF9C27B0); // Purple
      case AchievementType.streak100:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.streak365:
        return const Color(0xFFE91E63); // Pink
      case AchievementType.weekGoal:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  String _getAchievementTitle(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return 'First Steps';
      case AchievementType.streak7:
        return 'Week Warrior';
      case AchievementType.streak30:
        return 'Monthly Master';
      case AchievementType.streak100:
        return 'Century Champion';
      case AchievementType.streak365:
        return 'Year of Wisdom';
      case AchievementType.weekGoal:
        return 'Weekly Warrior';
    }
  }

  String _getAchievementDescription(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return 'Your first journal entry! Welcome to the journey of self-discovery.';
      case AchievementType.streak7:
        return '7 days of consistent journaling. Habits are forming!';
      case AchievementType.streak30:
        return '30 days of dedication. You\'re building a powerful habit.';
      case AchievementType.streak100:
        return '100 days of transformation. Your future self is grateful.';
      case AchievementType.streak365:
        return '365 days of self-reflection. A year of growth and insight.';
      case AchievementType.weekGoal:
        return 'Completed your weekly journaling goal!';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
