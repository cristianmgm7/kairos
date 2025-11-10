import 'package:isar/isar.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:uuid/uuid.dart';

part 'journal_message_model.g.dart';

@collection
class JournalMessageModel {
  JournalMessageModel({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.role,
    required this.messageType,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.content,
    this.storageUrl,
    this.thumbnailUrl,
    this.localFilePath,
    this.localThumbnailPath,
    this.audioDurationSeconds,
    this.transcription,
    this.aiProcessingStatus = 0,
    this.uploadStatus = 0,
    this.uploadRetryCount = 0,
    this.lastUploadAttemptMillis,
    this.isDeleted = false,
    this.version = 1,
  });

  factory JournalMessageModel.createUserMessage({
    required String threadId,
    required String userId,
    required MessageType messageType,
    String? content,
    String? localFilePath,
    String? localThumbnailPath,
    int? audioDurationSeconds,
  }) {
    final now = DateTime.now().toUtc();
    final nowMillis = now.millisecondsSinceEpoch;
    return JournalMessageModel(
      id: const Uuid().v4(),
      threadId: threadId,
      userId: userId,
      role: 0, // user
      messageType: messageType.index,
      content: content,
      localFilePath: localFilePath,
      localThumbnailPath: localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds,
      createdAtMillis: nowMillis,
      updatedAtMillis: nowMillis, // same as created initially
      uploadStatus: messageType == MessageType.text
          ? 2
          : 0, // text=completed, media=notStarted
    );
  }

  factory JournalMessageModel.fromEntity(JournalMessageEntity entity) {
    return JournalMessageModel(
      id: entity.id,
      threadId: entity.threadId,
      userId: entity.userId,
      role: entity.role.index,
      messageType: entity.messageType.index,
      content: entity.content,
      storageUrl: entity.storageUrl,
      thumbnailUrl: entity.thumbnailUrl,
      localFilePath: entity.localFilePath,
      localThumbnailPath: entity.localThumbnailPath,
      audioDurationSeconds: entity.audioDurationSeconds,
      transcription: entity.transcription,
      aiProcessingStatus: entity.aiProcessingStatus.index,
      uploadStatus: entity.uploadStatus.index,
      uploadRetryCount: entity.uploadRetryCount,
      lastUploadAttemptMillis:
          entity.lastUploadAttemptAt?.millisecondsSinceEpoch,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  factory JournalMessageModel.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAtMillis'] as int;
    return JournalMessageModel(
      id: map['id'] as String,
      threadId: map['threadId'] as String,
      userId: map['userId'] as String,
      role: map['role'] as int,
      messageType: map['messageType'] as int,
      content: map['content'] as String?,
      storageUrl: map['storageUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      audioDurationSeconds: map['audioDurationSeconds'] as int?,
      transcription: map['transcription'] as String?,
      aiProcessingStatus: map['aiProcessingStatus'] as int? ?? 0,
      uploadStatus: map['uploadStatus'] as int? ?? 0,
      createdAtMillis: createdAt,
      updatedAtMillis: map['updatedAtMillis'] as int? ?? createdAt, // default to createdAt for backwards compatibility
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String threadId;

  @Index()
  final String userId;

  final int role;
  final int messageType;
  final String? content;
  final String? storageUrl;
  final String? thumbnailUrl;
  final String? localFilePath;
  final String? localThumbnailPath;
  final int? audioDurationSeconds;
  final String? transcription;
  final int aiProcessingStatus;
  final int uploadStatus;
  final int uploadRetryCount;
  final int? lastUploadAttemptMillis;
  final int createdAtMillis;
  @Index()
  final int updatedAtMillis;
  final bool isDeleted;
  final int version;

  Id get isarId => fastHash(id);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'threadId': threadId,
      'userId': userId,
      'role': role,
      'messageType': messageType,
      'content': content,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'audioDurationSeconds': audioDurationSeconds,
      'transcription': transcription,
      'aiProcessingStatus': aiProcessingStatus,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  JournalMessageEntity toEntity() {
    // Validate timestamps to prevent invalid DateTime conversion
    // Valid range for DateTime.fromMillisecondsSinceEpoch is approximately:
    // -8640000000000000 to 8640000000000000
    final validCreatedAt = _isValidTimestamp(createdAtMillis)
        ? createdAtMillis
        : DateTime.now().toUtc().millisecondsSinceEpoch;
    
    final validUpdatedAt = _isValidTimestamp(updatedAtMillis)
        ? updatedAtMillis
        : validCreatedAt;

    return JournalMessageEntity(
      id: id,
      threadId: threadId,
      userId: userId,
      role: MessageRole.values[role],
      messageType: MessageType.values[messageType],
      content: content,
      storageUrl: storageUrl,
      thumbnailUrl: thumbnailUrl,
      localFilePath: localFilePath,
      localThumbnailPath: localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds,
      transcription: transcription,
      aiProcessingStatus: AiProcessingStatus.values[aiProcessingStatus],
      uploadStatus: UploadStatus.values[uploadStatus],
      uploadRetryCount: uploadRetryCount,
      lastUploadAttemptAt: lastUploadAttemptMillis != null &&
              _isValidTimestamp(lastUploadAttemptMillis!)
          ? DateTime.fromMillisecondsSinceEpoch(lastUploadAttemptMillis!,
              isUtc: true)
          : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(validCreatedAt, isUtc: true),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(validUpdatedAt, isUtc: true),
    );
  }

  /// Validates that a timestamp is within the valid range for DateTime
  bool _isValidTimestamp(int millis) {
    // DateTime.fromMillisecondsSinceEpoch valid range
    const minValid = -8640000000000000;
    const maxValid = 8640000000000000;
    return millis >= minValid && millis <= maxValid;
  }

  JournalMessageModel copyWith({
    String? id,
    String? threadId,
    String? userId,
    int? role,
    int? messageType,
    String? content,
    String? storageUrl,
    String? thumbnailUrl,
    String? localFilePath,
    String? localThumbnailPath,
    int? audioDurationSeconds,
    String? transcription,
    int? aiProcessingStatus,
    int? uploadStatus,
    int? uploadRetryCount,
    int? lastUploadAttemptMillis,
    int? createdAtMillis,
    int? updatedAtMillis,
    bool? isDeleted,
    int? version,
  }) {
    return JournalMessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      transcription: transcription ?? this.transcription,
      aiProcessingStatus: aiProcessingStatus ?? this.aiProcessingStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadRetryCount: uploadRetryCount ?? this.uploadRetryCount,
      lastUploadAttemptMillis:
          lastUploadAttemptMillis ?? this.lastUploadAttemptMillis,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
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
