import 'package:equatable/equatable.dart';

enum MessageRole {
  user(value: 0), // Human-created content
  ai(value: 1), // AI-generated responses
  system(value: 2); // App-generated metadata

  const MessageRole({required this.value});

  final int value;

  static MessageRole fromInt(int code) {
    return MessageRole.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageRole.user,
    );
  }
}

enum MessageType {
  text(value: 0),
  image(value: 1),
  audio(value: 2);

  const MessageType({required this.value});

  final int value;

  static MessageType fromInt(int code) {
    return MessageType.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageType.text,
    );
  }
}

/// Single authoritative status modeling the entire message pipeline
enum MessageStatus {
  /// Message created locally but not yet processed
  localCreated(value: 0),

  /// Media file is being uploaded (audio/image only)
  uploadingMedia(value: 1),

  /// Media file uploaded successfully
  mediaUploaded(value: 2),

  /// AI processing in progress (transcription or response generation)
  processingAi(value: 3),

  /// AI processing completed (transcription/analysis done)
  processed(value: 4),

  /// Message synced to remote Firestore
  remoteCreated(value: 5),

  /// Terminal failure state
  failed(value: 6);

  const MessageStatus({required this.value});

  final int value;

  static MessageStatus fromInt(int code) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageStatus.localCreated,
    );
  }
}

/// Detailed substatus for failed state to enable targeted retry
enum FailureReason {
  uploadFailed(value: 0),
  transcriptionFailed(value: 1),
  aiResponseFailed(value: 2),
  remoteCreationFailed(value: 3),
  networkError(value: 4),
  unknown(value: 5);

  const FailureReason({required this.value});

  final int value;

  static FailureReason fromInt(int code) {
    return FailureReason.values.firstWhere(
      (e) => e.value == code,
      orElse: () => FailureReason.unknown,
    );
  }
}

// DEPRECATED: Legacy enums kept for backward compatibility during migration
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
