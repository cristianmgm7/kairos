import 'package:isar/isar.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:uuid/uuid.dart';

part 'journal_thread_model.g.dart';

@collection
class JournalThreadModel {
  JournalThreadModel({
    required this.id,
    required this.userId,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.title,
    this.lastMessageAtMillis,
    this.messageCount = 0,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAtMillis,
    this.version = 1,
    this.latestInsightId,
    this.latestInsightSummary,
    this.latestInsightMood,
  });

  factory JournalThreadModel.create({
    required String userId,
    String? title,
  }) {
    final now = DateTime.now().toUtc();
    return JournalThreadModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  factory JournalThreadModel.fromEntity(JournalThreadEntity entity) {
    return JournalThreadModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
      lastMessageAtMillis: entity.lastMessageAt?.millisecondsSinceEpoch,
      messageCount: entity.messageCount,
      isArchived: entity.isArchived,
      latestInsightId: entity.latestInsightId,
      latestInsightSummary: entity.latestInsightSummary,
      latestInsightMood: entity.latestInsightMood?.name, // Convert enum to string
    );
  }

  factory JournalThreadModel.fromMap(Map<String, dynamic> map) {
    // Helper to safely convert dynamic value to String?
    // Handles cases where Firestore might store int values that should be strings
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is num) return value.toString();
      return value.toString();
    }

    return JournalThreadModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String?,
      createdAtMillis: map['createdAtMillis'] as int,
      updatedAtMillis: map['updatedAtMillis'] as int,
      lastMessageAtMillis: map['lastMessageAtMillis'] as int?,
      messageCount: map['messageCount'] as int? ?? 0,
      isArchived: map['isArchived'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      deletedAtMillis: map['deletedAtMillis'] as int?,
      version: map['version'] as int? ?? 1,
      latestInsightId: toStringOrNull(map['latestInsightId']),
      latestInsightSummary: toStringOrNull(map['latestInsightSummary']),
      latestInsightMood: toStringOrNull(map['latestInsightMood']),
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final String? title;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int? lastMessageAtMillis;
  final int messageCount;
  final bool isArchived;
  final bool isDeleted;
  final int? deletedAtMillis;
  final int version;
  final String? latestInsightId;
  final String? latestInsightSummary;
  final String? latestInsightMood; // Store as string (emotion enum name)

  Id get isarId => fastHash(id);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'lastMessageAtMillis': lastMessageAtMillis,
      'messageCount': messageCount,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'deletedAtMillis': deletedAtMillis,
      'version': version,
      'latestInsightId': latestInsightId,
      'latestInsightSummary': latestInsightSummary,
      'latestInsightMood': latestInsightMood,
    };
  }

  JournalThreadEntity toEntity() {
    // Safely convert latestInsightMood string to EmotionType enum
    EmotionType? mood;
    if (latestInsightMood != null) {
      try {
        mood = EmotionType.values.firstWhere(
          (e) => e.name == latestInsightMood,
          orElse: () => EmotionType.values.first, // Fallback to first enum value
        );
      } catch (e) {
        // If conversion fails, log and set to null
        logger.w('Failed to convert latestInsightMood "$latestInsightMood" to EmotionType: $e');
        mood = null;
      }
    }

    return JournalThreadEntity(
      id: id,
      userId: userId,
      title: title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis, isUtc: true),
      lastMessageAt: lastMessageAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMessageAtMillis!, isUtc: true)
          : null,
      messageCount: messageCount,
      isArchived: isArchived,
      latestInsightId: latestInsightId,
      latestInsightSummary: latestInsightSummary,
      latestInsightMood: mood,
    );
  }

  JournalThreadModel copyWith({
    String? id,
    String? userId,
    String? title,
    int? createdAtMillis,
    int? updatedAtMillis,
    int? lastMessageAtMillis,
    int? messageCount,
    bool? isArchived,
    bool? isDeleted,
    int? deletedAtMillis,
    int? version,
    String? latestInsightId,
    String? latestInsightSummary,
    String? latestInsightMood,
  }) {
    return JournalThreadModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      lastMessageAtMillis: lastMessageAtMillis ?? this.lastMessageAtMillis,
      messageCount: messageCount ?? this.messageCount,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
      version: version ?? this.version,
      latestInsightId: latestInsightId ?? this.latestInsightId,
      latestInsightSummary: latestInsightSummary ?? this.latestInsightSummary,
      latestInsightMood: latestInsightMood ?? this.latestInsightMood,
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
