import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/presentation/controllers/category_insight_controller.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';

class CategoryInsightDetailScreen extends ConsumerStatefulWidget {
  const CategoryInsightDetailScreen({
    required this.category,
    super.key,
  });

  final InsightCategory category;

  @override
  ConsumerState<CategoryInsightDetailScreen> createState() => _CategoryInsightDetailScreenState();
}

class _CategoryInsightDetailScreenState extends ConsumerState<CategoryInsightDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightAsync = ref.watch(categoryInsightProvider(widget.category));
    final controllerState = ref.watch(categoryInsightControllerProvider);

    // Listen for controller state changes for side effects
    ref.listen<CategoryInsightState>(categoryInsightControllerProvider, (previous, next) {
      if (next is CategoryInsightGenerateSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insight generated successfully')),
          );
        }
        // Reset controller state
        ref.read(categoryInsightControllerProvider.notifier).reset();
      } else if (next is CategoryInsightGenerateError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate insight: ${next.message}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        // Reset controller state
        ref.read(categoryInsightControllerProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.displayName),
      ),
      body: insightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (insight) {
          final isEmpty = insight == null || insight.isEmpty;
          final bool canRefresh;
          if (isEmpty) {
            canRefresh = true;
          } else {
            canRefresh = insight.canRefresh(const Duration(hours: 1));
          }

          // Check if currently generating
          final isGenerating = controllerState is CategoryInsightGenerating;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon and title
                Row(
                  children: [
                    Text(
                      widget.category.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isEmpty)
                            Text(
                              '${insight.memoryCount} memories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Generate/Refresh button
                if (isEmpty)
                  // First time: Show "Generate Insights" button
                  Column(
                    children: [
                      Text(
                        _getCategoryDescription(widget.category),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isGenerating ? null : _handleGenerateInsight,
                          icon: isGenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            isGenerating ? 'Generating...' : 'Generate Insights',
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  // After first generation: Show "Refresh" button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isGenerating || !canRefresh ? null : _handleGenerateInsight,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        isGenerating
                            ? 'Refreshing...'
                            : canRefresh
                                ? 'Refresh Insight'
                                : 'Available in ${_getTimeUntilRefresh(insight)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Summary
                  _buildSection(
                    theme,
                    'Summary',
                    Icons.insights,
                    Text(
                      insight.summary,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Key Patterns
                  if (insight.keyPatterns.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Key Patterns',
                      Icons.pattern,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.keyPatterns
                            .map(
                              (pattern) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        pattern,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Strengths
                  if (insight.strengths.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Strengths',
                      Icons.star,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.strengths
                            .map(
                              (strength) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '✓ ',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        strength,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Opportunities
                  if (insight.opportunities.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Opportunities for Growth',
                      Icons.trending_up,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.opportunities
                            .map(
                              (opportunity) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '→ ',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        opportunity,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  // Last updated
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Last updated: ${_formatDate(insight.lastRefreshedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Handle generate/refresh insight button press
  void _handleGenerateInsight() {
    ref.read(categoryInsightControllerProvider.notifier).generateInsight(
          widget.category.value,
        );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        content,
      ],
    );
  }

  String _getCategoryDescription(InsightCategory category) {
    return switch (category) {
      InsightCategory.mindsetWellbeing =>
        'Kairos will generate insights here once you talk about your emotions, stress, or mental well-being.',
      InsightCategory.productivityFocus =>
        'Kairos will generate insights here once you talk about your work, focus, or productivity.',
      InsightCategory.relationshipsConnection =>
        'Kairos will generate insights here once you talk about your relationships and connections.',
      InsightCategory.careerGrowth =>
        'Kairos will generate insights here once you talk about your career, goals, or professional growth.',
      InsightCategory.healthLifestyle =>
        'Kairos will generate insights here once you talk about your health, habits, or lifestyle.',
      InsightCategory.purposeValues =>
        'Kairos will generate insights here once you talk about your values, purpose, or life vision.',
    };
  }

  String _getTimeUntilRefresh(CategoryInsightEntity insight) {
    final now = DateTime.now();
    final nextRefreshTime = insight.lastRefreshedAt.add(const Duration(hours: 1));
    final difference = nextRefreshTime.difference(now);

    if (difference.inMinutes < 1) {
      return 'less than a minute';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '1 hour';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
