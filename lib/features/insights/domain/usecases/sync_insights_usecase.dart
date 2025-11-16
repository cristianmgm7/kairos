import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

/// Use case for manually syncing insights from remote
/// Similar to SyncThreadMessagesUseCase pattern
class SyncInsightsUseCase {
  SyncInsightsUseCase({
    required this.insightRepository,
    required this.authRepository,
  });

  final InsightRepository insightRepository;
  final AuthRepository authRepository;

  Future<Result<void>> execute() async {
    try {
      // Get current user
      final user = authRepository.currentUser;
      if (user == null) {
        return const Error<void>(ValidationFailure(message: 'User not authenticated'));
      }

      return await insightRepository.syncInsights(user.id);
    } catch (e) {
      return Error<void>(CacheFailure(message: 'Failed to sync insights: $e'));
    }
  }
}
