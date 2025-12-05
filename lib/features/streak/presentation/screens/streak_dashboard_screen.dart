import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';
import 'package:kairos/features/streak/presentation/widgets/achievement_badge_widget.dart';
import 'package:kairos/features/streak/presentation/widgets/motivational_message_widget.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_calendar_view.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_heatmap_view.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_stats_card.dart';

class StreakDashboardScreen extends ConsumerWidget {
  const StreakDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Dashboard'),
        elevation: 0,
      ),
      body: streakAsync.when(
        data: (streak) => _buildDashboard(context, ref, streak),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading dashboard: $error'),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, StreakEntity? streak) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivational message
          if (streak != null) MotivationalMessageWidget(streak: streak),

          // Stats card
          if (streak != null) StreakStatsCard(streak: streak),

          // Calendar view
          const StreakCalendarView(),

          // Heatmap view
          const StreakHeatmapView(),

          // Achievements section
          _buildAchievementsSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🏆',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Celebrate your journaling milestones',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            achievementsAsync.when(
              data: (List<AchievementEntity> achievements) => achievements.isNotEmpty
                  ? _buildAchievementsGrid(context, achievements)
                  : _buildEmptyAchievements(context),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) => Center(
                child: Text('Error loading achievements: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, List<AchievementEntity> achievements) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementBadgeWidget(achievement: achievement);
      },
    );
  }

  Widget _buildEmptyAchievements(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No achievements yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start journaling to unlock your first achievement!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
