import 'package:isar/isar.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';

part 'insight_model.g.dart';

@collection
class InsightModel {
  InsightModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.periodStartMillis,
    required this.periodEndMillis,
    required this.moodScore,
    required this.dominantEmotion,
    required this.keywords,
    required this.aiThemes,
    required this.summary,
    required this.messageCount,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.threadId,
    this.period,
    this.guidanceSuggestion,
    this.actionPrompt,
    this.isDeleted = false,
    this.version = 1,
  });

  /// Factory constructor for creating new insights
  factory InsightModel.create({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double moodScore,
    required int dominantEmotion,
    required List<String> keywords,
    required List<String> aiThemes,
    required String summary,
    required int messageCount,
    String? threadId,
  }) {
    final now = DateTime.now().toUtc();
    final startMillis = periodStart.millisecondsSinceEpoch;
    final insightType = threadId != null ? 0 : 1; // 0=thread, 1=global
    final insightId =
        threadId != null ? '${userId}_${threadId}_$startMillis' : '${userId}_global_$startMillis';

    return InsightModel(
      id: insightId,
      userId: userId,
      type: insightType,
      threadId: threadId,
      periodStartMillis: startMillis,
      periodEndMillis: periodEnd.millisecondsSinceEpoch,
      moodScore: moodScore,
      dominantEmotion: dominantEmotion,
      keywords: keywords,
      aiThemes: aiThemes,
      summary: summary,
      messageCount: messageCount,
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  factory InsightModel.fromEntity(InsightEntity entity) {
    return InsightModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type.value,
      threadId: entity.threadId,
      period: entity.period?.name, // Convert enum to string
      periodStartMillis: entity.periodStart.millisecondsSinceEpoch,
      periodEndMillis: entity.periodEnd.millisecondsSinceEpoch,
      moodScore: entity.moodScore,
      dominantEmotion: entity.dominantEmotion.value,
      keywords: entity.keywords,
      aiThemes: entity.aiThemes,
      summary: entity.summary,
      messageCount: entity.messageCount,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
      guidanceSuggestion: entity.guidanceSuggestion,
      actionPrompt: entity.actionPrompt,
    );
  }

  factory InsightModel.fromMap(Map<String, dynamic> map) {
    return InsightModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as int,
      threadId: map['threadId'] as String?,
      period: map['period'] as String?,
      periodStartMillis: map['periodStartMillis'] as int,
      periodEndMillis: map['periodEndMillis'] as int,
      moodScore: (map['moodScore'] as num).toDouble(),
      dominantEmotion: map['dominantEmotion'] as int,
      keywords: List<String>.from(map['keywords'] as List),
      aiThemes: List<String>.from(map['aiThemes'] as List),
      summary: map['summary'] as String,
      messageCount: map['messageCount'] as int,
      createdAtMillis: map['createdAtMillis'] as int,
      updatedAtMillis: map['updatedAtMillis'] as int,
      guidanceSuggestion: map['guidanceSuggestion'] as String?,
      actionPrompt: map['actionPrompt'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final int type; // 0=thread, 1=global, 2=dailyGlobal (InsightType.value)

  @Index()
  final String? threadId; // null for global insights

  final String? period; // Stored as string for Firestore/Isar compatibility

  final int periodStartMillis;
  final int periodEndMillis;
  final double moodScore;
  final int dominantEmotion; // EmotionType.value
  final List<String> keywords;
  final List<String> aiThemes;
  final String summary;
  final int messageCount;
  final int createdAtMillis;
  final int updatedAtMillis;

  // Future-compatibility fields
  final String? guidanceSuggestion;
  final String? actionPrompt;

  final bool isDeleted;
  final int version;

  Id get isarId => fastHash(id);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'threadId': threadId,
      'period': period,
      'periodStartMillis': periodStartMillis,
      'periodEndMillis': periodEndMillis,
      'moodScore': moodScore,
      'dominantEmotion': dominantEmotion,
      'keywords': keywords,
      'aiThemes': aiThemes,
      'summary': summary,
      'messageCount': messageCount,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'guidanceSuggestion': guidanceSuggestion,
      'actionPrompt': actionPrompt,
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  InsightEntity toEntity() {
    return InsightEntity(
      id: id,
      userId: userId,
      type: InsightType.fromInt(type),
      periodStart: DateTime.fromMillisecondsSinceEpoch(periodStartMillis, isUtc: true),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(periodEndMillis, isUtc: true),
      moodScore: moodScore,
      dominantEmotion: EmotionType.fromInt(dominantEmotion),
      keywords: keywords,
      aiThemes: aiThemes,
      summary: summary,
      messageCount: messageCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis, isUtc: true),
      threadId: threadId,
      period: period != null
          ? InsightPeriod.values.firstWhere((e) => e.name == period)
          : null,
      guidanceSuggestion: guidanceSuggestion,
      actionPrompt: actionPrompt,
    );
  }

  InsightModel copyWith({
    String? id,
    String? userId,
    int? type,
    String? threadId,
    String? period,
    int? periodStartMillis,
    int? periodEndMillis,
    double? moodScore,
    int? dominantEmotion,
    List<String>? keywords,
    List<String>? aiThemes,
    String? summary,
    int? messageCount,
    int? createdAtMillis,
    int? updatedAtMillis,
    String? guidanceSuggestion,
    String? actionPrompt,
    bool? isDeleted,
    int? version,
  }) {
    return InsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      threadId: threadId ?? this.threadId,
      period: period ?? this.period,
      periodStartMillis: periodStartMillis ?? this.periodStartMillis,
      periodEndMillis: periodEndMillis ?? this.periodEndMillis,
      moodScore: moodScore ?? this.moodScore,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      keywords: keywords ?? this.keywords,
      aiThemes: aiThemes ?? this.aiThemes,
      summary: summary ?? this.summary,
      messageCount: messageCount ?? this.messageCount,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      guidanceSuggestion: guidanceSuggestion ?? this.guidanceSuggestion,
      actionPrompt: actionPrompt ?? this.actionPrompt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  int fastHash(String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}
