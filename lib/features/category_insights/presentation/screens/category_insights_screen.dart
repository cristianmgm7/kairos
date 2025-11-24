import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';
import 'package:kairos/features/category_insights/presentation/screens/category_insight_detail_screen.dart';

class CategoryInsightsScreen extends ConsumerWidget {
  const CategoryInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(allCategoryInsightsProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Insights'),
        ),
        Expanded(
          child: insightsAsync.when(
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
            data: (insights) {
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.9,
                ),
                itemCount: InsightCategory.values.length,
                itemBuilder: (context, index) {
                  final category = InsightCategory.values[index];
                  final insight = insights.where((i) => i.category == category).firstOrNull;

                  return _CategoryCard(
                    category: category,
                    insight: insight,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CategoryInsightDetailScreen(
                            category: category,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.insight,
    required this.onTap,
  });

  final InsightCategory category;
  final CategoryInsightEntity? insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = insight == null || insight!.isEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category name
              Text(
                category.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Summary preview or empty state
              Expanded(
                child: isEmpty
                    ? Text(
                        'No insights yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        insight!.summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),

              // Memory count
              if (!isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${insight!.memoryCount} memories',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
