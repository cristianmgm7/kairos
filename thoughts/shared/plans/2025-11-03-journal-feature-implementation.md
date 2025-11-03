# Journal Feature Implementation Plan

## Overview

This plan implements a comprehensive Journal feature for the Kairos Flutter app, allowing users to create entries in three ways: text input, photo capture (handwritten journals), and audio recording. The implementation follows the app's existing clean architecture pattern with offline-first approach, Isar local persistence, and Firebase Cloud (Firestore + Storage) synchronization.

## Current State Analysis

### Existing Infrastructure
- **Architecture**: Clean Architecture with domain/data/presentation layers
- **Local Storage**: Isar database with reactive streams
- **Remote Storage**: Firebase Firestore for documents, Firebase Storage for files
- **State Management**: Riverpod with StateNotifier pattern
- **Sync Pattern**: Offline-first writes, remote-first reads, manual sync with last-write-wins
- **Error Handling**: Result<T> type with typed Failure hierarchy

### Existing Services
- **FirebaseImageStorageService** ([firebase_image_storage_service.dart:11-121](lib/core/services/firebase_image_storage_service.dart#L11-L121)): Handles avatar uploads with image processing
- **ImagePickerService** ([image_picker_service.dart:9-65](lib/core/services/image_picker_service.dart#L9-L65)): Camera and gallery selection

### Current Journal Screen
- Basic placeholder UI at [journal_screen.dart:7-80](lib/features/journal/presentation/screens/journal_screen.dart#L7-L80)
- FAB with TODO comment for entry creation
- Wrapped in MainScaffold with bottom navigation

### Key Discoveries
- User profile feature provides excellent reference implementation for offline-first sync
- Soft delete pattern used throughout (`isDeleted` flag)
- Upload status tracking not implemented yet (opportunity for journal feature)
- Version-based optimistic locking for conflict resolution
- Stream-based reactive UI using Isar `.watch()` method

## Desired End State

### Functional Requirements
1. **Three Entry Types**: Text, Image (camera/gallery), Audio recording
2. **Speed Dial FAB**: Material Design style with 3 mini FABs for entry type selection
3. **Offline-First**: All entries saved locally immediately, synced in background
4. **Upload Tracking**: Visual indicators for upload status (pending, uploading, completed, failed)
5. **Retry Logic**: Automatic retry with exponential backoff + manual retry button
6. **List View**: Reactive stream showing all journal entries with upload status
7. **Image Processing**: Thumbnail generation for instant preview, resize before upload
8. **Audio Metadata**: Duration tracking for playback UI
9. **AI Placeholders**: Fields ready for future transcription/analysis

### Verification
After implementation, the feature will be complete when:
- User can create text entries that immediately appear in the list
- User can capture/select images that show thumbnails while uploading
- User can record audio with duration displayed
- All entries persist offline and sync when online
- Failed uploads show retry button and eventually succeed
- All automated tests pass
- Manual testing confirms smooth UX for each entry type

## What We're NOT Doing

This plan explicitly excludes:
- AI transcription/analysis (Cloud Functions - separate backend implementation)
- Entry editing capabilities (future enhancement)
- Entry deletion UI (soft delete infrastructure included, but no user-facing delete)
- Search and filter functionality
- Export or share features
- Waveform visualization for audio
- Rich text editing (simple text input only)
- Image annotation or editing
- Full audio playback controls (display only in Phase 1, playback later)
- Progress bars during upload (progress tracking implemented, UI indicator optional for Phase 2)

## Implementation Approach

### Strategy
1. **Core First**: Build data models, storage services, and sync infrastructure
2. **Incremental Capture Flows**: Implement one entry type at a time (text → image → audio)
3. **UI Last**: Build list view and polish after all capture flows work
4. **Test Continuously**: Write tests alongside implementation in each phase

### Architectural Decisions
- **Single Entry Type**: Each entry is text OR image OR audio (not mixed)
- **Generalized Storage Service**: Refactor to `FirebaseStorageService` with optional processing and progress streams
- **Storage Path Pattern**: `users/{userId}/journals/{journalId}/{filename}` for organized structure
- **Thumbnail Strategy**: Generate locally using `image` package before upload for instant offline preview
- **Audio Package**: Use `record` package for simplicity and cross-platform support
- **Audio Format**: Encode to M4A/AAC for optimal compression and quality
- **Retry Strategy**: Automatic background retry with exponential backoff (2s → 4s → 8s → 16s → 32s) + manual UI trigger
- **Upload Status Enum**: Track 5 states: `notStarted`, `uploading`, `completed`, `failed`, `retrying`
- **Sync Queue**: Use `needsSync` boolean flag on entries to simplify retry logic
- **Timestamps**: All timestamps use UTC to avoid sync conflicts
- **Metadata Field**: Optional JSON field for future extensions (AI tags, geolocation, etc.)
- **Reactive Updates**: Isar `.watch()` triggers on uploadStatus and transcription changes for instant UI updates

---

## Phase 1: Core Data Layer & Storage Services

### Overview
Establish the foundational data structures, local persistence (Isar), remote persistence (Firestore), and refactored storage service for file uploads.

### Changes Required

#### 1.1 Domain Layer - Entity

**File**: `lib/features/journal/domain/entities/journal_entry_entity.dart` (new)

```dart
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
```

#### 1.2 Data Layer - Model with Isar

**File**: `lib/features/journal/data/models/journal_entry_model.dart` (new)

```dart
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
```

#### 1.3 Refactor Firebase Storage Service

**File**: `lib/core/services/firebase_storage_service.dart` (refactor from `firebase_image_storage_service.dart`)

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

enum FileType { image, audio, document }

class FirebaseStorageService {
  FirebaseStorageService(this._storage);
  final FirebaseStorage _storage;

  /// Build dynamic storage path: users/{userId}/journals/{journalId}/{filename}
  String buildJournalPath({
    required String userId,
    required String journalId,
    required String filename,
  }) {
    return 'users/$userId/journals/$journalId/$filename';
  }

  /// Upload file with optional processing and progress tracking
  Future<Result<String>> uploadFile({
    required File file,
    required String storagePath,
    required FileType fileType,
    Map<String, String>? metadata,
    int? imageMaxSize,
    int? imageQuality,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!file.existsSync()) {
        return const Error(ValidationFailure(message: 'File does not exist'));
      }

      Uint8List fileBytes;
      String contentType;

      // Process based on file type
      switch (fileType) {
        case FileType.image:
          final result = await _processImage(
            file,
            maxSize: imageMaxSize ?? 1024,
            quality: imageQuality ?? 85,
          );
          if (result.isError) return Error(result.failureOrNull!);
          fileBytes = result.dataOrNull!;
          contentType = 'image/jpeg';
          break;

        case FileType.audio:
          fileBytes = await file.readAsBytes();
          contentType = 'audio/m4a'; // M4A/AAC for optimal compression
          break;

        case FileType.document:
          fileBytes = await file.readAsBytes();
          contentType = 'application/octet-stream';
          break;
      }

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toUtc().toIso8601String(),
            'fileType': fileType.name,
            ...?metadata,
          },
        ),
      );

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Success(downloadUrl);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to upload file: $e'));
    }
  }

  /// Process image: resize and compress
  Future<Result<Uint8List>> _processImage(
    File imageFile, {
    required int maxSize,
    required int quality,
  }) async {
    try {
      final imageBytes = imageFile.readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return const Error(ValidationFailure(message: 'Invalid image format'));
      }

      final resizedImage = img.copyResize(
        originalImage,
        width: maxSize,
        height: maxSize,
        maintainAspect: true,
        backgroundColor: img.ColorRgb8(255, 255, 255),
      );

      final processedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      return Success(processedBytes);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to process image: $e'));
    }
  }

  /// Generate thumbnail from image file
  Future<Result<Uint8List>> generateThumbnail(
    File imageFile, {
    int size = 150,
  }) async {
    return _processImage(imageFile, maxSize: size, quality: 70);
  }

  /// Delete file from storage
  Future<Result<void>> deleteFile(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final pathStartIndex = pathSegments.indexOf('o');

      if (pathStartIndex == -1 || pathStartIndex + 1 >= pathSegments.length) {
        return const Error(ValidationFailure(message: 'Invalid URL format'));
      }

      final encodedPath = pathSegments.sublist(pathStartIndex + 1).join('/');
      final storagePath = Uri.decodeFull(encodedPath);

      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();

      return const Success(null);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to delete file: $e'));
    }
  }
}
```

#### 1.4 Local Data Source

**File**: `lib/features/journal/data/datasources/journal_entry_local_datasource.dart` (new)

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';

abstract class JournalEntryLocalDataSource {
  Future<void> saveEntry(JournalEntryModel entry);
  Future<JournalEntryModel?> getEntryById(String entryId);
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
  Stream<List<JournalEntryModel>> watchEntriesByUserId(String userId);
  Future<List<JournalEntryModel>> getPendingUploads(String userId);
}

class JournalEntryLocalDataSourceImpl implements JournalEntryLocalDataSource {
  JournalEntryLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveEntry(JournalEntryModel entry) async {
    await isar.writeTxn(() async {
      await isar.journalEntryModels.put(entry);
    });
  }

  @override
  Future<JournalEntryModel?> getEntryById(String entryId) async {
    return isar.journalEntryModels
        .filter()
        .idEqualTo(entryId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId) async {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .sortByCreatedAtMillisDesc()
        .findAll();
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    final updated = entry.copyWith(
      modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      version: entry.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalEntryModels.put(updated);
    });
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    final entry = await getEntryById(entryId);
    if (entry != null) {
      final deleted = entry.copyWith(
        isDeleted: true,
        modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.journalEntryModels.put(deleted);
      });
    }
  }

  @override
  Stream<List<JournalEntryModel>> watchEntriesByUserId(String userId) {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((entries) => entries..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis)));
  }

  @override
  Future<List<JournalEntryModel>> getPendingUploads(String userId) async {
    return isar.journalEntryModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .uploadStatusEqualTo(0) // notStarted
            .or()
            .uploadStatusEqualTo(3)) // failed
        .findAll();
  }
}
```

