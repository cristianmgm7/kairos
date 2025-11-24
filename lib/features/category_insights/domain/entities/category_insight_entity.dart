import 'package:equatable/equatable.dart';

enum InsightCategory {
  mindsetWellbeing('mindset_wellbeing', 'Mindset & Well-being', '🧠'),
  productivityFocus('productivity_focus', 'Productivity & Focus', '⚡'),
  relationshipsConnection('relationships_connection', 'Relationships & Connection', '💝'),
  careerGrowth('career_growth', 'Career & Growth', '🚀'),
  healthLifestyle('health_lifestyle', 'Health & Lifestyle', '💪'),
  purposeValues('purpose_values', 'Purpose & Values', '🌟');

  const InsightCategory(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static InsightCategory fromString(String value) {
    return InsightCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InsightCategory.mindsetWellbeing,
    );
  }
}

class CategoryInsightEntity extends Equatable {
  const CategoryInsightEntity({
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

  final String userId;
  final InsightCategory category;
  final String summary;
  final List<String> keyPatterns;
  final List<String> strengths;
  final List<String> opportunities;
  final DateTime lastRefreshedAt;
  final int memoryCount;
  final List<String> memoryIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => summary.isEmpty && keyPatterns.isEmpty && memoryCount == 0;

  bool canRefresh(Duration rateLimitDuration) {
    final now = DateTime.now();
    final timeSinceLastRefresh = now.difference(lastRefreshedAt);
    return timeSinceLastRefresh >= rateLimitDuration;
  }

  @override
  List<Object?> get props => [
        userId,
        category,
        summary,
        keyPatterns,
        strengths,
        opportunities,
        lastRefreshedAt,
        memoryCount,
      ];
}


