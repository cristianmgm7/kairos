import 'package:equatable/equatable.dart';

enum MessageRole {
  user, // Human-created content
  ai, // AI-generated responses
  system, // App-generated metadata
}

enum MessageType {
  text,
  image,
  audio,
}

enum UploadStatus {
  notStarted,
  uploading,
  completed,
  failed,
  retrying,
}

enum AiProcessingStatus {
  pending,
  processing,
  completed,
  failed,
}

class JournalMessageEntity extends Equatable {
  const JournalMessageEntity({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.role,
    required this.messageType,
    required this.createdAt,
    this.content,
    this.storageUrl,
    this.thumbnailUrl,
    this.localFilePath,
    this.localThumbnailPath,
    this.audioDurationSeconds,
    this.transcription,
    this.aiProcessingStatus = AiProcessingStatus.pending,
    this.uploadStatus = UploadStatus.notStarted,
    this.uploadRetryCount = 0,
    this.lastUploadAttemptAt,
    this.metadata,
    this.isTemporary = false,
  });

  final String id;
  final String threadId;
  final String userId;
  final MessageRole role;
  final MessageType messageType;
  final DateTime createdAt;

  // Content
  final String? content;
  final String? storageUrl;
  final String? thumbnailUrl;
  final String? localFilePath;
  final String? localThumbnailPath;
  final int? audioDurationSeconds;
  final String? transcription;

  // Processing
  final AiProcessingStatus aiProcessingStatus;
  final UploadStatus uploadStatus;
  final int uploadRetryCount;
  final DateTime? lastUploadAttemptAt;

  // Extensibility
  final Map<String, dynamic>? metadata;

  /// Indicates if this is a temporary local-only message (e.g., typing indicator)
  final bool isTemporary;

  @override
  List<Object?> get props => [
        id,
        threadId,
        userId,
        role,
        messageType,
        createdAt,
        content,
        storageUrl,
        thumbnailUrl,
        localFilePath,
        localThumbnailPath,
        audioDurationSeconds,
        transcription,
        aiProcessingStatus,
        uploadStatus,
        uploadRetryCount,
        lastUploadAttemptAt,
        metadata,
        isTemporary,
      ];

  JournalMessageEntity copyWith({
    String? id,
    String? threadId,
    String? userId,
    MessageRole? role,
    MessageType? messageType,
    DateTime? createdAt,
    String? content,
    String? storageUrl,
    String? thumbnailUrl,
    String? localFilePath,
    String? localThumbnailPath,
    int? audioDurationSeconds,
    String? transcription,
    AiProcessingStatus? aiProcessingStatus,
    UploadStatus? uploadStatus,
    int? uploadRetryCount,
    DateTime? lastUploadAttemptAt,
    Map<String, dynamic>? metadata,
    bool? isTemporary,
  }) {
    return JournalMessageEntity(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
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
      lastUploadAttemptAt: lastUploadAttemptAt ?? this.lastUploadAttemptAt,
      metadata: metadata ?? this.metadata,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