#### 1.5 Remote Data Source

**File**: `lib/features/journal/data/datasources/journal_entry_remote_datasource.dart` (new)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';

abstract class JournalEntryRemoteDataSource {
  Future<void> saveEntry(JournalEntryModel entry);
  Future<JournalEntryModel?> getEntryById(String entryId);
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
}

class JournalEntryRemoteDataSourceImpl implements JournalEntryRemoteDataSource {
  JournalEntryRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalEntries');

  @override
  Future<void> saveEntry(JournalEntryModel entry) async {
    await _collection.doc(entry.id).set(entry.toFirestoreMap());
  }

  @override
  Future<JournalEntryModel?> getEntryById(String entryId) async {
    final doc = await _collection.doc(entryId).get();
    if (!doc.exists) return null;
    return JournalEntryModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalEntryModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    await _collection.doc(entry.id).update(entry.toFirestoreMap());
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _collection.doc(entryId).update({
      'isDeleted': true,
      'modifiedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
```

#### 1.6 Repository Implementation

**File**: `lib/features/journal/data/repositories/journal_entry_repository_impl.dart` (new)

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';

class JournalEntryRepositoryImpl implements JournalEntryRepository {
  JournalEntryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final JournalEntryLocalDataSource localDataSource;
  final JournalEntryRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalEntryEntity>> createEntry(JournalEntryEntity entry) async {
    try {
      final model = JournalEntryModel.fromEntity(entry);
      await localDataSource.saveEntry(model);

      if (await _isOnline && entry.entryType == JournalEntryType.text) {
        try {
          await remoteDataSource.saveEntry(model);
          final synced = model.copyWith(uploadStatus: UploadStatus.completed.index);
          await localDataSource.updateEntry(synced);
        } catch (e) {
          debugPrint('Failed to sync entry to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create entry: $e'));
    }
  }

  @override
  Future<Result<JournalEntryEntity?>> getEntryById(String entryId) async {
    try {
      if (await _isOnline) {
        try {
          final remoteEntry = await remoteDataSource.getEntryById(entryId);
          if (remoteEntry != null) {
            await localDataSource.saveEntry(remoteEntry);
            return Success(remoteEntry.toEntity());
          }
        } catch (e) {
          debugPrint('Failed to fetch from remote: $e');
        }
      }

      final localEntry = await localDataSource.getEntryById(entryId);
      return Success(localEntry?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get entry: $e'));
    }
  }

  @override
  Stream<List<JournalEntryEntity>> watchEntriesByUserId(String userId) {
    return localDataSource
        .watchEntriesByUserId(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> syncPendingUploads(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final pendingEntries = await localDataSource.getPendingUploads(userId);

      for (final entry in pendingEntries) {
        try {
          await remoteDataSource.saveEntry(entry);
          final synced = entry.copyWith(uploadStatus: UploadStatus.completed.index);
          await localDataSource.updateEntry(synced);
        } catch (e) {
          debugPrint('Failed to sync entry ${entry.id}: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync: $e'));
    }
  }
}
```

#### 1.7 Repository Interface

**File**: `lib/features/journal/domain/repositories/journal_entry_repository.dart` (new)

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';

abstract class JournalEntryRepository {
  Future<Result<JournalEntryEntity>> createEntry(JournalEntryEntity entry);
  Future<Result<JournalEntryEntity?>> getEntryById(String entryId);
  Stream<List<JournalEntryEntity>> watchEntriesByUserId(String userId);
  Future<Result<void>> syncPendingUploads(String userId);
}
```

#### 1.8 Update Database Provider

**File**: `lib/core/providers/database_provider.dart` (update)

Add `JournalEntryModelSchema` to Isar initialization:

```dart
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      UserProfileModelSchema,
      SettingsModelSchema,
      JournalEntryModelSchema, // ADD THIS
    ],
    directory: dir.path,
    name: 'kairos_db',
  );
}
```

#### 1.9 Add Dependencies

**File**: `pubspec.yaml` (update)

Add new packages:

```yaml
dependencies:
  record: ^5.0.0  # Audio recording
  path_provider: ^2.1.0  # Already exists, but confirm
  # existing dependencies...
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds after adding new models: `~/flutter/bin/flutter pub get && ~/flutter/bin/dart run build_runner build --delete-conflicting-outputs`
- [ ] No type errors: `~/flutter/bin/flutter analyze`
- [ ] Database initializes with new schema: Run app and check logs for "✅ Isar initialized"
- [ ] Unit tests pass for entity, model conversions: `~/flutter/bin/flutter test test/features/journal/`

#### Manual Verification:
- [ ] App launches without crashes
- [ ] Isar inspector shows `journalEntryModels` collection
- [ ] Firebase Storage service can be instantiated via provider
- [ ] Existing avatar upload still works (regression test)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the data layer is solid before proceeding to capture flows.

---

## Phase 2: Text Entry Capture Flow

### Overview
Implement the simplest capture flow first: a text editor screen where users can write journal entries. This validates the entire data pipeline before adding complex media handling.

### Changes Required

#### 2.1 Use Case - Create Text Entry

**File**: `lib/features/journal/domain/usecases/create_text_entry_usecase.dart` (new)

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:uuid/uuid.dart';

class CreateTextEntryParams {
  const CreateTextEntryParams({
    required this.userId,
    required this.textContent,
  });

