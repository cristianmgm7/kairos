import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';

abstract class CategoryInsightRepository {
  Stream<List<CategoryInsightEntity>> watchAllInsights(String userId);
  Future<void> generateInsight(String category, {bool forceRefresh});
}
