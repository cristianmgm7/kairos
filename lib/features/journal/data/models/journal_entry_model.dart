import 'package:isar/isar.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:uuid/uuid.dart';

part 'journal_entry_model.g.dart';

@collection
class JournalEntryModel {
  JournalEntryModel({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.createdAtMillis,
    required this.modifiedAtMillis,
    this.textContent,
    this.storageUrl,
    this.localFilePath,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.audioDurationSeconds,
    this.transcription,
    this.aiProcessingStatus = 0, // pending
    this.uploadStatus = 0, // notStarted
    this.uploadRetryCount = 0,
    this.lastUploadAttemptMillis,
    this.needsSync = false,
    this.isDeleted = false,
    this.version = 1,
  });

  factory JournalEntryModel.create({
    required String userId,
    required JournalEntryType entryType,
    String? textContent,
    String? localFilePath,
    String? localThumbnailPath,
    int? audioDurationSeconds,
  }) {
    final now = DateTime.now().toUtc(); // Always use UTC
    return JournalEntryModel(
      id: const Uuid().v4(),
      userId: userId,
      entryType: entryType.index,
      textContent: textContent,
      localFilePath: localFilePath,
      localThumbnailPath: localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds,
      createdAtMillis: now.millisecondsSinceEpoch,
      modifiedAtMillis: now.millisecondsSinceEpoch,
      needsSync: entryType != JournalEntryType.text, // Media entries need upload
    );
  }

  factory JournalEntryModel.fromEntity(JournalEntryEntity entity) {
    return JournalEntryModel(
      id: entity.id,
      userId: entity.userId,
      entryType: entity.entryType.index,
      textContent: entity.textContent,
      storageUrl: entity.storageUrl,
      thumbnailUrl: entity.thumbnailUrl,
      audioDurationSeconds: entity.audioDurationSeconds,
      transcription: entity.transcription,
      aiProcessingStatus: entity.aiProcessingStatus.index,
      uploadStatus: entity.uploadStatus.index,
      needsSync: entity.needsSync,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      modifiedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map) {
    return JournalEntryModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      entryType: map['entryType'] as int,
      textContent: map['textContent'] as String?,
      storageUrl: map['storageUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      audioDurationSeconds: map['audioDurationSeconds'] as int?,
      transcription: map['transcription'] as String?,
      aiProcessingStatus: map['aiProcessingStatus'] as int? ?? 0,
      uploadStatus: map['uploadStatus'] as int? ?? 0,
      createdAtMillis: map['createdAtMillis'] as int,
      modifiedAtMillis: map['modifiedAtMillis'] as int,
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final int entryType; // 0=text, 1=image, 2=audio
  final String? textContent;
  final String? storageUrl;
  final String? localFilePath; // For offline access
  final String? thumbnailUrl;
  final String? localThumbnailPath; // For offline thumbnail
  final int? audioDurationSeconds;
  final String? transcription;
  final int aiProcessingStatus; // 0=pending, 1=processing, 2=completed, 3=failed
  final int uploadStatus; // 0=notStarted, 1=uploading, 2=completed, 3=failed, 4=retrying
  final int uploadRetryCount;
  final int? lastUploadAttemptMillis;
  final bool needsSync;

  final int createdAtMillis;
  final int modifiedAtMillis;
  final bool isDeleted;
  final int version;

  Id get isarId => fastHash(id);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'entryType': entryType,
      'textContent': textContent,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'audioDurationSeconds': audioDurationSeconds,
      'transcription': transcription,
      'aiProcessingStatus': aiProcessingStatus,
      'createdAtMillis': createdAtMillis,
      'modifiedAtMillis': modifiedAtMillis,
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  JournalEntryEntity toEntity() {
    return JournalEntryEntity(
      id: id,
      userId: userId,
      entryType: JournalEntryType.values[entryType],
      textContent: textContent,
      storageUrl: storageUrl,
      thumbnailUrl: thumbnailUrl,
      audioDurationSeconds: audioDurationSeconds,
      transcription: transcription,
      aiProcessingStatus: AiProcessingStatus.values[aiProcessingStatus],
      uploadStatus: UploadStatus.values[uploadStatus],
      needsSync: needsSync,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(modifiedAtMillis),
    );
  }

  JournalEntryModel copyWith({
    String? id,
    String? userId,
    int? entryType,
    String? textContent,
    String? storageUrl,
    String? localFilePath,
    String? thumbnailUrl,
    String? localThumbnailPath,
    int? audioDurationSeconds,
    String? transcription,
    int? aiProcessingStatus,
    int? uploadStatus,
    int? uploadRetryCount,
    int? lastUploadAttemptMillis,
    bool? needsSync,
    int? createdAtMillis,
    int? modifiedAtMillis,
    bool? isDeleted,
    int? version,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryType: entryType ?? this.entryType,
      textContent: textContent ?? this.textContent,
      storageUrl: storageUrl ?? this.storageUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      transcription: transcription ?? this.transcription,
      aiProcessingStatus: aiProcessingStatus ?? this.aiProcessingStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadRetryCount: uploadRetryCount ?? this.uploadRetryCount,
      lastUploadAttemptMillis: lastUploadAttemptMillis ?? this.lastUploadAttemptMillis,
      needsSync: needsSync ?? this.needsSync,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      modifiedAtMillis: modifiedAtMillis ?? this.modifiedAtMillis,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  int fastHash(String string) {
    var hash = 0xcbf29ce4;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x1000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x1000001b3;
    }
    return hash;
  }
}
