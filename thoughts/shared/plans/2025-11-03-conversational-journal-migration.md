# Conversational Journal Implementation Plan

## Overview

Kairos implements an AI-powered conversational journal where users create messages (text, audio, or image) within threads, forming a continuous reflective dialogue. The AI assistant can respond, summarize, or generate insights based on thread context, creating an intelligent journaling companion.

**Core Principle**: Each journal interaction is a message in an ongoing conversation, not an isolated entry. This enables contextual AI responses, semantic search, and progressive reflection over time.

## Architecture Vision

### Data Model

**Two-Entity Structure**:
- `JournalThreadEntity` - Represents a conversation/topic with metadata
- `JournalMessageEntity` - Individual messages within a thread (user, AI, or system)

### Design Principles

1. **Conversational First**: Everything is a message in a thread
2. **Offline-First**: Local persistence with background sync
3. **Clean Architecture**: Clear separation of domain, data, and presentation
4. **AI-Ready**: Built for contextual responses, embeddings, and semantic search
5. **Scalable**: Designed for future features (summarization, emotion tracking)

### User Experience

- **Thread List**: Conversational timeline showing recent threads
- **Thread Detail**: Chat-like interface with user/AI messages
- **Message Creation**: Text, audio, or image inputs create messages
- **AI Responses**: Assistant replies appear automatically when generated
- **Offline Support**: All messages saved locally, synced in background

## Desired End State

### Functional Requirements

**Thread Management**:
- Threads auto-created when user sends first message
- Thread title auto-generated from first message content
- Threads sorted by most recent activity
- Support for archiving threads (soft delete)

**Message Creation**:
- Text messages: Rich text input with instant save
- Audio messages: Record audio → transcribe → save with duration
- Image messages: Capture/select image → OCR → save with thumbnail

**AI Integration**:
- Cloud Functions listen for new user messages
- AI generates responses based on thread context
- Responses written to Firestore, auto-sync to client
- Support for system messages (summaries, insights)

**Sync & Upload**:
- Text/AI messages sync immediately
- Media messages upload in background with retry
- Upload status tracking (pending, uploading, completed, failed)
- AI processing status (pending, processing, completed, failed)

### Data Model Structure

#### JournalThreadEntity
```dart
{
  id: String (UUID),
  userId: String,
  title: String? (auto-generated or user-edited),
  createdAt: DateTime (UTC),
  updatedAt: DateTime (UTC),
  lastMessageAt: DateTime? (most recent message timestamp),
  messageCount: int (cached for performance),
  metadata: Map<String, dynamic>? (AI tags, categories, embeddings),
  isArchived: bool (soft archive flag)
}
```

#### JournalMessageEntity
```dart
{
  id: String (UUID),
  threadId: String (foreign key),
  userId: String,
  role: MessageRole (user | ai | system),
  messageType: MessageType (text | image | audio),
  content: String? (text content or AI response),
  createdAt: DateTime (UTC),

  // Media fields
  storageUrl: String? (Firebase Storage URL),
  thumbnailUrl: String? (for images),
  localFilePath: String? (local cache, user messages only),
  localThumbnailPath: String? (local thumbnail cache),
  audioDurationSeconds: int?,

  // AI processing
  transcription: String? (OCR/Speech-to-Text result),
  aiProcessingStatus: AiProcessingStatus,

  // Upload tracking
  uploadStatus: UploadStatus,
  uploadRetryCount: int,
  lastUploadAttemptAt: DateTime?,

  // Extensibility
  metadata: Map<String, dynamic>? (embeddings, tags, sentiment)
}
```

### Storage & Sync Architecture

**Firestore Collections**:
- `journalThreads` - Thread metadata
- `journalMessages` - All messages (user + AI)

**Firebase Storage Paths**:
- `users/{userId}/threads/{threadId}/messages/{messageId}/{file}`

**Offline-First Pattern**:
1. Save to local Isar database first
2. Sync to Firestore/Storage when online
3. Reactive streams update UI automatically
4. Background retry for failed uploads