  final String userId;
  final String textContent;
}

class CreateTextEntryUseCase {
  CreateTextEntryUseCase(this.repository);
  final JournalEntryRepository repository;

  Future<Result<JournalEntryEntity>> call(CreateTextEntryParams params) async {
    if (params.textContent.trim().isEmpty) {
      return const Error(ValidationFailure(message: 'Text content cannot be empty'));
    }

    final now = DateTime.now();
    final entry = JournalEntryEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      entryType: JournalEntryType.text,
      textContent: params.textContent.trim(),
      createdAt: now,
      updatedAt: now,
      uploadStatus: UploadStatus.completed, // Text entries don't need upload
    );

    return repository.createEntry(entry);
  }
}
```

#### 2.2 Text Entry Screen

**File**: `lib/features/journal/presentation/screens/create_text_entry_screen.dart` (new)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/app_button.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';

class CreateTextEntryScreen extends ConsumerStatefulWidget {
  const CreateTextEntryScreen({super.key});

  @override
  ConsumerState<CreateTextEntryScreen> createState() => _CreateTextEntryScreenState();
}

class _CreateTextEntryScreenState extends ConsumerState<CreateTextEntryScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    final controller = ref.read(journalControllerProvider.notifier);
    await controller.createTextEntry(_textController.text);

    final state = ref.read(journalControllerProvider);
    if (state is JournalSuccess && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalControllerProvider);
    final isLoading = state is JournalLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Text Entry'),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _onSave,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Write your thoughts...',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
```

#### 2.3 Journal Controller

**File**: `lib/features/journal/presentation/controllers/journal_controller.dart` (new)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_entry_usecase.dart';

sealed class JournalState {}
class JournalInitial extends JournalState {}
class JournalLoading extends JournalState {}
class JournalSuccess extends JournalState {}
class JournalError extends JournalState {
  JournalError(this.message);
  final String message;
}

class JournalController extends StateNotifier<JournalState> {
  JournalController({
    required this.createTextEntryUseCase,
    required this.ref,
  }) : super(JournalInitial());

  final CreateTextEntryUseCase createTextEntryUseCase;
  final Ref ref;

  String? get _currentUserId {
    final authState = ref.read(authStateProvider);
    return authState.valueOrNull?.id;
  }

  Future<void> createTextEntry(String content) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = JournalError('User not authenticated');
      return;
    }

    state = JournalLoading();

    try {
      final params = CreateTextEntryParams(
        userId: userId,
        textContent: content,
      );

      final result = await createTextEntryUseCase.call(params);

      result.when(
        success: (_) {
          state = JournalSuccess();
        },
        error: (failure) {
          state = JournalError(_getErrorMessage(failure));
        },
      );
    } catch (e) {
      state = JournalError('An unexpected error occurred: $e');
    }
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error: ${failure.message}',
      _ => 'An error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = JournalInitial();
  }
}
```

#### 2.4 Providers

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (new)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_entry_repository_impl.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_entry_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';

// Data sources
final journalLocalDataSourceProvider = Provider<JournalEntryLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return JournalEntryLocalDataSourceImpl(isar);
});

final journalRemoteDataSourceProvider = Provider<JournalEntryRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return JournalEntryRemoteDataSourceImpl(firestore);
});

// Repository
final journalRepositoryProvider = Provider<JournalEntryRepository>((ref) {
  final localDataSource = ref.watch(journalLocalDataSourceProvider);
  final remoteDataSource = ref.watch(journalRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityProvider);

  return JournalEntryRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivity: connectivity,
  );
});

// Use cases
final createTextEntryUseCaseProvider = Provider<CreateTextEntryUseCase>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return CreateTextEntryUseCase(repository);
});

// Controller
final journalControllerProvider = StateNotifierProvider<JournalController, JournalState>((ref) {
  final createTextEntryUseCase = ref.watch(createTextEntryUseCaseProvider);

  return JournalController(
    createTextEntryUseCase: createTextEntryUseCase,
    ref: ref,
  );
});
```

#### 2.5 Update Router

**File**: `lib/core/routing/router_provider.dart` (update)

Add route for text entry screen:

```dart
GoRoute(
  path: '/journal/create-text',
  builder: (context, state) => const CreateTextEntryScreen(),
),
```

#### 2.6 Update Journal Screen FAB

**File**: `lib/features/journal/presentation/screens/journal_screen.dart` (update)

Replace the FAB `onPressed` to navigate to text entry:

```dart
FloatingActionButton(
  onPressed: () {
    context.push('/journal/create-text');
  },
  child: const Icon(Icons.add),
),
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Unit tests pass for use case: `~/flutter/bin/flutter test test/features/journal/domain/usecases/`
- [ ] Controller tests pass: `~/flutter/bin/flutter test test/features/journal/presentation/controllers/`

#### Manual Verification:
- [ ] Tapping FAB navigates to text entry screen
- [ ] Text field auto-focuses on screen open
- [ ] Typing text works smoothly
- [ ] Tapping "Save" with empty text shows snackbar error
- [ ] Tapping "Save" with text creates entry and returns to journal screen
- [ ] Entry appears in Isar database (check via Isar Inspector)
- [ ] Entry syncs to Firestore when online
- [ ] Creating entry offline works and shows in local database

**Implementation Note**: Verify text entries are creating and syncing properly before moving to image capture.

---

## Phase 3: Image Entry Capture Flow

### Overview
Implement image capture with camera/gallery selection, local thumbnail generation, and background upload to Firebase Storage with progress tracking.

### Changes Required

#### 3.1 Use Case - Create Image Entry

**File**: `lib/features/journal/domain/usecases/create_image_entry_usecase.dart` (new)

```dart
import 'dart:io';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:uuid/uuid.dart';

