import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

abstract class InsightRepository {
  Future<Result<InsightEntity?>> getInsightById(String insightId);
  Future<Result<List<InsightEntity>>> getGlobalInsights(String userId);
  Future<Result<List<InsightEntity>>> getThreadInsights(String threadId);
  Stream<List<InsightEntity>> watchGlobalInsights(String userId);
  Stream<List<InsightEntity>> watchThreadInsights(String threadId);
  Future<Result<void>> syncInsights(String userId);
}