## What We're NOT Implementing (Yet)

**Out of Scope**:
- Message editing or deletion UI (soft delete infrastructure only)
- Thread merging or splitting
- Full-text or semantic search (architecture supports it)
- Message reactions or annotations
- Thread sharing or collaboration
- Export functionality
- Waveform visualization for audio
- Rich text/Markdown formatting
- Live transcription during recording
- Image annotation or cropping
- Thread archiving UI (data model only)
- Pagination (implement when >100 threads)

---

## Phase 1: Core Domain Layer

### Overview
Define the domain entities, enums, and repository interfaces. This establishes the business logic layer with no dependencies on data sources or frameworks.

### Changes Required

#### 1.1 Message Role & Type Enums

**File**: `lib/features/journal/domain/entities/journal_message_entity.dart` (new)

```dart
import 'package:equatable/equatable.dart';

enum MessageRole {
  user,   // Human-created content
  ai,     // AI-generated responses
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
    );
  }
}
```

#### 1.2 Thread Entity

**File**: `lib/features/journal/domain/entities/journal_thread_entity.dart` (new)

```dart
import 'package:equatable/equatable.dart';

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
    );
  }
}
```

#### 1.3 Thread Repository Interface

**File**: `lib/features/journal/domain/repositories/journal_thread_repository.dart` (new)

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';

abstract class JournalThreadRepository {
  Future<Result<JournalThreadEntity>> createThread(JournalThreadEntity thread);
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId);
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId);
  Future<Result<void>> updateThread(JournalThreadEntity thread);
  Future<Result<void>> archiveThread(String threadId);
  Future<Result<void>> syncThreads(String userId);
}
```

#### 1.4 Message Repository Interface

**File**: `lib/features/journal/domain/repositories/journal_message_repository.dart` (new)

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

abstract class JournalMessageRepository {
  Future<Result<JournalMessageEntity>> createMessage(JournalMessageEntity message);
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId);
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId);
  Future<Result<void>> updateMessage(JournalMessageEntity message);
  Future<Result<void>> syncMessages(String threadId);
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(String userId);
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter analyze`
- [ ] No import errors
- [ ] Entities are immutable and equatable
- [ ] Repository interfaces compile without errors

#### Manual Verification:
- [ ] Entity `copyWith` methods work correctly
- [ ] Enums have correct values (user=0, ai=1, system=2)
- [ ] No references to "entry" or deprecated terminology

**Implementation Note**: This phase establishes the clean domain layer with no framework dependencies. All business logic lives here.

---

## Phase 2: Data Layer (Models & Isar Schemas)

### Overview
Create Isar models for local persistence and Firestore serialization. These map to domain entities while handling framework-specific concerns.

### Changes Required

#### 2.1 Thread Model (Isar)

**File**: `lib/features/journal/data/models/journal_thread_model.dart` (new)

```dart
import 'package:isar/isar.dart';
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
    this.version = 1,
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
    );
  }

  factory JournalThreadModel.fromMap(Map<String, dynamic> map) {
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
      version: map['version'] as int? ?? 1,
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
  final int version;

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
      'version': version,
    };
  }

  JournalThreadEntity toEntity() {
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
    int? version,
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
```

#### 2.2 Message Model (Isar)

**File**: `lib/features/journal/data/models/journal_message_model.dart` (new)

```dart
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
      createdAtMillis: now.millisecondsSinceEpoch,
      uploadStatus: messageType == MessageType.text ? 2 : 0, // text=completed, media=notStarted
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
      lastUploadAttemptMillis: entity.lastUploadAttemptAt?.millisecondsSinceEpoch,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
    );
  }

  factory JournalMessageModel.fromMap(Map<String, dynamic> map) {
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
      createdAtMillis: map['createdAtMillis'] as int,
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
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  JournalMessageEntity toEntity() {
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
      lastUploadAttemptAt: lastUploadAttemptMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUploadAttemptMillis!, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
    );
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
      lastUploadAttemptMillis: lastUploadAttemptMillis ?? this.lastUploadAttemptMillis,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
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
```

