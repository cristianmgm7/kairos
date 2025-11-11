import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/presentation/providers/insight_providers.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightPeriod _selectedPeriod = InsightPeriod.oneWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    // Watch all global insights
    final insightsAsync = ref.watch(currentUserGlobalInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(insightControllerProvider.notifier).generateGlobalInsight(
                    period: _selectedPeriod,
                    forceRefresh: true,
                  );
            },
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading insights',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (allInsights) {
          if (allInsights.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No insights yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Start journaling to generate insights',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter insights by selected period
          final periodInsight = allInsights.where((i) => i.period == _selectedPeriod).firstOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(theme),
                const SizedBox(height: AppSpacing.lg),

                // Insight Summary Card
                if (periodInsight != null) ...[
                  _buildInsightCard(theme, periodInsight),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  _buildNoInsightForPeriod(theme),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // All Insights List (for debugging/testing)
                Text(
                  'All Insights (${allInsights.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...allInsights.map((insight) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        title: Text(insight.summary ?? 'No summary'),
                        subtitle: Text(
                          'Period: ${insight.period?.name ?? "none"} | '
                          'Mood: ${insight.moodScore.toStringAsFixed(2)} | '
                          'Emotion: ${insight.dominantEmotion.name}',
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    final selectablePeriods = [
      InsightPeriod.oneDay,
      InsightPeriod.threeDays,
      InsightPeriod.oneWeek,
      InsightPeriod.oneMonth,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InsightPeriod>(
          value: _selectedPeriod,
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          items: selectablePeriods.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(_getPeriodLabel(period)),
            );
          }).toList(),
          onChanged: (period) {
            if (period != null) {
              setState(() {
                _selectedPeriod = period;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme, InsightEntity insight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.summary ?? 'No summary available',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    theme,
                    'Mood',
                    insight.moodScore.toStringAsFixed(1),
                    Icons.mood,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatChip(
                    theme,
                    'Emotion',
                    insight.dominantEmotion.name,
                    Icons.favorite,
                  ),
                ),
              ],
            ),
            if (insight.keywords.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Keywords',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: insight.keywords.take(5).map((keyword) {
                  return Chip(
                    label: Text(keyword),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInsightForPeriod(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No insight for ${_getPeriodLabel(_selectedPeriod)}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Keep journaling to generate insights for this period',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(InsightPeriod period) {
    return switch (period) {
      InsightPeriod.oneDay => '1 Day',
      InsightPeriod.threeDays => '3 Days',
      InsightPeriod.oneWeek => '1 Week',
      InsightPeriod.oneMonth => '1 Month',
      InsightPeriod.daily => 'Daily',
    };
  }
}
