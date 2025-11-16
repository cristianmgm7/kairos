import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';

class GenerateGlobalInsightParams {
  const GenerateGlobalInsightParams({
    required this.period,
    this.forceRefresh = false,
  });

  final InsightPeriod period;
  final bool forceRefresh; // If true, calls backend to regenerate
}

/// Use case for getting/generating global insights for a specific period
///
/// Behavior:
/// - First checks local DB for cached insight for this period
/// - If not found or forceRefresh=true, calls backend to generate
/// - Returns immediately, insight appears via repository watch stream
class GenerateGlobalInsightUseCase {
  GenerateGlobalInsightUseCase({
    required this.insightRepository,
    required this.authRepository,
    required this.functions,
  });

  final InsightRepository insightRepository;
  final AuthRepository authRepository;
  final FirebaseFunctions functions;

  Future<Result<void>> execute(
    GenerateGlobalInsightParams params,
  ) async {
    try {
      // Get current user
      final user = authRepository.currentUser;
      if (user == null) {
        return const Error<void>(ValidationFailure(message: 'User not authenticated'));
      }

      // Check if we already have insight for this period (unless forcing refresh)
      if (!params.forceRefresh) {
        final existingResult = await insightRepository.getGlobalInsights(user.id);

        final hasInsightForPeriod = existingResult.when(
          success: (insights) {
            // Check if any insight matches the requested period
            return insights.any((insight) => insight.period == params.period);
          },
          error: (_) => false,
        );

        if (hasInsightForPeriod) {
          // Already have insight for this period, no need to regenerate
          return const Success(null);
        }
      }

      // Call backend to generate insight for this period
      final callable = functions.httpsCallable(
        'generatePeriodInsight',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      await callable.call<Map<String, dynamic>>({
        'period': params.period.name,
      });

      // Sync to get the newly generated insight
      await insightRepository.syncInsights(user.id);

      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Error<void>(
        ServerFailure(
          message: 'Failed to generate insight: ${e.message}',
        ),
      );
    } catch (e) {
      return Error<void>(
        ServerFailure(
          message: 'Failed to generate global insight: $e',
        ),
      );
    }
  }
}
