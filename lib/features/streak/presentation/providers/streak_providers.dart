import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:kairos/features/streak/data/datasources/streak_remote_datasource.dart';
import 'package:kairos/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';
import 'package:kairos/features/streak/domain/usecases/calculate_and_update_streak_usecase.dart';

// ============ Data Source Providers ============

final streakLocalDataSourceProvider = Provider<StreakLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return StreakLocalDataSourceImpl(isar);
});

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StreakRemoteDataSourceImpl(firestore);
});

// ============ Repository Provider ============

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final localDataSource = ref.watch(streakLocalDataSourceProvider);
  final remoteDataSource = ref.watch(streakRemoteDataSourceProvider);

  return StreakRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// ============ Stream Providers ============

/// Watch current user's streak data
final currentStreakProvider = StreamProvider<StreakEntity?>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchStreak(userId);
});

/// Watch current user's achievements
final achievementsProvider = StreamProvider<List<AchievementEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchAchievements(userId);
});

// Alias for backwards compatibility
final currentAchievementsProvider = achievementsProvider;

/// Watch current user's daily activity data for the past year
final dailyActivitiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchDailyActivities(userId);
});

// ============ Action Providers ============

/// Trigger streak calculation (call after journal entry created)
final calculateAndUpdateStreakUseCaseProvider = Provider<CalculateAndUpdateStreakUseCase>((ref) {
  final streakRepository = ref.watch(streakRepositoryProvider);
  final journalRepository = ref.watch(threadRepositoryProvider);
  final celebrationHandler = ref.read(achievementCelebrationProvider);

  return CalculateAndUpdateStreakUseCase(
    streakRepository: streakRepository,
    journalRepository: journalRepository,
    onAchievementUnlocked: celebrationHandler,
  );
});

/// Convenience provider for triggering streak calculation
final calculateStreakProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final user = ref.read(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      logger.w('Cannot calculate streak: no user logged in');
      return;
    }

    final useCase = ref.read(calculateAndUpdateStreakUseCaseProvider);
    final result = await useCase(userId);

    result.when(
      success: (StreakEntity streak) {
        logger.i('Streak updated: current=${streak.currentStreak}');
      },
      error: (Failure failure) {
        logger.e('Failed to calculate streak: ${failure.message}');
      },
    );
  };
});

/// Provider that handles achievement celebrations
final achievementCelebrationProvider = Provider<Future<void> Function(AchievementEntity)>((ref) {
  return (achievement) async {
    logger.i('🎉 Achievement unlocked: ${achievement.type.name}');

    // We'll implement the dialog showing in Phase 5.3 when we have better context access
    // For now, the celebration is logged and will be shown in the UI
  };
});