#### 2.3 Update Database Provider

**File**: `lib/core/providers/database_provider.dart` (update)

Replace old schema with new ones:

```dart
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      UserProfileModelSchema,
      SettingsModelSchema,
      JournalThreadModelSchema,
      JournalMessageModelSchema,
    ],
    directory: dir.path,
    name: 'kairos_db',
  );
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation succeeds: `~/flutter/bin/dart run build_runner build --delete-conflicting-outputs`
- [ ] No analyzer errors: `~/flutter/bin/flutter analyze`
- [ ] Isar schemas compile correctly
- [ ] All conversion methods work (toEntity, fromEntity, toFirestoreMap, fromMap)

#### Manual Verification:
- [ ] App launches without crashes
- [ ] Isar inspector shows `journalThreadModels` and `journalMessageModels` collections
- [ ] Model conversions preserve all data correctly
- [ ] No references to old journal entry models

**Implementation Note**: Remove all old journal entry files after confirming new schemas work.

---

## Phase 3: Data Sources & Repositories

### Overview
Implement local (Isar) and remote (Firestore) data sources, then build repositories that orchestrate offline-first logic.

### Changes Required

#### 3.1 Thread Local Data Source

**File**: `lib/features/journal/data/datasources/journal_thread_local_datasource.dart` (replace existing)

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

abstract class JournalThreadLocalDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
  Future<void> archiveThread(String threadId);
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId);
}

class JournalThreadLocalDataSourceImpl implements JournalThreadLocalDataSource {
  JournalThreadLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveThread(JournalThreadModel thread) async {
    await isar.writeTxn(() async {
      await isar.journalThreadModels.put(thread);
    });
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    return isar.journalThreadModels
        .filter()
        .idEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    return isar.journalThreadModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .isArchivedEqualTo(false)
        .findAll();
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    final updated = thread.copyWith(
      updatedAtMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      version: thread.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalThreadModels.put(updated);
    });
  }

  @override
  Future<void> archiveThread(String threadId) async {
    final thread = await getThreadById(threadId);
    if (thread != null) {
      final archived = thread.copyWith(
        isArchived: true,
        updatedAtMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.journalThreadModels.put(archived);
      });
    }
  }

  @override
  Stream<List<JournalThreadModel>> watchThreadsByUserId(String userId) {
    return isar.journalThreadModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .map((threads) => threads
            ..sort((a, b) {
              final aTime = a.lastMessageAtMillis ?? a.createdAtMillis;
              final bTime = b.lastMessageAtMillis ?? b.createdAtMillis;
              return bTime.compareTo(aTime);
            }));
  }
}
```

#### 3.2 Message Local Data Source

**File**: `lib/features/journal/data/datasources/journal_message_local_datasource.dart` (replace existing)

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

abstract class JournalMessageLocalDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getPendingUploads(String userId);
}

class JournalMessageLocalDataSourceImpl implements JournalMessageLocalDataSource {
  JournalMessageLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    await isar.writeTxn(() async {
      await isar.journalMessageModels.put(message);
    });
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    return isar.journalMessageModels
        .filter()
        .idEqualTo(messageId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId) async {
    return isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByCreatedAtMillis()
        .findAll();
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    final updated = message.copyWith(
      version: message.version + 1,
    );
    await isar.writeTxn(() async {
      await isar.journalMessageModels.put(updated);
    });
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId) {
    return isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((messages) => messages..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis)));
  }

  @override
  Future<List<JournalMessageModel>> getPendingUploads(String userId) async {
    return isar.journalMessageModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .roleEqualTo(0) // user messages only
        .and()
        .group((q) => q
            .uploadStatusEqualTo(0) // notStarted
            .or()
            .uploadStatusEqualTo(3)) // failed
        .findAll();
  }
}
```

#### 3.3 Thread Remote Data Source

**File**: `lib/features/journal/data/datasources/journal_thread_remote_datasource.dart` (replace existing)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

abstract class JournalThreadRemoteDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);
}

class JournalThreadRemoteDataSourceImpl implements JournalThreadRemoteDataSource {
  JournalThreadRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalThreads');

  @override
  Future<void> saveThread(JournalThreadModel thread) async {
    await _collection.doc(thread.id).set(thread.toFirestoreMap());
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    final doc = await _collection.doc(threadId).get();
    if (!doc.exists) return null;
    return JournalThreadModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .where('isArchived', isEqualTo: false)
        .orderBy('lastMessageAtMillis', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalThreadModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    await _collection.doc(thread.id).update(thread.toFirestoreMap());
  }
}
```

