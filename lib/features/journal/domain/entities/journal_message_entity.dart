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

/// Single authoritative status modeling the entire message pipeline
enum MessageStatus {
  /// Message created locally but not yet processed
  localCreated,

  /// Media file is being uploaded (audio/image only)
  uploadingMedia,

  /// Media file uploaded successfully
  mediaUploaded,

  /// AI processing in progress (transcription or response generation)
  processingAi,

  /// AI processing completed (transcription/analysis done)
  processed,

  /// Message synced to remote Firestore
  remoteCreated,

  /// Terminal failure state
  failed,
}

/// Detailed substatus for failed state to enable targeted retry
enum FailureReason {
  uploadFailed,
  transcriptionFailed,
  aiResponseFailed,
  remoteCreationFailed,
  networkError,
  unknown,
}

// DEPRECATED: Legacy enums kept for backward compatibility during migration
@Deprecated('Use MessageStatus instead')
enum UploadStatus {
  notStarted,
  uploading,
  completed,
  failed,
  retrying,
}

@Deprecated('Use MessageStatus instead')
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
    required this.updatedAt,
    this.content,
    this.storageUrl,
    this.thumbnailUrl,
    this.localFilePath,
    this.localThumbnailPath,
    this.audioDurationSeconds,
    this.transcription,
    // NEW: Single pipeline status (replaces uploadStatus and aiProcessingStatus)
    this.status = MessageStatus.localCreated,
    this.failureReason,
    // NEW: Progress and error tracking
    this.uploadProgress,
    this.uploadError,
    this.aiError,
    // NEW: Retry tracking (replaces uploadRetryCount and lastUploadAttemptAt)
    this.attemptCount = 0,
    this.lastAttemptAt,
    // NEW: Idempotency
    this.clientLocalId,
    // DEPRECATED: Legacy fields kept for backward compatibility
    @Deprecated('Use status instead') this.aiProcessingStatus = AiProcessingStatus.pending,
    @Deprecated('Use status instead') this.uploadStatus = UploadStatus.notStarted,
    @Deprecated('Use attemptCount instead') this.uploadRetryCount = 0,
    @Deprecated('Use lastAttemptAt instead') this.lastUploadAttemptAt,
    this.metadata,
    this.isTemporary = false,
  });

  final String id;
  final String threadId;
  final String userId;
  final MessageRole role;
  final MessageType messageType;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Content
  final String? content;
  final String? storageUrl;
  final String? thumbnailUrl;
  final String? localFilePath;
  final String? localThumbnailPath;
  final int? audioDurationSeconds;
  final String? transcription;

  // Pipeline status (REPLACES: uploadStatus, aiProcessingStatus)
  final MessageStatus status;
  final FailureReason? failureReason;

  // Progress tracking
  final double? uploadProgress; // 0.0 to 1.0
  final String? uploadError;
  final String? aiError;

  // Retry tracking (REPLACES: uploadRetryCount, lastUploadAttemptAt)
  final int attemptCount;
  final DateTime? lastAttemptAt;

  // Idempotency key for remote writes
  final String? clientLocalId;

  // DEPRECATED: Legacy fields
  @Deprecated('Use status instead')
  final AiProcessingStatus aiProcessingStatus;
  @Deprecated('Use status instead')
  final UploadStatus uploadStatus;
  @Deprecated('Use attemptCount instead')
  final int uploadRetryCount;
  @Deprecated('Use lastAttemptAt instead')
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
        updatedAt,
        content,
        storageUrl,
        thumbnailUrl,
        localFilePath,
        localThumbnailPath,
        audioDurationSeconds,
        transcription,
        status,
        failureReason,
        uploadProgress,
        uploadError,
        aiError,
        attemptCount,
        lastAttemptAt,
        clientLocalId,
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
    DateTime? updatedAt,
    String? content,
    String? storageUrl,
    String? thumbnailUrl,
    String? localFilePath,
    String? localThumbnailPath,
    int? audioDurationSeconds,
    String? transcription,
    MessageStatus? status,
    FailureReason? failureReason,
    double? uploadProgress,
    String? uploadError,
    String? aiError,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? clientLocalId,
    // DEPRECATED: Keep for backward compatibility during migration
    @Deprecated('Use status instead') AiProcessingStatus? aiProcessingStatus,
    @Deprecated('Use status instead') UploadStatus? uploadStatus,
    @Deprecated('Use attemptCount instead') int? uploadRetryCount,
    @Deprecated('Use lastAttemptAt instead') DateTime? lastUploadAttemptAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
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
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      clientLocalId: clientLocalId ?? this.clientLocalId,
      metadata: metadata ?? this.metadata,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
