import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

/// Use case for triggering thread insight generation
///
/// This does NOT generate the insight itself - it calls the backend
/// Cloud Function which handles AI analysis.
/// The generated insight will appear via the repository watch stream.
class GenerateThreadInsightUseCase {
  GenerateThreadInsightUseCase({
    required this.insightRepository,
    required this.authRepository,
  });

  final InsightRepository insightRepository;
  final AuthRepository authRepository;

  /// Request thread insight generation
  /// Returns immediately - insight appears via stream when backend completes
  Future<Result<void>> execute(String threadId) async {
    try {
      // Get current user
      final user = authRepository.currentUser;
      if (user == null) {
        return const Error<void>(ValidationFailure(message: 'User not authenticated'));
      }

      // Note: Current backend generateInsight trigger fires on AI message creation
      // This use case is for future manual refresh capability
      // For now, we just trigger a sync to fetch any new insights

      // Sync insights from remote to ensure we have latest
      final syncResult = await insightRepository.syncInsights(user.id);

      return syncResult.when(
        success: (_) => const Success(null),
        error: Error.new,
      );
    } catch (e) {
      return Error<void>(ServerFailure(message: 'Failed to sync thread insight: $e'));
    }
  }
}
