import 'package:kairos/features/category_insights/data/datasources/category_insight_remote_datasource.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';

class CategoryInsightRepositoryImpl implements CategoryInsightRepository {
  CategoryInsightRepositoryImpl({required this.remoteDataSource});

  final CategoryInsightRemoteDataSource remoteDataSource;

  @override
  Stream<List<CategoryInsightEntity>> watchAllInsights(String userId) {
    return remoteDataSource
        .watchAllInsights(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    await remoteDataSource.generateInsight(category, forceRefresh: forceRefresh);
  }
}


