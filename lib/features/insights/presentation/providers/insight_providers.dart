import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/insights/data/datasources/insight_local_datasource.dart';
import 'package:kairos/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:kairos/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';
import 'package:kairos/features/insights/domain/usecases/generate_global_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/generate_thread_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/sync_insights_usecase.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';
import 'package:kairos/features/insights/presentation/controllers/insight_controller.dart';

// Data source providers
final insightLocalDataSourceProvider = Provider<InsightLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return InsightLocalDataSourceImpl(isar);
});

final insightRemoteDataSourceProvider = Provider<InsightRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InsightRemoteDataSourceImpl(firestore);
});

// Repository provider
final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final localDataSource = ref.watch(insightLocalDataSourceProvider);
  final remoteDataSource = ref.watch(insightRemoteDataSourceProvider);

  return InsightRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// Stream providers
final globalInsightsStreamProvider =
    StreamProvider.family<List<InsightEntity>, String>((ref, userId) {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchGlobalInsights(userId);
});

final threadInsightsStreamProvider =
    StreamProvider.family<List<InsightEntity>, String>((ref, threadId) {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchThreadInsights(threadId);
});

// Current user's global insights (convenience provider)
final currentUserGlobalInsightsProvider = StreamProvider<List<InsightEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchGlobalInsights(userId);
});

// Use case providers
final generateThreadInsightUseCaseProvider = Provider<GenerateThreadInsightUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return GenerateThreadInsightUseCase(
    insightRepository: repository,
    authRepository: authRepository,
  );
});

final generateGlobalInsightUseCaseProvider = Provider<GenerateGlobalInsightUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return GenerateGlobalInsightUseCase(
    insightRepository: repository,
    authRepository: authRepository,
    functions: FirebaseFunctions.instance,
  );
});

final syncInsightsUseCaseProvider = Provider<SyncInsightsUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return SyncInsightsUseCase(
    insightRepository: repository,
    authRepository: authRepository,
  );
});

// Stream provider for period-filtered global insights
final globalInsightsByPeriodProvider = StreamProvider.family<InsightEntity?, (String, InsightPeriod)>(
  (ref, params) {
    final (userId, period) = params;
    final repository = ref.watch(insightRepositoryProvider);

    return repository.watchGlobalInsights(userId).map(
      (insights) {
        try {
          return insights.firstWhere((insight) => insight.period == period);
        } catch (_) {
          return null;
        }
      },
    );
  },
);

// Controller provider
final insightControllerProvider = StateNotifierProvider<InsightController, InsightState>((ref) {
  final generateThreadUseCase = ref.watch(generateThreadInsightUseCaseProvider);
  final generateGlobalUseCase = ref.watch(generateGlobalInsightUseCaseProvider);
  final syncUseCase = ref.watch(syncInsightsUseCaseProvider);

  return InsightController(
    generateThreadInsightUseCase: generateThreadUseCase,
    generateGlobalInsightUseCase: generateGlobalUseCase,
    syncInsightsUseCase: syncUseCase,
  );
});
