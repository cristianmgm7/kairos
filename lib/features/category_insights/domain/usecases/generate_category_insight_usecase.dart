import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';

/// Use case for generating category insights
class GenerateCategoryInsightUseCase {
  GenerateCategoryInsightUseCase({required this.repository});

  final CategoryInsightRepository repository;

  /// Execute the use case
  ///
  /// [category] - The category value to generate insights for
  /// [forceRefresh] - Whether to force regeneration even if recently generated
  Future<Result<void>> call(String category, {bool forceRefresh = true}) async {
    try {
      await repository.generateInsight(category, forceRefresh: forceRefresh);
      return const Success(null);
    } catch (e) {
      // Map exceptions to domain failures
      if (e.toString().contains('network')) {
        return const Error(NetworkFailure(message: 'Network error occurred'));
      } else if (e.toString().contains('permission')) {
        return const Error(ServerFailure(message: 'Permission denied'));
      } else {
        return Error(
          ServerFailure(message: 'Failed to generate insight: $e'),
        );
      }
    }
  }
}
