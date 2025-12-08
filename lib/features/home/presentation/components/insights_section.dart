import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/widgets/error_body.dart';
import 'package:kairos/core/widgets/loading_body.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';
import 'package:kairos/features/insights/presentation/components/insights_grid_view.dart';

class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(allCategoryInsightsProvider);

    return insightsAsync.when(
      loading: () => const LoadingBody(
        height: 500,
      ),
      error: (error, stack) {
        return const ErrorBody(
          height: 172,
          description: 'Error loading insights',
        );
      },
      data: (insights) => InsightsGridView(insights: insights),
    );
  }
}
