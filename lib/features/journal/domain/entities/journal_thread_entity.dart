import 'package:equatable/equatable.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';

class JournalThreadEntity extends Equatable {
  const JournalThreadEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.lastMessageAt,
    this.messageCount = 0,
    this.metadata,
    this.isArchived = false,
    this.latestInsightId,
    this.latestInsightSummary,
    this.latestInsightMood,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final DateTime? lastMessageAt;
  final int messageCount;
  final Map<String, dynamic>? metadata;
  final bool isArchived;
  final String? latestInsightId;
  final String? latestInsightSummary;
  final EmotionType? latestInsightMood;

  @override
  List<Object?> get props => [
        id,
        userId,
        createdAt,
        updatedAt,
        title,
        lastMessageAt,
        messageCount,
        metadata,
        isArchived,
        latestInsightId,
        latestInsightSummary,
        latestInsightMood,
      ];

  JournalThreadEntity copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    DateTime? lastMessageAt,
    int? messageCount,
    Map<String, dynamic>? metadata,
    bool? isArchived,
    String? latestInsightId,
    String? latestInsightSummary,
    EmotionType? latestInsightMood,
  }) {
    return JournalThreadEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      metadata: metadata ?? this.metadata,
      isArchived: isArchived ?? this.isArchived,
      latestInsightId: latestInsightId ?? this.latestInsightId,
      latestInsightSummary: latestInsightSummary ?? this.latestInsightSummary,
      latestInsightMood: latestInsightMood ?? this.latestInsightMood,
    );
  }
}
