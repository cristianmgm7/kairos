import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

class MotivationalMessageWidget extends StatelessWidget {
  const MotivationalMessageWidget({
    required this.streak,
    super.key,
  });

  final StreakEntity streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _getMotivationalMessage(streak);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getEmoji(streak),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Motivation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(StreakEntity streak) {
    final currentStreak = streak.currentStreak;
    final hasJournaledToday = streak.hasJournaledToday;
    final longestStreak = streak.longestStreak;

    // New user
    if (currentStreak == 0 && longestStreak == 0) {
      return 'Every great journey begins with a single step. Start journaling today and build something amazing! 💪';
    }

    // Lost streak but has history
    if (currentStreak == 0 && longestStreak > 0) {
      if (longestStreak == 1) {
        return "Yesterday's a closed chapter. Today's a blank page. Write your comeback story! 📖";
      } else {
        return "You've built a streak of $longestStreak days before. That fire is still inside you. Let's reignite it! 🔥";
      }
    }

    // Active streak - hasn't journaled today
    if (currentStreak > 0 && !hasJournaledToday) {
      if (currentStreak == 1) {
        return "Great start! Keep the momentum going tomorrow. One day at a time creates extraordinary results. 🌟";
      } else if (currentStreak < 7) {
        return "You're building something special! $currentStreak days in a row shows real dedication. Keep going! 🚀";
      } else if (currentStreak < 30) {
        return "Week ${currentStreak ~/ 7 + 1} in progress! You're turning consistency into a superpower. Stay strong! ⚡";
      } else {
        return "$currentStreak days strong! You're proving to yourself what dedication can achieve. The journey continues! 🏔️";
      }
    }

    // Active streak - has journaled today
    if (currentStreak > 0 && hasJournaledToday) {
      if (currentStreak == 1) {
        return "First day done! You've taken the most important step. Tomorrow builds on today. Keep it going! 🎯";
      } else if (currentStreak == 7) {
        return "One week down! You've officially turned journaling into a habit. Week 2 awaits! 🎉";
      } else if (currentStreak == 30) {
        return "A full month! 30 days of self-reflection. You're not just journaling - you're evolving. 🌱➡️🌳";
      } else if (currentStreak == 100) {
        return "100 days! This isn't just consistency - this is transformation. You're unstoppable! 💎";
      } else if (currentStreak == 365) {
        return "A YEAR of daily journaling! You've given yourself the gift of self-discovery. Your future self thanks you! 🎁";
      } else if (currentStreak < 7) {
        return "$currentStreak days strong and today's entry is in the books! The compound effect is working. 🌱";
      } else if (currentStreak < 30) {
        return "Week ${currentStreak ~/ 7 + 1} complete! Your commitment is inspiring. The next chapter awaits! 📚";
      } else if (currentStreak < 100) {
        return "$currentStreak days of wisdom collected! You're building a treasure trove of self-knowledge. 🏆";
      } else {
        return "$currentStreak days of transformation! Each entry is a step toward the person you're becoming. You're incredible! ✨";
      }
    }

    return 'Keep writing your story, one day at a time! 📝';
  }

  String _getEmoji(StreakEntity streak) {
    final currentStreak = streak.currentStreak;
    final hasJournaledToday = streak.hasJournaledToday;

    if (currentStreak == 0) {
      return '🌱'; // Seed for new beginnings
    } else if (currentStreak < 7) {
      return hasJournaledToday ? '🔥' : '💪'; // Fire or strength
    } else if (currentStreak < 30) {
      return '🚀'; // Rocket for momentum
    } else if (currentStreak < 100) {
      return '⚡'; // Lightning for power
    } else if (currentStreak < 365) {
      return '💎'; // Diamond for precious achievement
    } else {
      return '👑'; // Crown for mastery
    }
  }
}
