import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/insights/presentation/widgets/category_card.dart';

class InsightsGridView extends StatelessWidget {
  const InsightsGridView({
    required this.insights,
    super.key,
  });

  final List<CategoryInsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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

        return CategoryCard(
          category: category,
          insight: insight,
          onTap: () {
            context.push(AppRoutes.insightDetails, extra: category);
          },
        );
      },
    );
  }
}
