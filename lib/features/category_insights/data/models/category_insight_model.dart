import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';

class CategoryInsightModel {
  CategoryInsightModel({
    required this.userId,
    required this.category,
    required this.summary,
    required this.keyPatterns,
    required this.strengths,
    required this.opportunities,
    required this.lastRefreshedAt,
    required this.memoryCount,
    required this.memoryIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryInsightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CategoryInsightModel(
      userId: data['userId'] as String,
      category: data['category'] as String,
      summary: data['summary'] as String? ?? '',
      keyPatterns: List<String>.from(data['keyPatterns'] as List? ?? []),
      strengths: List<String>.from(data['strengths'] as List? ?? []),
      opportunities: List<String>.from(data['opportunities'] as List? ?? []),
      lastRefreshedAt: (data['lastRefreshedAt'] as int?) ?? 0,
      memoryCount: (data['memoryCount'] as int?) ?? 0,
      memoryIds: List<String>.from(data['memoryIds'] as List? ?? []),
      createdAt: (data['createdAt'] as int?) ?? 0,
      updatedAt: (data['updatedAt'] as int?) ?? 0,
    );
  }

  final String userId;
  final String category;
  final String summary;
  final List<String> keyPatterns;
  final List<String> strengths;
  final List<String> opportunities;
  final int lastRefreshedAt;
  final int memoryCount;
  final List<String> memoryIds;
  final int createdAt;
  final int updatedAt;

  CategoryInsightEntity toEntity() {
    return CategoryInsightEntity(
      userId: userId,
      category: InsightCategory.fromString(category),
      summary: summary,
      keyPatterns: keyPatterns,
      strengths: strengths,
      opportunities: opportunities,
      lastRefreshedAt: DateTime.fromMillisecondsSinceEpoch(lastRefreshedAt),
      memoryCount: memoryCount,
      memoryIds: memoryIds,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