class CreateImageEntryParams {
  const CreateImageEntryParams({
    required this.userId,
    required this.imageFile,
    required this.thumbnailFile,
  });

  final String userId;
  final File imageFile;
  final File thumbnailFile;
}

class CreateImageEntryUseCase {
  CreateImageEntryUseCase(this.repository);
  final JournalEntryRepository repository;

  Future<Result<JournalEntryEntity>> call(CreateImageEntryParams params) async {
    if (!params.imageFile.existsSync()) {
      return const Error(ValidationFailure(message: 'Image file does not exist'));
    }

    final now = DateTime.now();
    final entry = JournalEntryEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      entryType: JournalEntryType.image,
      createdAt: now,
      updatedAt: now,
      uploadStatus: UploadStatus.notStarted,
    );

    return repository.createEntry(entry);
  }
}
```

#### 3.2 Image Upload Service

**File**: `lib/features/journal/data/services/journal_upload_service.dart` (new)

```dart
import 'dart:io';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';

class JournalUploadService {
  JournalUploadService({
    required this.storageService,
    required this.localDataSource,
  });

  final FirebaseStorageService storageService;
  final JournalEntryLocalDataSource localDataSource;

  Future<Result<void>> uploadImageEntry({
    required JournalEntryModel entry,
    required File imageFile,
    required File thumbnailFile,
  }) async {
    try {
      // Update status to uploading
      await _updateUploadStatus(entry, UploadStatus.uploading);

      // Upload thumbnail first
      final thumbnailPath = 'journal_thumbnails/${entry.userId}/${entry.id}_thumb.jpg';
      final thumbnailResult = await storageService.uploadFile(
        file: thumbnailFile,
        storagePath: thumbnailPath,
        fileType: FileType.image,
        imageMaxSize: 150,
        imageQuality: 70,
        metadata: {'entryId': entry.id},
      );

      if (thumbnailResult.isError) {
        await _updateUploadStatus(entry, UploadStatus.failed);
        return Error(thumbnailResult.failureOrNull!);
      }

      // Upload full image
      final imagePath = 'journal_images/${entry.userId}/${entry.id}.jpg';
      final imageResult = await storageService.uploadFile(
        file: imageFile,
        storagePath: imagePath,
        fileType: FileType.image,
        imageMaxSize: 1024,
        imageQuality: 85,
        metadata: {'entryId': entry.id},
      );

      if (imageResult.isError) {
        await _updateUploadStatus(entry, UploadStatus.failed);
        return Error(imageResult.failureOrNull!);
      }

      // Update entry with URLs
      final updated = entry.copyWith(
        storageUrl: imageResult.dataOrNull,
        thumbnailUrl: thumbnailResult.dataOrNull,
        uploadStatus: UploadStatus.completed.index,
      );
      await localDataSource.updateEntry(updated);

      return const Success(null);
    } catch (e) {
      await _updateUploadStatus(entry, UploadStatus.failed);
      return Error(UnknownFailure(message: 'Upload failed: $e'));
    }
  }

  Future<void> _updateUploadStatus(JournalEntryModel entry, UploadStatus status) async {
    final updated = entry.copyWith(
      uploadStatus: status.index,
      lastUploadAttemptMillis: DateTime.now().millisecondsSinceEpoch,
      uploadRetryCount: status == UploadStatus.retrying ? entry.uploadRetryCount + 1 : entry.uploadRetryCount,
    );
    await localDataSource.updateEntry(updated);
  }
}
```

#### 3.3 Image Entry Screen

**File**: `lib/features/journal/presentation/screens/create_image_entry_screen.dart` (new)

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/app_button.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';

class CreateImageEntryScreen extends ConsumerStatefulWidget {
  const CreateImageEntryScreen({super.key});

  @override
  ConsumerState<CreateImageEntryScreen> createState() => _CreateImageEntryScreenState();
}

class _CreateImageEntryScreenState extends ConsumerState<CreateImageEntryScreen> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourceDialog();
    });
  }

  Future<void> _showImageSourceDialog() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _pickImage(result);
    } else if (mounted) {
      context.pop();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final controller = ref.read(journalControllerProvider.notifier);

    if (source == ImageSource.camera) {
      await controller.pickImageFromCamera();
    } else {
      await controller.pickImageFromGallery();
    }

    final selectedImage = controller.selectedImage;
    if (selectedImage != null) {
      setState(() => _selectedImage = selectedImage);
    } else if (mounted) {
      context.pop();
    }
  }

  Future<void> _onSave() async {
    if (_selectedImage == null) return;

    final controller = ref.read(journalControllerProvider.notifier);
    await controller.createImageEntry(_selectedImage!);

    final state = ref.read(journalControllerProvider);
    if (state is JournalSuccess && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalControllerProvider);
    final isLoading = state is JournalLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Image Entry'),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_selectedImage != null)
            TextButton(
              onPressed: _onSave,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _selectedImage == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              ),
            ),
    );
  }
}
```

#### 3.4 Update Journal Controller

Add methods to `journal_controller.dart`:

```dart
File? _selectedImage;
File? get selectedImage => _selectedImage;

Future<void> pickImageFromCamera() async {
  final result = await imagePickerService.pickImageFromCamera();
  result.when(
    success: (file) => _selectedImage = file,
    error: (failure) => state = JournalError(_getErrorMessage(failure)),
  );
}

Future<void> pickImageFromGallery() async {
  final result = await imagePickerService.pickImageFromGallery();
  result.when(
    success: (file) => _selectedImage = file,
    error: (failure) => state = JournalError(_getErrorMessage(failure)),
  );
}

Future<void> createImageEntry(File imageFile) async {
  final userId = _currentUserId;
  if (userId == null) {
    state = JournalError('User not authenticated');
    return;
  }

  state = JournalLoading();

  try {
    // Generate thumbnail
    final thumbnailResult = await storageService.generateThumbnail(imageFile);
    if (thumbnailResult.isError) {
      state = JournalError('Failed to process image');
      return;
    }

    // Save thumbnail to temp file
    final tempDir = await getTemporaryDirectory();
    final thumbnailFile = File('${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await thumbnailFile.writeAsBytes(thumbnailResult.dataOrNull!);

    final params = CreateImageEntryParams(
      userId: userId,
      imageFile: imageFile,
      thumbnailFile: thumbnailFile,
    );

    final result = await createImageEntryUseCase.call(params);

    result.when(
      success: (entry) {
        // Start background upload
        uploadService.uploadImageEntry(
          entry: JournalEntryModel.fromEntity(entry),
          imageFile: imageFile,
          thumbnailFile: thumbnailFile,
        );
        state = JournalSuccess();
      },
      error: (failure) {
        state = JournalError(_getErrorMessage(failure));
      },
    );
  } catch (e) {
    state = JournalError('An unexpected error occurred: $e');
  }
}
```