#### 3.4 Message Remote Data Source

**File**: `lib/features/journal/data/datasources/journal_message_remote_datasource.dart` (replace existing)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

abstract class JournalMessageRemoteDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId);
}

class JournalMessageRemoteDataSourceImpl implements JournalMessageRemoteDataSource {
  JournalMessageRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalMessages');

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    await _collection.doc(message.id).set(message.toFirestoreMap());
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    final doc = await _collection.doc(messageId).get();
    if (!doc.exists) return null;
    return JournalMessageModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId) async {
    final querySnapshot = await _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalMessageModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    await _collection.doc(message.id).update(message.toFirestoreMap());
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId) {
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalMessageModel.fromMap(doc.data()))
            .toList());
  }
}
```

#### 3.5 Thread Repository Implementation

**File**: `lib/features/journal/data/repositories/journal_thread_repository_impl.dart` (replace existing)

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';

class JournalThreadRepositoryImpl implements JournalThreadRepository {
  JournalThreadRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final JournalThreadLocalDataSource localDataSource;
  final JournalThreadRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalThreadEntity>> createThread(JournalThreadEntity thread) async {
    try {
      final model = JournalThreadModel.fromEntity(thread);
      await localDataSource.saveThread(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.saveThread(model);
        } catch (e) {
          debugPrint('Failed to sync thread to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create thread: $e'));
    }
  }

  @override
  Future<Result<JournalThreadEntity?>> getThreadById(String threadId) async {
    try {
      final localThread = await localDataSource.getThreadById(threadId);
      return Success(localThread?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get thread: $e'));
    }
  }

  @override
  Stream<List<JournalThreadEntity>> watchThreadsByUserId(String userId) {
    return localDataSource
        .watchThreadsByUserId(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> updateThread(JournalThreadEntity thread) async {
    try {
      final model = JournalThreadModel.fromEntity(thread);
      await localDataSource.updateThread(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.updateThread(model);
        } catch (e) {
          debugPrint('Failed to sync thread update to remote: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update thread: $e'));
    }
  }

  @override
  Future<Result<void>> archiveThread(String threadId) async {
    try {
      await localDataSource.archiveThread(threadId);

      if (await _isOnline) {
        try {
          final thread = await localDataSource.getThreadById(threadId);
          if (thread != null) {
            await remoteDataSource.updateThread(thread);
          }
        } catch (e) {
          debugPrint('Failed to sync thread archive to remote: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to archive thread: $e'));
    }
  }

  @override
  Future<Result<void>> syncThreads(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final remoteThreads = await remoteDataSource.getThreadsByUserId(userId);
      for (final thread in remoteThreads) {
        await localDataSource.saveThread(thread);
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync threads: $e'));
    }
  }
}
```

#### 3.6 Message Repository Implementation

**File**: `lib/features/journal/data/repositories/journal_message_repository_impl.dart` (replace existing)

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

