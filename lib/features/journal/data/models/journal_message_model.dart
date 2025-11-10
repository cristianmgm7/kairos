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
    // NEW: Single pipeline status
    this.status = 0, // MessageStatus.localCreated
    this.failureReason,
    this.uploadProgress,
    this.uploadError,
    this.aiError,
    this.attemptCount = 0,
    this.lastAttemptMillis,
    this.clientLocalId,
    // DEPRECATED: Legacy fields for backward compatibility
    @Deprecated('Use status instead') this.aiProcessingStatus = 0,
    @Deprecated('Use status instead') this.uploadStatus = 0,
    @Deprecated('Use attemptCount instead') this.uploadRetryCount = 0,
    @Deprecated('Use lastAttemptMillis instead') this.lastUploadAttemptMillis,
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
      status: 0, // MessageStatus.localCreated
      clientLocalId: const Uuid().v4(), // Generate unique ID for idempotency
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
      // NEW fields
      status: entity.status.index,
      failureReason: entity.failureReason?.index,
      uploadProgress: entity.uploadProgress,
      uploadError: entity.uploadError,
      aiError: entity.aiError,
      attemptCount: entity.attemptCount,
      lastAttemptMillis: entity.lastAttemptAt?.millisecondsSinceEpoch,
      clientLocalId: entity.clientLocalId,
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
      // NEW fields
      status: map['status'] as int? ?? 0, // default to localCreated
      failureReason: map['failureReason'] as int?,
      uploadProgress: (map['uploadProgress'] as num?)?.toDouble(),
      uploadError: map['uploadError'] as String?,
      aiError: map['aiError'] as String?,
      attemptCount: map['attemptCount'] as int? ?? 0,
      lastAttemptMillis: map['lastAttemptMillis'] as int?,
      clientLocalId: map['clientLocalId'] as String?,
      createdAtMillis: createdAt,
      updatedAtMillis: map['updatedAtMillis'] as int? ??
          createdAt, // default to createdAt for backwards compatibility
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

  // NEW: Single pipeline status fields
  @enumerated
  final int status; // MessageStatus enum index
  final int? failureReason; // FailureReason enum index
  final double? uploadProgress;
  final String? uploadError;
  final String? aiError;
  final int attemptCount;
  final int? lastAttemptMillis;
  final String? clientLocalId;

  // DEPRECATED: Legacy fields
  @Deprecated('Use status instead')
  final int aiProcessingStatus;
  @Deprecated('Use status instead')
  final int uploadStatus;
  @Deprecated('Use attemptCount instead')
  final int uploadRetryCount;
  @Deprecated('Use lastAttemptMillis instead')
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
      // NEW fields
      'status': status,
      'failureReason': failureReason,
      'uploadProgress': uploadProgress,
      'uploadError': uploadError,
      'aiError': aiError,
      'attemptCount': attemptCount,
      'lastAttemptMillis': lastAttemptMillis,
      'clientLocalId': clientLocalId,
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

    final validUpdatedAt = _isValidTimestamp(updatedAtMillis) ? updatedAtMillis : validCreatedAt;

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
      // NEW fields
      status: MessageStatus.values[status],
      failureReason: failureReason != null ? FailureReason.values[failureReason!] : null,
      uploadProgress: uploadProgress,
      uploadError: uploadError,
      aiError: aiError,
      attemptCount: attemptCount,
      lastAttemptAt:
          lastAttemptMillis != null && _isValidTimestamp(lastAttemptMillis!)
              ? DateTime.fromMillisecondsSinceEpoch(lastAttemptMillis!, isUtc: true)
              : null,
      clientLocalId: clientLocalId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(validCreatedAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(validUpdatedAt, isUtc: true),
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
    int? status,
    int? failureReason,
    double? uploadProgress,
    String? uploadError,
    String? aiError,
    int? attemptCount,
    int? lastAttemptMillis,
    String? clientLocalId,
    // DEPRECATED: Keep for backward compatibility during migration
    @Deprecated('Use status instead') int? aiProcessingStatus,
    @Deprecated('Use status instead') int? uploadStatus,
    @Deprecated('Use attemptCount instead') int? uploadRetryCount,
    @Deprecated('Use lastAttemptMillis instead') int? lastUploadAttemptMillis,
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
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadError: uploadError ?? this.uploadError,
      aiError: aiError ?? this.aiError,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptMillis: lastAttemptMillis ?? this.lastAttemptMillis,
      clientLocalId: clientLocalId ?? this.clientLocalId,
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