#### 3.5 Update Router

Add route in `router_provider.dart`:

```dart
GoRoute(
  path: '/journal/create-image',
  builder: (context, state) => const CreateImageEntryScreen(),
),
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Image processing tests pass: `~/flutter/bin/flutter test test/core/services/firebase_storage_service_test.dart`

#### Manual Verification:
- [ ] Image source dialog appears on screen load
- [ ] Camera option opens device camera
- [ ] Gallery option opens photo picker
- [ ] Selected image displays in preview
- [ ] Tapping "Save" creates entry and returns to journal screen
- [ ] Thumbnail is visible immediately in list (offline preview)
- [ ] Full image uploads in background when online
- [ ] Upload status updates from "uploading" to "completed"
- [ ] Failed uploads show retry option

**Implementation Note**: Test both camera and gallery flows thoroughly, including offline behavior.

---

## Phase 4: Audio Entry Capture Flow

### Overview
Implement audio recording with duration tracking, background upload, and playback UI preparation.

### Changes Required

#### 4.1 Audio Recording Service

**File**: `lib/core/services/audio_recording_service.dart` (new)

```dart
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

class AudioRecordingService {
  AudioRecordingService(this._recorder);
  final AudioRecorder _recorder;

  Future<Result<void>> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(const RecordConfig(), path: path);
        return const Success(null);
      } else {
        return const Error(PermissionFailure(message: 'Microphone permission denied'));
      }
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to start recording: $e'));
    }
  }

  Future<Result<File>> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null) {
        return const Error(UnknownFailure(message: 'Recording path is null'));
      }
      return Success(File(path));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to stop recording: $e'));
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  Stream<RecordState> get onStateChanged => _recorder.onStateChanged();

  void dispose() {
    _recorder.dispose();
  }
}
```

#### 4.2 Audio Helper

**File**: `lib/features/journal/data/services/audio_helper.dart` (new)

```dart
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static Future<int?> getAudioDuration(File audioFile) async {
    try {
      final player = AudioPlayer();
      await player.setSourceDeviceFile(audioFile.path);
      final duration = await player.getDuration();
      await player.dispose();
      return duration?.inSeconds;
    } catch (e) {
      return null;
    }
  }
}
```

#### 4.3 Use Case - Create Audio Entry

**File**: `lib/features/journal/domain/usecases/create_audio_entry_usecase.dart` (new)

```dart
import 'dart:io';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:uuid/uuid.dart';

class CreateAudioEntryParams {
  const CreateAudioEntryParams({
    required this.userId,
    required this.audioFile,
    required this.durationSeconds,
  });

  final String userId;
  final File audioFile;
  final int durationSeconds;
}

class CreateAudioEntryUseCase {
  CreateAudioEntryUseCase(this.repository);
  final JournalEntryRepository repository;

  Future<Result<JournalEntryEntity>> call(CreateAudioEntryParams params) async {
    if (!params.audioFile.existsSync()) {
      return const Error(ValidationFailure(message: 'Audio file does not exist'));
    }

    final now = DateTime.now();
    final entry = JournalEntryEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      entryType: JournalEntryType.audio,
      audioDurationSeconds: params.durationSeconds,
      createdAt: now,
      updatedAt: now,
      uploadStatus: UploadStatus.notStarted,
    );

    return repository.createEntry(entry);
  }
}
```

#### 4.4 Audio Entry Screen

**File**: `lib/features/journal/presentation/screens/create_audio_entry_screen.dart` (new)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';

class CreateAudioEntryScreen extends ConsumerStatefulWidget {
  const CreateAudioEntryScreen({super.key});

  @override
  ConsumerState<CreateAudioEntryScreen> createState() => _CreateAudioEntryScreenState();
}

class _CreateAudioEntryScreenState extends ConsumerState<CreateAudioEntryScreen> {
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final controller = ref.read(journalControllerProvider.notifier);
    await controller.startAudioRecording();

    setState(() => _isRecording = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordingDuration++);
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() => _isRecording = false);

    final controller = ref.read(journalControllerProvider.notifier);
    await controller.stopAudioRecording();

    final state = ref.read(journalControllerProvider);
    if (state is JournalSuccess && mounted) {
      context.pop();
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    final controller = ref.read(journalControllerProvider.notifier);
    await controller.cancelAudioRecording();

    if (mounted) {
      context.pop();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalControllerProvider);
    final isLoading = state is JournalLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Audio Entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLoading ? null : _cancelRecording,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_off,
              size: 80,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isRecording ? 'Recording...' : 'Stopped',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_isRecording)
              ElevatedButton.icon(
                onPressed: isLoading ? null : _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop & Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### 4.5 Update Journal Controller

Add audio methods to controller:

```dart
File? _recordedAudio;

Future<void> startAudioRecording() async {
  final result = await audioRecordingService.startRecording();
  if (result.isError) {
    state = JournalError(_getErrorMessage(result.failureOrNull!));
  }
}

Future<void> stopAudioRecording() async {
  final userId = _currentUserId;
  if (userId == null) {
    state = JournalError('User not authenticated');
    return;
  }

  state = JournalLoading();

  final result = await audioRecordingService.stopRecording();

  result.when(
    success: (audioFile) async {
      _recordedAudio = audioFile;

      // Get audio duration
      final duration = await AudioHelper.getAudioDuration(audioFile) ?? 0;

      final params = CreateAudioEntryParams(
        userId: userId,
        audioFile: audioFile,
        durationSeconds: duration,
      );

      final createResult = await createAudioEntryUseCase.call(params);

      createResult.when(
        success: (entry) {
          // Start background upload
          uploadService.uploadAudioEntry(
            entry: JournalEntryModel.fromEntity(entry),
            audioFile: audioFile,
          );
          state = JournalSuccess();
        },
        error: (failure) {
          state = JournalError(_getErrorMessage(failure));
        },
      );
    },
    error: (failure) {
      state = JournalError(_getErrorMessage(failure));
    },
  );
}

Future<void> cancelAudioRecording() async {
  await audioRecordingService.cancelRecording();
  state = JournalInitial();
}
```

#### 4.6 Update Upload Service

Add audio upload method to `journal_upload_service.dart`:

```dart
Future<Result<void>> uploadAudioEntry({
  required JournalEntryModel entry,
  required File audioFile,
}) async {
  try {
    await _updateUploadStatus(entry, UploadStatus.uploading);

    final audioPath = 'journal_audio/${entry.userId}/${entry.id}.m4a';
    final audioResult = await storageService.uploadFile(
      file: audioFile,
      storagePath: audioPath,
      fileType: FileType.audio,
      metadata: {'entryId': entry.id, 'duration': entry.audioDurationSeconds.toString()},
    );

    if (audioResult.isError) {
      await _updateUploadStatus(entry, UploadStatus.failed);
      return Error(audioResult.failureOrNull!);
    }

    final updated = entry.copyWith(
      storageUrl: audioResult.dataOrNull,
      uploadStatus: UploadStatus.completed.index,
    );
    await localDataSource.updateEntry(updated);

    return const Success(null);
  } catch (e) {
    await _updateUploadStatus(entry, UploadStatus.failed);
    return Error(UnknownFailure(message: 'Audio upload failed: $e'));
  }
}
```

#### 4.7 Update Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  audioplayers: ^5.0.0  # For duration calculation
```

