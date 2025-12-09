import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

class StreakStatsCard extends StatelessWidget {
  const StreakStatsCard({
    required this.streak,
    super.key,
  });

  final StreakEntity streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Current Streak',
                    '${streak.currentStreak} days',
                    Icons.local_fire_department,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Longest Streak',
                    '${streak.longestStreak} days',
                    Icons.emoji_events,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Days',
                    '${streak.totalActiveDays}',
                    Icons.calendar_today,
                    theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'This Week',
                    '${streak.weeklyCount}/7',
                    Icons.view_week,
                    theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildWeeklyProgressIndicator(context, streak),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressIndicator(BuildContext context, StreakEntity streak) {
    final theme = Theme.of(context);
    final progress = streak.weeklyCount / 7.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Goal Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${streak.weeklyCount}/7 days',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0
                ? theme.colorScheme.primary
                : progress >= 0.7
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _getWeeklyMessage(streak.weeklyCount),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _getWeeklyMessage(int weeklyCount) {
    switch (weeklyCount) {
      case 0:
        return 'Start your week strong!';
      case 1:
        return 'Great start! Keep the momentum going.';
      case 2:
      case 3:
        return "Building momentum - you're doing well!";
      case 4:
      case 5:
        return 'Halfway there! Stay consistent.';
      case 6:
        return 'Almost there! One more day to complete the week!';
      case 7:
        return "Perfect week! You're unstoppable!";
      default:
        return 'Keep up the amazing work!';
    }
  }
}
