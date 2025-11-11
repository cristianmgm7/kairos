import 'package:equatable/equatable.dart';

enum EmotionType {
  joy,
  calm,
  neutral,
  sadness,
  stress,
  anger,
  fear,
  excitement,
}

enum InsightPeriod {
  oneDay,    // Last 24 hours
  threeDays, // Last 3 days
  oneWeek,   // Last 7 days
  oneMonth,  // Last 30 days
  daily,     // Single day snapshot (for aggregation)
}

enum InsightType {
  thread,       // Per-thread insight
  global,       // Global aggregated insight
  dailyGlobal,  // Single day global snapshot
}

class InsightEntity extends Equatable {
  const InsightEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.periodStart,
    required this.periodEnd,
    required this.moodScore,
    required this.dominantEmotion,
    required this.keywords,
    required this.aiThemes,
    required this.summary,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.threadId, // null for global insights
    this.period, // null for thread insights, set for global insights
    this.guidanceSuggestion, // Placeholder for future Guidance feature
    this.actionPrompt, // Placeholder for future Guidance feature
    this.metadata,
  });

  final String id;
  final String userId;
  final InsightType type;
  final String? threadId; // null for global insights
  final DateTime periodStart;
  final DateTime periodEnd;
  final double moodScore; // 0.0 to 1.0
  final EmotionType dominantEmotion;
  final List<String> keywords; // Top 10 keywords by frequency
  final List<String> aiThemes; // Top 5 AI-extracted themes
  final String summary; // Natural language summary
  final int messageCount; // Number of messages analyzed
  final DateTime createdAt;
  final DateTime updatedAt;
  final InsightPeriod? period; // null for thread insights, set for global insights

  // Future-compatibility fields
  final String? guidanceSuggestion;
  final String? actionPrompt;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        threadId,
        periodStart,
        periodEnd,
        moodScore,
        dominantEmotion,
        keywords,
        aiThemes,
        summary,
        messageCount,
        createdAt,
        updatedAt,
        period,
        guidanceSuggestion,
        actionPrompt,
        metadata,
      ];

  InsightEntity copyWith({
    String? id,
    String? userId,
    InsightType? type,
    String? threadId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? moodScore,
    EmotionType? dominantEmotion,
    List<String>? keywords,
    List<String>? aiThemes,
    String? summary,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    InsightPeriod? period,
    String? guidanceSuggestion,
    String? actionPrompt,
    Map<String, dynamic>? metadata,
  }) {
    return InsightEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      threadId: threadId ?? this.threadId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      moodScore: moodScore ?? this.moodScore,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      keywords: keywords ?? this.keywords,
      aiThemes: aiThemes ?? this.aiThemes,
      summary: summary ?? this.summary,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      period: period ?? this.period,
      guidanceSuggestion: guidanceSuggestion ?? this.guidanceSuggestion,
      actionPrompt: actionPrompt ?? this.actionPrompt,
      metadata: metadata ?? this.metadata,
    );
  }
}
