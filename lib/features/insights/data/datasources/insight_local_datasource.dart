import 'package:isar/isar.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';

abstract class InsightLocalDataSource {
  Future<void> saveInsight(InsightModel insight);
  Future<InsightModel?> getInsightById(String insightId);
  Future<List<InsightModel>> getInsightsByUserId(String userId);
  Future<List<InsightModel>> getGlobalInsights(String userId);
  Future<List<InsightModel>> getThreadInsights(String threadId);
  Stream<List<InsightModel>> watchGlobalInsights(String userId);
  Stream<List<InsightModel>> watchThreadInsights(String threadId);
  Future<void> updateInsight(InsightModel insight);
  Future<void> deleteInsight(String insightId);
}

class InsightLocalDataSourceImpl implements InsightLocalDataSource {
  InsightLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveInsight(InsightModel insight) async {
    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });
  }

  @override
  Future<InsightModel?> getInsightById(String insightId) async {
    return isar.insightModels
        .filter()
        .idEqualTo(insightId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<InsightModel>> getInsightsByUserId(String userId) async {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Future<List<InsightModel>> getGlobalInsights(String userId) async {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .threadIdIsNull()
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Future<List<InsightModel>> getThreadInsights(String threadId) async {
    return isar.insightModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Stream<List<InsightModel>> watchGlobalInsights(String userId) {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .threadIdIsNull()
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((insights) {
      final sorted = insights.toList()
        ..sort((a, b) => b.periodEndMillis.compareTo(a.periodEndMillis));
      return sorted;
    });
  }

  @override
  Stream<List<InsightModel>> watchThreadInsights(String threadId) {
    return isar.insightModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((insights) {
      final sorted = insights.toList()
        ..sort((a, b) => b.periodEndMillis.compareTo(a.periodEndMillis));
      return sorted;
    });
  }

  @override
  Future<void> updateInsight(InsightModel insight) async {
    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });
  }

  @override
  Future<void> deleteInsight(String insightId) async {
    await isar.writeTxn(() async {
      final insight = await isar.insightModels.filter().idEqualTo(insightId).findFirst();

      if (insight != null) {
        final deleted = insight.copyWith(isDeleted: true);
        await isar.insightModels.put(deleted);
      }
    });
  }
}
