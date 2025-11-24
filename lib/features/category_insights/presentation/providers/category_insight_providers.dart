import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/category_insights/data/datasources/category_insight_remote_datasource.dart';
import 'package:kairos/features/category_insights/data/repositories/category_insight_repository_impl.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';
import 'package:kairos/features/category_insights/domain/usecases/generate_category_insight_usecase.dart';

// Data source provider
final categoryInsightRemoteDataSourceProvider = Provider<CategoryInsightRemoteDataSource>((ref) {
  return CategoryInsightRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

// Repository provider
final categoryInsightRepositoryProvider = Provider<CategoryInsightRepository>((ref) {
  final remoteDataSource = ref.watch(categoryInsightRemoteDataSourceProvider);
  return CategoryInsightRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use case provider
final generateCategoryInsightUseCaseProvider = Provider<GenerateCategoryInsightUseCase>((ref) {
  final repository = ref.watch(categoryInsightRepositoryProvider);
  return GenerateCategoryInsightUseCase(repository: repository);
});

// Stream provider for all category insights
final allCategoryInsightsProvider = StreamProvider<List<CategoryInsightEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(categoryInsightRepositoryProvider);
  return repository.watchAllInsights(userId);
});

// Provider for a specific category insight
final categoryInsightProvider =
    StreamProvider.family<CategoryInsightEntity?, InsightCategory>((ref, category) {
  final allInsightsAsync = ref.watch(allCategoryInsightsProvider);

  return allInsightsAsync.when(
    data: (insights) {
      try {
        final insight = insights.firstWhere((i) => i.category == category);
        return Stream.value(insight);
      } catch (_) {
        return Stream.value(null);
      }
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
