import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/category_insights/domain/usecases/generate_category_insight_usecase.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';

/// State for category insight generation operations
sealed class CategoryInsightState {
  const CategoryInsightState();
}

/// Initial state - no operation in progress
class CategoryInsightInitial extends CategoryInsightState {
  const CategoryInsightInitial();
}

/// Generating insights
class CategoryInsightGenerating extends CategoryInsightState {
  const CategoryInsightGenerating();
}

/// Insight generation succeeded
class CategoryInsightGenerateSuccess extends CategoryInsightState {
  const CategoryInsightGenerateSuccess();
}

/// Insight generation failed
class CategoryInsightGenerateError extends CategoryInsightState {
  const CategoryInsightGenerateError(this.message);
  final String message;
}

/// Controller for category insight operations
class CategoryInsightController extends StateNotifier<CategoryInsightState> {
  CategoryInsightController({
    required this.generateInsightUseCase,
  }) : super(const CategoryInsightInitial());

  final GenerateCategoryInsightUseCase generateInsightUseCase;

  /// Generate or refresh category insight
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    state = const CategoryInsightGenerating();

    final result = await generateInsightUseCase(category, forceRefresh: forceRefresh);

    result.when<void>(
      success: (_) {
        state = const CategoryInsightGenerateSuccess();
      },
      error: (Failure failure) {
        state = CategoryInsightGenerateError(_getErrorMessage(failure));
      },
    );
  }

  /// Reset controller to initial state
  void reset() {
    state = const CategoryInsightInitial();
  }

  /// Map failure to user-friendly error message
  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error. Please check your connection.',
      ServerFailure() => failure.message,
      CacheFailure() => failure.message,
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }
}

/// Provider for category insight controller
final categoryInsightControllerProvider =
    StateNotifierProvider<CategoryInsightController, CategoryInsightState>((ref) {
  final generateInsightUseCase = ref.watch(generateCategoryInsightUseCaseProvider);
  return CategoryInsightController(generateInsightUseCase: generateInsightUseCase);
});
