import 'package:equatable/equatable.dart';

enum JournalEntryType {
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

class JournalEntryEntity extends Equatable {
  const JournalEntryEntity({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.createdAt,
    required this.updatedAt,
    this.textContent,
    this.storageUrl,
    this.thumbnailUrl,
    this.audioDurationSeconds,
    this.transcription,
    this.metadata,
    this.aiProcessingStatus = AiProcessingStatus.pending,
    this.uploadStatus = UploadStatus.notStarted,
    this.needsSync = false,
  });

  final String id;
  final String userId;
  final JournalEntryType entryType;
  final DateTime createdAt; // Always UTC
  final DateTime updatedAt; // Always UTC

  // Content fields (type-specific)
  final String? textContent;
  final String? storageUrl; // Firebase Storage URL for image/audio
  final String? thumbnailUrl; // Thumbnail URL for images
  final int? audioDurationSeconds;

  // AI fields (populated later by Cloud Functions)
  final String? transcription;
  final AiProcessingStatus aiProcessingStatus;

  // Sync fields
  final UploadStatus uploadStatus;
  final bool needsSync; // Flag for retry queue

  // Future extensibility (AI tags, geolocation, etc.)
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        userId,
        entryType,
        createdAt,
        updatedAt,
        textContent,
        storageUrl,
        thumbnailUrl,
        audioDurationSeconds,
        transcription,
        metadata,
        aiProcessingStatus,
        uploadStatus,
        needsSync,
      ];

  JournalEntryEntity copyWith({
    String? id,
    String? userId,
    JournalEntryType? entryType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? textContent,
    String? storageUrl,
    String? thumbnailUrl,
    int? audioDurationSeconds,
    String? transcription,
    Map<String, dynamic>? metadata,
    AiProcessingStatus? aiProcessingStatus,
    UploadStatus? uploadStatus,
    bool? needsSync,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryType: entryType ?? this.entryType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      textContent: textContent ?? this.textContent,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      transcription: transcription ?? this.transcription,
      metadata: metadata ?? this.metadata,
      aiProcessingStatus: aiProcessingStatus ?? this.aiProcessingStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}
