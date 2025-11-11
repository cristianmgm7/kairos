import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/usecases/generate_global_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/generate_thread_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/sync_insights_usecase.dart';

/// States for insight operations
abstract class InsightState {
  const InsightState();
}

class InsightInitial extends InsightState {
  const InsightInitial();
}

class InsightLoading extends InsightState {
  const InsightLoading();
}

class InsightSuccess extends InsightState {
  const InsightSuccess();
}

class InsightError extends InsightState {
  const InsightError(this.message);
  final String message;
}

/// Controller for insight generation and sync operations
/// Follows MessageController pattern
class InsightController extends StateNotifier<InsightState> {
  InsightController({
    required this.generateThreadInsightUseCase,
    required this.generateGlobalInsightUseCase,
    required this.syncInsightsUseCase,
  }) : super(const InsightInitial());

  final GenerateThreadInsightUseCase generateThreadInsightUseCase;
  final GenerateGlobalInsightUseCase generateGlobalInsightUseCase;
  final SyncInsightsUseCase syncInsightsUseCase;

  /// Generate thread insight (or sync existing)
  Future<void> generateThreadInsight(String threadId) async {
    state = const InsightLoading();

    final result = await generateThreadInsightUseCase.execute(threadId);

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (Failure failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  /// Generate global insight for specific period
  Future<void> generateGlobalInsight({
    required InsightPeriod period,
    bool forceRefresh = false,
  }) async {
    state = const InsightLoading();

    final params = GenerateGlobalInsightParams(
      period: period,
      forceRefresh: forceRefresh,
    );

    final result = await generateGlobalInsightUseCase.execute(params);

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (Failure failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  /// Manual sync of all insights
  Future<void> syncInsights() async {
    state = const InsightLoading();

    final result = await syncInsightsUseCase.execute();

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (Failure failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error. Please check your connection.',
      CacheFailure() => 'Local storage error: ${failure.message}',
      ServerFailure() => 'Server error: ${failure.message}',
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }
}
