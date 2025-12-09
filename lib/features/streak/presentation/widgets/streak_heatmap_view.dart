import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';

class StreakHeatmapView extends ConsumerWidget {
  const StreakHeatmapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyActivitiesAsync = ref.watch(dailyActivitiesProvider);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yearly Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your journaling journey at a glance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            dailyActivitiesAsync.when(
              data: (activities) => _buildHeatmap(context, activities),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading heatmap: $error'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHeatmapLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, List<Map<String, dynamic>> activities) {
    final theme = Theme.of(context);

    // Convert activities to heatmap data
    final heatmapData = <DateTime, int>{};
    for (final activity in activities) {
      final date = DateTime.parse(activity['date'] as String);
      final count = activity['entryCount'] as int;
      if (count > 0) {
        heatmapData[DateTime(date.year, date.month, date.day)] = count;
      }
    }

    return HeatMapCalendar(
      flexible: true,
      datasets: heatmapData,
      colorMode: ColorMode.color,
      colorsets: {
        1: _getHeatmapColor(1), // Light activity
        2: _getHeatmapColor(2), // Medium activity
        3: _getHeatmapColor(3), // High activity
        4: _getHeatmapColor(4), // Very high activity
      },
      defaultColor: theme.colorScheme.surfaceContainerHighest,
      textColor: theme.colorScheme.onSurface,
      showColorTip: false, // Hide day numbers to keep it clean
      size: 16,
      margin: const EdgeInsets.all(AppSpacing.xs),
      onClick: (date) {
        // Could show a tooltip with activity details
        final count = heatmapData[date];
        if (count != null && count > 0) {
          _showActivityTooltip(context, date, count);
        }
      },
    );
  }

  Widget _buildHeatmapLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(width: 12, height: 12, color: _getHeatmapColor(0)),
        const SizedBox(width: AppSpacing.xs),
        Container(width: 12, height: 12, color: _getHeatmapColor(1)),
        const SizedBox(width: AppSpacing.xs),
        Container(width: 12, height: 12, color: _getHeatmapColor(2)),
        const SizedBox(width: AppSpacing.xs),
        Container(width: 12, height: 12, color: _getHeatmapColor(3)),
        const SizedBox(width: AppSpacing.xs),
        Container(width: 12, height: 12, color: _getHeatmapColor(4)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'More',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return const Color(0xFFE5E7EB); // Very light gray
      case 1:
        return const Color(0xFF9BE9A8); // Light green
      case 2:
        return const Color(0xFF40C463); // Medium green
      case 3:
        return const Color(0xFF30A14E); // Dark green
      case 4:
        return const Color(0xFF216E39); // Very dark green
      default:
        return const Color(0xFF216E39);
    }
  }

  void _showActivityTooltip(BuildContext context, DateTime date, int count) {
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _formatDate(date),
          style: theme.textTheme.titleMedium,
        ),
        content: Text(
          count == 1 ? '1 journal entry' : '$count journal entries',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