class JournalMessageRepositoryImpl implements JournalMessageRepository {
  JournalMessageRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final JournalMessageLocalDataSource localDataSource;
  final JournalMessageRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalMessageEntity>> createMessage(JournalMessageEntity message) async {
    try {
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.saveMessage(model);

      // Text messages and AI messages sync immediately
      if (await _isOnline && (message.messageType == MessageType.text || message.role != MessageRole.user)) {
        try {
          await remoteDataSource.saveMessage(model);
          final synced = model.copyWith(uploadStatus: 2); // completed
          await localDataSource.updateMessage(synced);
        } catch (e) {
          debugPrint('Failed to sync message to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create message: $e'));
    }
  }

  @override
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId) async {
    try {
      final localMessage = await localDataSource.getMessageById(messageId);
      return Success(localMessage?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get message: $e'));
    }
  }

  @override
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId) {
    return localDataSource
        .watchMessagesByThreadId(threadId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> updateMessage(JournalMessageEntity message) async {
    try {
      final model = JournalMessageModel.fromEntity(message);
      await localDataSource.updateMessage(model);

      if (await _isOnline) {
        try {
          await remoteDataSource.updateMessage(model);
        } catch (e) {
          debugPrint('Failed to sync message update to remote: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update message: $e'));
    }
  }

  @override
  Future<Result<void>> syncMessages(String threadId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final remoteMessages = await remoteDataSource.getMessagesByThreadId(threadId);
      for (final message in remoteMessages) {
        await localDataSource.saveMessage(message);
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync messages: $e'));
    }
  }

  @override
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(String userId) async {
    try {
      final messages = await localDataSource.getPendingUploads(userId);
      return Success(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get pending uploads: $e'));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter analyze`
- [ ] Unit tests pass for datasources (with mocked Isar): `~/flutter/bin/flutter test test/features/journal/data/datasources/`
- [ ] Unit tests pass for repositories: `~/flutter/bin/flutter test test/features/journal/data/repositories/`

#### Manual Verification:
- [ ] Can create thread locally and sync to Firestore when online
- [ ] Can create message locally and sync to Firestore when online
- [ ] Offline creation works without errors
- [ ] Reactive streams emit new data on updates
- [ ] Pending uploads query returns correct messages

**Implementation Note**: Remove all old journal entry datasources and repositories after confirming new ones work.

---

## Phase 4: Use Cases & Business Logic

### Overview
Implement use cases for creating threads and messages. Each use case encapsulates a single business operation with proper validation.

### Changes Required

#### 4.1 Create Text Message Use Case

**File**: `lib/features/journal/domain/usecases/create_text_message_usecase.dart` (replace existing)

```dart
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:uuid/uuid.dart';

class CreateTextMessageParams {
  const CreateTextMessageParams({
    required this.userId,
    required this.content,
    this.threadId,
  });

  final String userId;
  final String content;
  final String? threadId;
}

class CreateTextMessageUseCase {
  CreateTextMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;

  Future<Result<JournalMessageEntity>> call(CreateTextMessageParams params) async {
    if (params.content.trim().isEmpty) {
      return const Error(ValidationFailure(message: 'Message content cannot be empty'));
    }

    try {
      String threadId;
      if (params.threadId != null) {
        threadId = params.threadId!;
      } else {
        final threadTitle = params.content.length > 50
            ? '${params.content.substring(0, 50)}...'
            : params.content;

        final now = DateTime.now().toUtc();
        final newThread = JournalThreadEntity(
          id: const Uuid().v4(),
          userId: params.userId,
          title: threadTitle,
          createdAt: now,
          updatedAt: now,
        );

        final threadResult = await threadRepository.createThread(newThread);
        if (threadResult.isError) {
          return Error(threadResult.failureOrNull!);
        }

        threadId = threadResult.dataOrNull!.id;
      }

      final now = DateTime.now().toUtc();
      final message = JournalMessageEntity(
        id: const Uuid().v4(),
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.text,
        content: params.content.trim(),
        createdAt: now,
        uploadStatus: UploadStatus.completed,
      );

      final messageResult = await messageRepository.createMessage(message);
      if (messageResult.isError) {
        return Error(messageResult.failureOrNull!);
      }

      final threadResult = await threadRepository.getThreadById(threadId);
      if (threadResult.dataOrNull != null) {
        final thread = threadResult.dataOrNull!;
        final updatedThread = thread.copyWith(
          lastMessageAt: now,
          messageCount: thread.messageCount + 1,
          updatedAt: now,
        );
        await threadRepository.updateThread(updatedThread);
      }

      return messageResult;
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create message: $e'));
    }
  }
}
```

#### 4.2 Create Image Message Use Case

**File**: `lib/features/journal/domain/usecases/create_image_message_usecase.dart` (new)

```dart
import 'dart:io';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:uuid/uuid.dart';

class CreateImageMessageParams {
  const CreateImageMessageParams({
    required this.userId,
    required this.imageFile,
    required this.thumbnailPath,
    this.threadId,
  });

  final String userId;
  final File imageFile;
  final String thumbnailPath;
  final String? threadId;
}

class CreateImageMessageUseCase {
  CreateImageMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;

  Future<Result<JournalMessageEntity>> call(CreateImageMessageParams params) async {
    if (!params.imageFile.existsSync()) {
      return const Error(ValidationFailure(message: 'Image file does not exist'));
    }

    try {
      String threadId;
      if (params.threadId != null) {
        threadId = params.threadId!;
      } else {
        final now = DateTime.now().toUtc();
        final newThread = JournalThreadEntity(
          id: const Uuid().v4(),
          userId: params.userId,
          title: 'Image Journal',
          createdAt: now,
          updatedAt: now,
        );

        final threadResult = await threadRepository.createThread(newThread);
        if (threadResult.isError) {
          return Error(threadResult.failureOrNull!);
        }

        threadId = threadResult.dataOrNull!.id;
      }

      final now = DateTime.now().toUtc();
      final message = JournalMessageEntity(
        id: const Uuid().v4(),
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.image,
        localFilePath: params.imageFile.path,
        localThumbnailPath: params.thumbnailPath,
        createdAt: now,
        uploadStatus: UploadStatus.notStarted,
      );

      final messageResult = await messageRepository.createMessage(message);
      if (messageResult.isError) {
        return Error(messageResult.failureOrNull!);
      }

      final threadResult = await threadRepository.getThreadById(threadId);
      if (threadResult.dataOrNull != null) {
        final thread = threadResult.dataOrNull!;
        final updatedThread = thread.copyWith(
          lastMessageAt: now,
          messageCount: thread.messageCount + 1,
          updatedAt: now,
        );
        await threadRepository.updateThread(updatedThread);
      }

      return messageResult;
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create image message: $e'));
    }
  }
}
```

#### 4.3 Create Audio Message Use Case

**File**: `lib/features/journal/domain/usecases/create_audio_message_usecase.dart` (new)

```dart
import 'dart:io';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:uuid/uuid.dart';

class CreateAudioMessageParams {
  const CreateAudioMessageParams({
    required this.userId,
    required this.audioFile,
    required this.durationSeconds,
    this.threadId,
  });

  final String userId;
  final File audioFile;
  final int durationSeconds;
  final String? threadId;
}

class CreateAudioMessageUseCase {
  CreateAudioMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;

  Future<Result<JournalMessageEntity>> call(CreateAudioMessageParams params) async {
    if (!params.audioFile.existsSync()) {
      return const Error(ValidationFailure(message: 'Audio file does not exist'));
    }

    try {
      String threadId;
      if (params.threadId != null) {
        threadId = params.threadId!;
      } else {
        final now = DateTime.now().toUtc();
        final newThread = JournalThreadEntity(
          id: const Uuid().v4(),
          userId: params.userId,
          title: 'Audio Recording (${params.durationSeconds}s)',
          createdAt: now,
          updatedAt: now,
        );

        final threadResult = await threadRepository.createThread(newThread);
        if (threadResult.isError) {
          return Error(threadResult.failureOrNull!);
        }

        threadId = threadResult.dataOrNull!.id;
      }

      final now = DateTime.now().toUtc();
      final message = JournalMessageEntity(
        id: const Uuid().v4(),
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.audio,
        localFilePath: params.audioFile.path,
        audioDurationSeconds: params.durationSeconds,
        createdAt: now,
        uploadStatus: UploadStatus.notStarted,
      );

      final messageResult = await messageRepository.createMessage(message);
      if (messageResult.isError) {
        return Error(messageResult.failureOrNull!);
      }

      final threadResult = await threadRepository.getThreadById(threadId);
      if (threadResult.dataOrNull != null) {
        final thread = threadResult.dataOrNull!;
        final updatedThread = thread.copyWith(
          lastMessageAt: now,
          messageCount: thread.messageCount + 1,
          updatedAt: now,
        );
        await threadRepository.updateThread(updatedThread);
      }

      return messageResult;
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create audio message: $e'));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter analyze`
- [ ] Unit tests pass for all use cases: `~/flutter/bin/flutter test test/features/journal/domain/usecases/`
- [ ] Use cases properly validate inputs
- [ ] Use cases correctly update thread metadata

#### Manual Verification:
- [ ] Creating text message in new thread → thread auto-created with title from content
- [ ] Creating text message in existing thread → message appended, thread updated
- [ ] Creating image/audio message → thread created with appropriate title
- [ ] Thread messageCount increments correctly
- [ ] Thread lastMessageAt updates to message timestamp

**Implementation Note**: Remove old CreateTextEntryUseCase after confirming new use cases work.

---

## Phase 5: Presentation Layer - Controllers & Providers

### Overview
Build controllers for state management and update providers for dependency injection.

### Changes Required

#### 5.1 Message Controller

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (replace `journal_controller.dart`)

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';

sealed class MessageState {}
class MessageInitial extends MessageState {}
class MessageLoading extends MessageState {}
class MessageSuccess extends MessageState {
  MessageSuccess(this.message);
  final JournalMessageEntity message;
}
class MessageError extends MessageState {
  MessageError(this.message);
  final String message;
}

class MessageController extends StateNotifier<MessageState> {
  MessageController({
    required this.createTextMessageUseCase,
    required this.createImageMessageUseCase,
    required this.createAudioMessageUseCase,
  }) : super(MessageInitial());

  final CreateTextMessageUseCase createTextMessageUseCase;
  final CreateImageMessageUseCase createImageMessageUseCase;
  final CreateAudioMessageUseCase createAudioMessageUseCase;

  Future<void> createTextMessage({
    required String userId,
    required String content,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateTextMessageParams(
      userId: userId,
      content: content,
      threadId: threadId,
    );

    final result = await createTextMessageUseCase.call(params);

    result.when(
      success: (message) {
        state = MessageSuccess(message);
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  Future<void> createImageMessage({
    required String userId,
    required File imageFile,
    required String thumbnailPath,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateImageMessageParams(
      userId: userId,
      imageFile: imageFile,
      thumbnailPath: thumbnailPath,
      threadId: threadId,
    );

    final result = await createImageMessageUseCase.call(params);

    result.when(
      success: (message) {
        state = MessageSuccess(message);
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  Future<void> createAudioMessage({
    required String userId,
    required File audioFile,
    required int durationSeconds,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateAudioMessageParams(
      userId: userId,
      audioFile: audioFile,
      durationSeconds: durationSeconds,
      threadId: threadId,
    );

    final result = await createAudioMessageUseCase.call(params);

    result.when(
      success: (message) {
        state = MessageSuccess(message);
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error: ${failure.message}',
      _ => 'An error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = MessageInitial();
  }
}
```

#### 5.2 Update Providers

**File**: `lib/features/journal/presentation/providers/journal_providers.dart` (replace existing)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_thread_repository_impl.dart';
import 'package:kairos/features/journal/data/repositories/journal_message_repository_impl.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';

// Data sources
final threadLocalDataSourceProvider = Provider<JournalThreadLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return JournalThreadLocalDataSourceImpl(isar);
});

final threadRemoteDataSourceProvider = Provider<JournalThreadRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return JournalThreadRemoteDataSourceImpl(firestore);
});

final messageLocalDataSourceProvider = Provider<JournalMessageLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return JournalMessageLocalDataSourceImpl(isar);
});

final messageRemoteDataSourceProvider = Provider<JournalMessageRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return JournalMessageRemoteDataSourceImpl(firestore);
});

// Repositories
final threadRepositoryProvider = Provider<JournalThreadRepository>((ref) {
  final localDataSource = ref.watch(threadLocalDataSourceProvider);
  final remoteDataSource = ref.watch(threadRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityProvider);

  return JournalThreadRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivity: connectivity,
  );
});

final messageRepositoryProvider = Provider<JournalMessageRepository>((ref) {
  final localDataSource = ref.watch(messageLocalDataSourceProvider);
  final remoteDataSource = ref.watch(messageRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityProvider);

  return JournalMessageRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivity: connectivity,
  );
});

// Use cases
final createTextMessageUseCaseProvider = Provider<CreateTextMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  return CreateTextMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
  );
});

final createImageMessageUseCaseProvider = Provider<CreateImageMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  return CreateImageMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
  );
});

final createAudioMessageUseCaseProvider = Provider<CreateAudioMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  return CreateAudioMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
  );
});

// Stream providers
final threadsStreamProvider = StreamProvider.family<List<JournalThreadEntity>, String>((ref, userId) {
  final repository = ref.watch(threadRepositoryProvider);
  return repository.watchThreadsByUserId(userId);
});

final messagesStreamProvider = StreamProvider.family<List<JournalMessageEntity>, String>((ref, threadId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessagesByThreadId(threadId);
});

// Controller
final messageControllerProvider = StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase = ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase = ref.watch(createAudioMessageUseCaseProvider);

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
  );
});
```

### Success Criteria

#### Automated Verification:
- [ ] Build succeeds: `~/flutter/bin/flutter analyze`
- [ ] No circular dependencies in providers
- [ ] Controllers compile without errors

#### Manual Verification:
- [ ] Provider graph initializes correctly
- [ ] Controllers can access use cases
- [ ] State transitions work properly

**Implementation Note**: Remove old journal_controller.dart after confirming new message_controller.dart works.

---

## Phase 6: UI - Thread List & Thread Detail

### Overview
Build the conversational UI: thread list screen and thread detail (chat) screen.

### Changes Required

*(Detailed UI implementation would continue here with screens and widgets similar to the previous plan, but adapted for clean implementation without migration references)*

---

## Testing Strategy

### Unit Tests
- Entity equality and copyWith methods
- Repository offline-first logic
- Use case validation
- Model conversions

### Integration Tests
- Thread creation flow
- Message creation in thread
- AI message sync from Firestore
- Offline/online transitions

### Manual Testing
- Create threads via different message types
- Send multiple messages in thread
- Verify conversational UI
- Test offline mode

---

## AI Integration Architecture

### Cloud Functions Flow
1. Firestore trigger on new user message
2. Fetch thread context (last N messages)
3. Call AI API (OpenAI/Gemini/Claude)
4. Write AI message to Firestore
5. Client syncs automatically

### Client-Side Handling
- Firestore listener automatically receives AI messages
- Repository syncs to local Isar
- UI updates reactively via streams

---

## References

- Existing offline-first pattern: [user_profile_repository_impl.dart:29-54](lib/features/profile/data/repositories/user_profile_repository_impl.dart#L29-L54)
- Controller state management: Current profile controller pattern
- Reactive streams: Isar `.watch()` with Riverpod StreamProvider

---

## Summary

This plan implements a clean, conversational journal system from scratch with:
- **Thread + Message architecture** for contextual conversations
- **Offline-first design** with Isar and Firebase sync
- **AI-ready infrastructure** for contextual responses
- **Clean architecture** with proper separation of concerns
- **No legacy code** - fresh implementation throughout
