import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';

class StreakPreviewCard extends ConsumerWidget {
  const StreakPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);

    return streakAsync.when(
      data: (streak) => _buildCard(context, streak),
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildCard(BuildContext context, StreakEntity? streak) {
    final theme = Theme.of(context);
    final currentStreak = streak?.currentStreak ?? 0;
    final hasJournaledToday = streak?.hasJournaledToday ?? false;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.streakDashboard);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with flame icon and streak count
              Row(
                children: [
                  Text(
                    '🔥',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak Day Streak',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getStatusMessage(hasJournaledToday, currentStreak),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Weekly progress dots
              if (streak != null) _buildWeeklyProgress(context, streak),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, StreakEntity streak) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    // Determine which days this week have activity
    final weekDays = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dateStr = _dateToString(date);
      final isToday = dateStr == _dateToString(now);
      final hasActivity =
          streak.lastActivityDate == dateStr || (streak.hasJournaledToday && isToday);

      return (isToday: isToday, hasActivity: hasActivity);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((day) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: day.hasActivity
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: day.isToday
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: day.hasActivity
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
            return SizedBox(
              width: 36,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('Error loading streak: $error'),
      ),
    );
  }

  String _getStatusMessage(bool hasJournaledToday, int currentStreak) {
    if (currentStreak == 0) {
      return 'Start your streak today!';
    } else if (hasJournaledToday) {
      return 'Amazing! Keep the momentum going!';
    } else {
      return 'Journal today to continue your streak';
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1
    return date.subtract(Duration(days: weekday - 1));
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