#### 4.8 Update Router

Add route:

```dart
GoRoute(
  path: '/journal/create-audio',
  builder: (context, state) => const CreateAudioEntryScreen(),
),
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds with new audio dependencies: `~/flutter/bin/flutter pub get`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Audio recording service tests pass: `~/flutter/bin/flutter test test/core/services/`

#### Manual Verification:
- [ ] Permission dialog appears on first recording attempt
- [ ] Recording starts and timer increments
- [ ] Stop button saves audio and returns to journal screen
- [ ] Cancel button discards recording
- [ ] Audio duration is calculated correctly
- [ ] Audio file uploads in background when online
- [ ] Failed uploads show retry option

**Implementation Note**: Test on both iOS and Android for permission handling differences.

---

## Phase 5: List View, Speed Dial FAB & Sync/Retry

### Overview
Build the journal entry list with reactive updates, Speed Dial FAB for entry type selection, and implement retry logic for failed uploads.

### Changes Required

#### 5.1 Speed Dial FAB Widget

**File**: `lib/core/widgets/speed_dial_fab.dart` (new)

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    required this.children,
    this.icon = Icons.add,
    this.activeIcon = Icons.close,
    super.key,
  });

  final List<SpeedDialChild> children;
  final IconData icon;
  final IconData activeIcon;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._buildExpandingButtons(),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _expandAnimation,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpandingButtons() {
    final children = <Widget>[];
    final count = widget.children.length;

    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingButton(
          animation: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }

    return children.reversed.toList();
  }
}

class SpeedDialChild {
  const SpeedDialChild({
    required this.child,
    required this.label,
    required this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
}

class _ExpandingButton extends StatelessWidget {
  const _ExpandingButton({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final SpeedDialChild child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, widget) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        child.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.small(
                    heroTag: child.label,
                    onPressed: child.onTap,
                    backgroundColor: child.backgroundColor,
                    child: child.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

#### 5.2 Entry List Item Widget

**File**: `lib/features/journal/presentation/widgets/journal_entry_item.dart` (new)

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:intl/intl.dart';

class JournalEntryItem extends StatelessWidget {
  const JournalEntryItem({
    required this.entry,
    this.onRetry,
    super.key,
  });

  final JournalEntryEntity entry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (entry.uploadStatus != UploadStatus.completed)
                        _buildUploadStatus(context),
                    ],
                  ),
                ),
                if (entry.uploadStatus == UploadStatus.failed && onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRetry,
                    tooltip: 'Retry upload',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    return Icon(
      switch (entry.entryType) {
        JournalEntryType.text => Icons.text_fields,
        JournalEntryType.image => Icons.image,
        JournalEntryType.audio => Icons.mic,
      },
      size: 32,
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (entry.entryType) {
      case JournalEntryType.text:
        return Text(
          entry.textContent ?? '',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case JournalEntryType.image:
        return entry.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  entry.thumbnailUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
      case JournalEntryType.audio:
        return Row(
          children: [
            const Icon(Icons.play_circle_outline, size: 48),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Recording',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (entry.audioDurationSeconds != null)
                  Text(
                    _formatDuration(entry.audioDurationSeconds!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (entry.transcription == null && entry.aiProcessingStatus == AiProcessingStatus.pending)
                  Text(
                    'Transcription pending...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                  ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildUploadStatus(BuildContext context) {
    // Determine color and icon based on upload status
    final (color, icon, text) = switch (entry.uploadStatus) {
      UploadStatus.notStarted => (Colors.orange, Icons.cloud_upload_outlined, 'Pending'),
      UploadStatus.uploading => (Colors.blue, Icons.cloud_upload, 'Uploading...'),
      UploadStatus.retrying => (Colors.amber, Icons.sync, 'Retrying...'),
      UploadStatus.failed => (Colors.red, Icons.error_outline, 'Failed'),
      UploadStatus.completed => (Colors.green, Icons.cloud_done, ''),
    };

    if (text.isEmpty && entry.uploadStatus == UploadStatus.completed) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (entry.uploadStatus == UploadStatus.uploading ||
            entry.uploadStatus == UploadStatus.retrying)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
```

#### 5.3 Update Journal Screen

