import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';
import 'package:kairos/features/streak/domain/usecases/calculate_streak_usecase.dart';

/// Use case for calculating and updating user streak with complete orchestration.
/// Handles calculation, persistence, achievements, and sync in a single operation.
///
/// Should be called after user creates a journal entry or during data sync.
class CalculateAndUpdateStreakUseCase {
  CalculateAndUpdateStreakUseCase({
    required this.streakRepository,
    required this.journalRepository,
    this.onAchievementUnlocked,
  });

  final StreakRepository streakRepository;
  final JournalThreadRepository journalRepository;
  final void Function(AchievementEntity)? onAchievementUnlocked;

  Future<Result<StreakEntity>> call(String userId) async {
    try {
      // Calculate new streak using pure calculation use case
      final calculateUseCase = CalculateStreakUseCase(
        streakRepository: streakRepository,
        journalRepository: journalRepository,
      );
      final updatedStreak = await calculateUseCase(userId);

      // Save to local first
      final model = StreakModel.fromEntity(updatedStreak);
      await streakRepository.saveStreak(model);

      // Check for new achievements
      await _checkAndAwardAchievements(updatedStreak);

      // Try to sync to remote (best effort)
      try {
        await streakRepository.syncStreak(userId);
      } on NetworkException catch (e) {
        logger.i('Network error syncing streak (will sync later): ${e.message}');
      } on ServerException catch (e) {
        logger.i('Server error syncing streak (will sync later): ${e.message}');
      }

      return Success(updatedStreak);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to calculate and update streak: $e'));
    }
  }

  /// Check if user has earned any new achievements
  Future<void> _checkAndAwardAchievements(StreakEntity streak) async {
    final existingAchievements = await streakRepository.getAchievements(streak.userId);
    final existingTypes = existingAchievements.dataOrNull?.map((a) => a.typeIndex).toSet() ?? {};

    // Check streak milestones
    final achievementsToAward = <AchievementType>[];

    if (streak.currentStreak >= 7 && !existingTypes.contains(AchievementType.streak7.index)) {
      achievementsToAward.add(AchievementType.streak7);
    }
    if (streak.currentStreak >= 30 && !existingTypes.contains(AchievementType.streak30.index)) {
      achievementsToAward.add(AchievementType.streak30);
    }
    if (streak.currentStreak >= 100 && !existingTypes.contains(AchievementType.streak100.index)) {
      achievementsToAward.add(AchievementType.streak100);
    }
    if (streak.currentStreak >= 365 && !existingTypes.contains(AchievementType.streak365.index)) {
      achievementsToAward.add(AchievementType.streak365);
    }

    // First entry achievement
    if (streak.totalActiveDays == 1 && !existingTypes.contains(AchievementType.firstEntry.index)) {
      achievementsToAward.add(AchievementType.firstEntry);
    }

    // Award new achievements
    for (final type in achievementsToAward) {
      final achievement = AchievementModel.create(userId: streak.userId, type: type);
      await streakRepository.saveAchievement(achievement);

      try {
        await streakRepository.syncStreak(streak.userId);
      } catch (e) {
        logger.i('Failed to sync achievement to remote: $e');
      }

      logger.i('🎉 Achievement unlocked for ${streak.userId}: ${type.name}');

      // Trigger celebration callback
      onAchievementUnlocked?.call(achievement.toEntity());
    }
  }
}