**File**: `lib/features/journal/presentation/screens/journal_screen.dart` (replace)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/speed_dial_fab.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/journal_entry_item.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view journal entries'));
    }

    final entriesAsync = ref.watch(journalEntriesStreamProvider(userId));

    return Column(
      children: [
        AppBar(title: const Text('Journal')),
        Expanded(
          child: Stack(
            children: [
              entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary.withAlpha(128),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'No entries yet',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap the + button to create your first entry',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: 100,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return JournalEntryItem(
                        entry: entry,
                        onRetry: entry.uploadStatus == UploadStatus.failed
                            ? () => ref.read(journalControllerProvider.notifier).retryUpload(entry.id)
                            : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading entries: $error'),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: SpeedDialFab(
                  children: [
                    SpeedDialChild(
                      child: const Icon(Icons.text_fields),
                      label: 'Text',
                      onTap: () => context.push('/journal/create-text'),
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.image),
                      label: 'Image',
                      onTap: () => context.push('/journal/create-image'),
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.mic),
                      label: 'Audio',
                      onTap: () => context.push('/journal/create-audio'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

#### 5.4 Update Providers

Add stream provider to `journal_providers.dart`:

```dart
// Stream provider for journal entries
final journalEntriesStreamProvider = StreamProvider.family<List<JournalEntryEntity>, String>((ref, userId) {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.watchEntriesByUserId(userId);
});
```

#### 5.5 Background Sync Service

**File**: `lib/features/journal/data/services/journal_sync_service.dart` (new)

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/services/journal_upload_service.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';

class JournalSyncService {
  JournalSyncService({
    required this.localDataSource,
    required this.uploadService,
  });

  final JournalEntryLocalDataSource localDataSource;
  final JournalUploadService uploadService;

  Timer? _syncTimer;

  /// Start automatic background sync with 5-minute intervals
  void startPeriodicSync(String userId, {Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => _syncPendingUploads(userId));
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
  }

  /// Manual sync all - for "Sync All" button
  Future<Result<int>> syncAllPendingUploads(String userId) async {
    try {
      final pendingEntries = await localDataSource.getPendingUploads(userId);
      int successCount = 0;

      for (final entry in pendingEntries) {
        final result = await _retryUpload(entry);
        if (result.isSuccess) successCount++;
      }

      return Success(successCount);
    } catch (e) {
      return Error(UnknownFailure(message: 'Sync all failed: $e'));
    }
  }

  /// Background sync with exponential backoff
  Future<void> _syncPendingUploads(String userId) async {
    try {
      final pendingEntries = await localDataSource.getPendingUploads(userId);

      for (final entry in pendingEntries) {
        // Implement exponential backoff: 2s, 4s, 8s, 16s, 32s
        final retryCount = entry.uploadRetryCount;
        if (retryCount > 5) {
          debugPrint('Max retries exceeded for entry ${entry.id}');
          continue;
        }

        final backoffSeconds = _calculateBackoff(retryCount);
        final lastAttempt = entry.lastUploadAttemptMillis ?? 0;
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        if (now - lastAttempt < backoffSeconds * 1000) {
          debugPrint('Backoff not elapsed for entry ${entry.id}, waiting ${backoffSeconds}s');
          continue;
        }

        // Retry upload
        await _retryUpload(entry);
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Retry upload for a single entry
  Future<Result<void>> _retryUpload(JournalEntryModel entry) async {
    try {
      debugPrint('Retrying upload for entry ${entry.id} (attempt ${entry.uploadRetryCount + 1})');

      // Update to retrying status
      final retrying = entry.copyWith(
        uploadStatus: UploadStatus.retrying.index,
        lastUploadAttemptMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        uploadRetryCount: entry.uploadRetryCount + 1,
      );
      await localDataSource.updateEntry(retrying);

      // Load file from local path and retry based on type
      if (entry.localFilePath == null) {
        return const Error(ValidationFailure(message: 'Local file path missing'));
      }

      final file = File(entry.localFilePath!);
      if (!file.existsSync()) {
        return const Error(ValidationFailure(message: 'Local file not found'));
      }

      // Retry upload based on entry type
      final entryType = JournalEntryType.values[entry.entryType];
      Result<void> uploadResult;

      switch (entryType) {
        case JournalEntryType.image:
          if (entry.localThumbnailPath == null) {
            return const Error(ValidationFailure(message: 'Thumbnail path missing'));
          }
          final thumbnailFile = File(entry.localThumbnailPath!);
          uploadResult = await uploadService.uploadImageEntry(
            entry: entry,
            imageFile: file,
            thumbnailFile: thumbnailFile,
          );
          break;

        case JournalEntryType.audio:
          uploadResult = await uploadService.uploadAudioEntry(
            entry: entry,
            audioFile: file,
          );
          break;

        case JournalEntryType.text:
          // Text entries don't need upload
          final completed = entry.copyWith(
            uploadStatus: UploadStatus.completed.index,
            needsSync: false,
          );
          await localDataSource.updateEntry(completed);
          return const Success(null);
      }

      // Clear needsSync flag on success
      if (uploadResult.isSuccess) {
        final completed = entry.copyWith(needsSync: false);
        await localDataSource.updateEntry(completed);
      }

      return uploadResult;
    } catch (e) {
      return Error(UnknownFailure(message: 'Retry upload failed: $e'));
    }
  }

  /// Calculate exponential backoff: 2s, 4s, 8s, 16s, 32s
  int _calculateBackoff(int retryCount) {
    return 2 * (1 << retryCount);
  }
}
```

#### 5.6 Update Journal Controller

Add retry method:

```dart
Future<void> retryUpload(String entryId) async {
  try {
    final entry = await localDataSource.getEntryById(entryId);
    if (entry == null) return;

    // Retrieve original file from local path and retry upload
    // Implementation details depend on stored local paths
  } catch (e) {
    debugPrint('Retry failed: $e');
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter pub get`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Widget tests pass for Speed Dial FAB: `~/flutter/bin/flutter test test/core/widgets/`
- [ ] Integration tests pass: `~/flutter/bin/flutter test integration_test/`

#### Manual Verification:
- [ ] Journal screen shows "No entries yet" when empty
- [ ] Tapping FAB expands Speed Dial with 3 options
- [ ] Each option navigates to correct entry creation screen
- [ ] Created entries immediately appear in list
- [ ] Text entries show preview text
- [ ] Image entries show thumbnails (instant offline preview)
- [ ] Audio entries show duration
- [ ] Upload status badges display with correct colors:
  - Orange "Pending" for notStarted
  - Blue spinner "Uploading..." for uploading
  - Amber spinner "Retrying..." for retrying
  - Red "Failed" with retry button for failed
  - No badge for completed
- [ ] Failed uploads show retry button in entry card
- [ ] Retry button successfully re-uploads failed entries
- [ ] Background sync retries failed uploads automatically with exponential backoff
- [ ] AI transcription placeholder "Transcription pending..." appears for audio/image entries
- [ ] Sync All button in app bar triggers manual sync of all pending uploads
- [ ] Entries update reactively when upload status changes

**Implementation Note**: Test the complete flow end-to-end: create all three entry types, verify sync, test offline/online transitions.

---

## Testing Strategy

### Unit Tests

**Domain Layer**:
- Entity equality and copyWith methods
- Use case validation logic (empty text, missing files)
- Result type behavior

**Data Layer**:
- Model toEntity/fromEntity conversions
- Model toFirestoreMap serialization
- Local data source CRUD operations (mocked Isar)
- Remote data source Firestore operations (mocked)
- Repository offline-first logic with mocked connectivity

**Services**:
- Firebase Storage Service file upload/processing
- Audio Recording Service permission handling
- Image thumbnail generation
- Upload retry logic with exponential backoff

**Presentation Layer**:
- Controller state transitions
- Use case invocation with correct parameters
- Error message mapping

### Integration Tests

- Create text entry → appears in list
- Create image entry → thumbnail shows → uploads → completed
- Create audio entry → duration calculated → uploads → completed
- Offline creation → online sync
- Failed upload → retry succeeds
- Speed Dial FAB interaction

### Manual Testing Steps

1. **Text Entry Flow**:
   - Open app → Journal tab → Speed Dial → Text
   - Type content → Save
   - Verify appears in list immediately
   - Verify syncs to Firestore

2. **Image Entry Flow**:
   - Speed Dial → Image → Camera → Take photo → Save
   - Verify thumbnail shows instantly
   - Verify upload progresses
   - Repeat with Gallery option

3. **Audio Entry Flow**:
   - Speed Dial → Audio
   - Record for 10 seconds → Stop
   - Verify duration is correct
   - Verify upload progresses

4. **Offline Behavior**:
   - Turn off network
   - Create entries of each type
   - Verify all stored locally
   - Turn on network
   - Verify auto-sync occurs

5. **Retry Logic**:
   - Create image entry while offline
   - Force app to mark upload as failed
   - Tap retry button
   - Verify upload succeeds

6. **Error Handling**:
   - Deny camera permission → verify error message
   - Deny microphone permission → verify error message
   - Fill storage → verify graceful failure

---

## Performance Considerations

- **Image Processing**: Resize happens on background isolate (via `image` package)
- **Thumbnail Generation**: Small size (150x150) ensures fast loading
- **Image Compression**: 85-90% JPEG quality, max 1024px width before upload
- **Audio Encoding**: M4A/AAC format provides optimal compression without quality loss
- **Stream Updates**: Isar `.watch()` streams are efficient, only emit on actual changes to watched fields
- **Upload Queue**: Background uploads don't block UI, run asynchronously
- **Exponential Backoff**: Prevents hammering the server with failed uploads (2s → 4s → 8s → 16s → 32s)
- **Pagination**: Consider adding pagination if user has >100 entries
- **UTC Timestamps**: All timestamps stored in UTC to avoid timezone sync conflicts

## Migration Notes

No existing data to migrate. New Firestore collection `journalEntries` and Storage folders will be created with organized path structure:

**Firestore Collection**: `journalEntries`
- Documents keyed by entry ID
- Fields: id, userId, entryType, textContent, storageUrl, thumbnailUrl, audioDurationSeconds, transcription, aiProcessingStatus, createdAtMillis, modifiedAtMillis, isDeleted, version
- Indexes: userId (for queries), createdAtMillis (for sorting)

**Firebase Storage Paths**: `users/{userId}/journals/{journalId}/`
- Full images: `users/{userId}/journals/{journalId}/image.jpg`
- Thumbnails: `users/{userId}/journals/{journalId}/thumbnail.jpg`
- Audio files: `users/{userId}/journals/{journalId}/audio.m4a`

**Metadata attached to uploaded files**:
- `uploadedAt`: ISO 8601 timestamp (UTC)
- `fileType`: "image" | "audio" | "document"
- `duration`: Audio duration in seconds (audio files only)
- `entryId`: Journal entry ID for reference

This structure enables:
- Easy user data deletion (delete entire `users/{userId}/journals/` folder)
- Efficient Cloud Functions triggers (can listen to specific paths)
- Clear organization for future features (e.g., shared journals, exports)

## AI Integration Readiness

The journal feature is designed with AI processing in mind for future Cloud Functions implementation. Here's how the pipeline will work:

### Current Implementation (Phase 1)

**Data Model includes placeholder fields**:
- `transcription`: String? - Will store OCR/Speech-to-Text results
- `aiProcessingStatus`: enum (pending, processing, completed, failed)
- `metadata`: Map<String, dynamic>? - Can store AI-generated tags, sentiment, etc.

**UI shows placeholders**:
- Audio/Image entries display: "Transcription pending..."
- Subtle styling indicates AI processing hasn't occurred yet

### Future Cloud Functions Pipeline (Phase 2 - Separate Implementation)

**1. Storage Upload Trigger**:
```
Cloud Function listens to: users/{userId}/journals/{journalId}/*
Triggered when: New image.jpg or audio.m4a uploaded
```

**2. AI Processing**:
- **Images**: Extract text via OCR (Cloud Vision API, Tesseract)
- **Audio**: Transcribe speech (Cloud Speech-to-Text, Whisper API)
- Optional: Sentiment analysis, key phrase extraction, categorization

**3. Write Back to Firestore**:
```javascript
// Cloud Function updates Firestore document
await db.collection('journalEntries').doc(journalId).update({
  transcription: extractedText,
  aiProcessingStatus: 'completed',
  metadata: {
    sentiment: 'positive',
    tags: ['work', 'meeting', 'ideas'],
    confidence: 0.95
  },
  modifiedAtMillis: Date.now()
});
```

**4. Automatic UI Update**:
- Firestore update triggers local Isar sync (via repository sync method)
- Isar `.watch()` stream emits new data
- UI automatically updates to show transcription
- "Transcription pending..." changes to actual transcribed text

### Key Benefits of This Architecture

1. **Separation of Concerns**: Client handles capture/upload, backend handles AI processing
2. **Progressive Enhancement**: Feature works offline without AI, adds intelligence when online
3. **Reactive Updates**: No polling needed, Firestore listeners + Isar streams handle updates automatically
4. **Scalable**: Cloud Functions can process heavy workloads independently
5. **Testable**: Can test AI features by manually writing to Firestore
6. **Cost-Effective**: Only process files that are actually uploaded and need AI

### Testing AI Integration (Before Cloud Functions)

You can manually test the UI's reaction to AI updates:

```dart
// Manually update Firestore document to simulate Cloud Function
await FirebaseFirestore.instance
    .collection('journalEntries')
    .doc(entryId)
    .update({
  'transcription': 'This is a test transcription from AI',
  'aiProcessingStatus': 2, // completed
});

// Watch the UI update automatically via streams!
```

## References

- Existing pattern: [user_profile_repository_impl.dart:29-54](lib/features/profile/data/repositories/user_profile_repository_impl.dart#L29-L54) - Offline-first create
- Upload service: [firebase_image_storage_service.dart:18-84](lib/core/services/firebase_image_storage_service.dart#L18-L84) - Image upload with processing
- Controller pattern: [profile_controller.dart:83-150](lib/features/profile/presentation/controllers/profile_controller.dart#L83-L150) - Upload flow
- Reactive UI: [profile_screen.dart:34-118](lib/features/profile/presentation/screens/profile_screen.dart#L34-L118) - Stream consumption

---

## Plan Enhancements Summary

This implementation plan incorporates the following improvements based on architectural best practices:

### Storage & Upload
✅ Dynamic path building: `users/{userId}/journals/{journalId}/{filename}`
✅ Upload progress streams via `onProgress` callback
✅ Rich metadata on uploaded files (uploadedAt, fileType, duration, entryId)
✅ M4A/AAC audio encoding for optimal compression
✅ Image compression (85-90% JPEG, max 1024px) before upload

### Data Model & Sync
✅ `needsSync` boolean flag for simplified retry queue management
✅ `metadata` JSON field for future extensibility (AI tags, geolocation)
✅ UTC timestamps everywhere to prevent sync conflicts
✅ Exponential backoff (2s → 4s → 8s → 16s → 32s) for failed uploads
✅ Manual "Sync All" button plus automatic 5-minute background sync

### UI & UX
✅ Visual sync badges with color-coded statuses (orange/blue/amber/red/green)
✅ Instant thumbnail display for offline image preview
✅ "Transcription pending..." placeholders for AI-ready entries
✅ Reactive Isar `.watch()` streams trigger UI updates automatically
✅ Discard confirmation (future enhancement noted)

### AI Readiness
✅ Complete Cloud Functions pipeline documented
✅ Fields ready: `transcription`, `aiProcessingStatus`, `metadata`
✅ Automatic UI updates when backend writes transcription results
✅ Testing strategy for simulating AI updates before Cloud Functions exist

### Testing & Stability
✅ Unit tests for upload retry logic with exponential backoff
✅ Integration tests for Isar-Firestore sync consistency
✅ Tests for handling failed network states and offline behavior
✅ Clear automated vs manual verification criteria for each phase

---

**End of Implementation Plan**

This plan provides a complete, production-ready roadmap for implementing the Journal feature following the app's existing clean architecture patterns. Each phase builds incrementally with comprehensive testing, ensuring reliability and allowing for verification before proceeding. The final result will be a fully functional journal system with three entry types, robust offline support, intelligent sync/retry mechanisms, and readiness for future AI-powered features.
