# Incremental Message Sync with Offline Support Implementation Plan

## Overview

Implement incremental synchronization for journal messages to ensure the app maintains data consistency when offline, backgrounded, or when the Firestore stream listener is inactive. The system will use `updatedAt` timestamps to fetch only changed messages since the last sync, triggered by pull-to-refresh or automatic reconnection.

## Current State Analysis

### What Exists Now:

**Live Stream Sync:**
- `watchMessagesByThreadId()` in [journal_message_repository_impl.dart:96-191](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L96-L191)
- Works when online and actively watching
- Syncs remote Firestore changes to local Isar DB in real-time

**Basic Sync:**
- `syncMessages()` in [journal_message_repository_impl.dart:220-241](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L220-L241)
- Performs full thread sync (inefficient for large threads)
- Not incremental

**Connectivity:**
- `_isOnline` getter using connectivity_plus ([journal_message_repository_impl.dart:25-28](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L25-L28))
- `NetworkInfoImpl` service ([network_info.dart:10-22](lib/core/network/network_info.dart#L10-L22))
- `connectivityProvider` ([core_providers.dart:35-37](lib/core/providers/core_providers.dart#L35-L37))

**UI:**
- `ThreadDetailScreen` displays messages via `messagesStreamProvider` ([thread_detail_screen.dart:16-335](lib/features/journal/presentation/screens/thread_detail_screen.dart#L16-L335))
- No pull-to-refresh capability
- No auto-sync on reconnect

### Key Discoveries:

- Messages use `createdAtMillis` field (immutable) but lack `updatedAtMillis` for incremental sync
- Isar database schema needs migration to add `updatedAtMillis` field
- Firestore documents need `updatedAtMillis` field added
- Cloud Functions must update `updatedAtMillis` when writing AI responses
- No connectivity stream provider exists for reactive network state changes
- No use case exists for coordinating sync operations

### Constraints:

- Messages are stored in Isar (local) and Firestore (remote)
- Cloud Functions generate AI responses and write to Firestore
- Must maintain offline-first architecture
- Clean architecture layers must be preserved (data, domain, presentation)
- Riverpod providers used for dependency injection and state management

## Desired End State

After implementation:

1. **Incremental Sync**: Only messages updated since last sync are fetched from Firestore
2. **Auto-Sync on Reconnect**: When device reconnects and thread is active, automatic sync fires (debounced)
3. **Pull-to-Refresh**: Users can manually trigger sync via RefreshIndicator
4. **Timestamp Tracking**: All messages have `updatedAt` field that updates on every Firestore write
5. **Connectivity Stream**: Reactive stream exposes network state changes

### Verification:

1. Go offline, have AI respond (message queued in Firestore)
2. Come back online while viewing thread
3. After ~2 seconds, new AI message appears automatically
4. Pull down to manually refresh
5. Only new/updated messages fetched (verify in logs)

## What We're NOT Doing

- Global background sync for all threads (only active thread)
- Conflict resolution for simultaneous edits (messages are append-only)
- Delta sync for message content changes (full message objects synced)
- Sync for deleted messages (out of scope)
- Retry logic for failed syncs (can be added later)

## Implementation Approach

Implement incremental sync using timestamp-based queries, following clean architecture:

1. **Data Layer**: Add `updatedAtMillis` to model, extend data sources with incremental methods
2. **Domain Layer**: Create use case for sync, extend repository interface
3. **Presentation Layer**: Add connectivity stream provider, implement auto-sync listener and pull-to-refresh in UI

Use Firestore `where` query to filter messages by `updatedAtMillis > lastLocalUpdate`, ensuring only deltas are fetched.

---

## Phase 1: Add `updatedAt` Field to Data Models

### Overview
Add `updatedAtMillis` field to message entity, model, and database schema. Perform Isar migration to add the field to existing local data.

### Changes Required:

#### 1. Domain Entity - Add `updatedAt` field
**File**: [lib/features/journal/domain/entities/journal_message_entity.dart](lib/features/journal/domain/entities/journal_message_entity.dart)

Add `updatedAt` field to entity:

```dart
class JournalMessageEntity extends Equatable {
  const JournalMessageEntity({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.role,
    required this.messageType,
    required this.createdAt,
    required this.updatedAt, // NEW
    // ... existing fields
  });

  final String id;
  final String threadId;
  final String userId;
  final MessageRole role;
  final MessageType messageType;
  final DateTime createdAt;
  final DateTime updatedAt; // NEW
  // ... rest of fields

  @override
  List<Object?> get props => [
    id,
    threadId,
    userId,
    role,
    messageType,
    createdAt,
    updatedAt, // NEW
    // ... rest of props
  ];

  JournalMessageEntity copyWith({
    String? id,
    String? threadId,
    String? userId,
    MessageRole? role,
    MessageType? messageType,
    DateTime? createdAt,
    DateTime? updatedAt, // NEW
    // ... rest of parameters
  }) {
    return JournalMessageEntity(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // NEW
      // ... rest of fields
    );
  }
}
```

#### 2. Data Model - Add `updatedAtMillis` field
**File**: [lib/features/journal/data/models/journal_message_model.dart](lib/features/journal/data/models/journal_message_model.dart)

Add field and update methods:

```dart
@collection
class JournalMessageModel {
  JournalMessageModel({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.role,
    required this.messageType,
    required this.createdAtMillis,
    required this.updatedAtMillis, // NEW
    // ... existing fields
  });

  // ... existing factory methods

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
      role: 0,
      messageType: messageType.index,
      content: content,
      localFilePath: localFilePath,
      localThumbnailPath: localThumbnailPath,
      audioDurationSeconds: audioDurationSeconds,
      createdAtMillis: nowMillis,
      updatedAtMillis: nowMillis, // NEW - same as created initially
      uploadStatus: messageType == MessageType.text ? 2 : 0,
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
      // ... existing fields
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch, // NEW
      // ... rest
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
      // ... existing fields
      createdAtMillis: createdAt,
      updatedAtMillis: map['updatedAtMillis'] as int? ?? createdAt, // NEW - default to createdAt for backwards compatibility
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }

  final int createdAtMillis;
  @Index() // NEW - add index for efficient querying
  final int updatedAtMillis;
  // ... rest of fields

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'threadId': threadId,
      'userId': userId,
      'role': role,
      'messageType': messageType,
      'content': content,
      // ... existing fields
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis, // NEW
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
      // ... existing fields
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis, isUtc: true), // NEW
      // ... rest
    );
  }

  JournalMessageModel copyWith({
    String? id,
    String? threadId,
    String? userId,
    int? role,
    int? messageType,
    String? content,
    // ... existing parameters
    int? createdAtMillis,
    int? updatedAtMillis, // NEW
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
      // ... existing fields
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis, // NEW
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }
}
```

#### 3. Update Isar Schema Version
**File**: [lib/features/journal/data/models/journal_message_model.dart](lib/features/journal/data/models/journal_message_model.dart)

The schema version is managed by Isar automatically, but we need to regenerate the schema:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will update the generated `journal_message_model.g.dart` file with the new field.

#### 4. Migrate Existing Firestore Data (Cloud Function or Script)

**Note**: This step depends on your deployment process. You have two options:

**Option A: Lazy Migration (Recommended)**
- Existing documents without `updatedAtMillis` will default to `createdAtMillis` when read (already handled in `fromMap`)
- Cloud Function will add `updatedAtMillis` on next update
- No separate migration script needed

**Option B: Batch Migration Script**
- Create a one-time Cloud Function or script to update all existing messages:

```typescript
// functions/src/migrations/addUpdatedAtMillis.ts
import * as admin from 'firebase-admin';

async function migrateMessages() {
  const db = admin.firestore();
  const batch = db.batch();
  let count = 0;

  const snapshot = await db.collection('journalMessages').get();

  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.updatedAtMillis && data.createdAtMillis) {
      batch.update(doc.ref, { updatedAtMillis: data.createdAtMillis });
      count++;
    }
  });

  await batch.commit();
  console.log(`Migrated ${count} messages`);
}
```

**Recommendation**: Use Option A (lazy migration) for simplicity.

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] Build runner succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No type errors: `flutter analyze`
- [ ] Unit tests pass (if any exist for models): `flutter test`

#### Manual Verification:
- [ ] Create a new message in the app - verify `updatedAt` equals `createdAt` in local DB
- [ ] Check Firestore console - new messages have `updatedAtMillis` field
- [ ] Existing messages still load correctly (lazy migration working)
- [ ] App doesn't crash when reading old messages without `updatedAtMillis`

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that messages are being created with the new field before proceeding to Phase 2.

---

## Phase 2: Extend Data Sources with Incremental Query Methods

### Overview
Add methods to remote and local data sources to support incremental sync: `getUpdatedMessages()` in remote data source and `getLastUpdatedAtMillis()` in local data source.

### Changes Required:

#### 1. Remote Data Source - Add `getUpdatedMessages` method
**File**: [lib/features/journal/data/datasources/journal_message_remote_datasource.dart](lib/features/journal/data/datasources/journal_message_remote_datasource.dart)

Add new method to interface and implementation:

```dart
abstract class JournalMessageRemoteDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getUpdatedMessages(String threadId, int lastUpdatedAtMillis); // NEW
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId, String userId);
}

class JournalMessageRemoteDataSourceImpl implements JournalMessageRemoteDataSource {
  // ... existing implementation

  @override
  Future<List<JournalMessageModel>> getUpdatedMessages(
    String threadId,
    int lastUpdatedAtMillis,
  ) async {
    final querySnapshot = await _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .where('updatedAtMillis', isGreaterThan: lastUpdatedAtMillis)
        .orderBy('updatedAtMillis', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return JournalMessageModel.fromMap(data);
        })
        .toList();
  }
}
```

#### 2. Local Data Source - Add `getLastUpdatedAtMillis` method
**File**: [lib/features/journal/data/datasources/journal_message_local_datasource.dart](lib/features/journal/data/datasources/journal_message_local_datasource.dart)

Add method to get the latest `updatedAtMillis` for a thread:

```dart
abstract class JournalMessageLocalDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<int?> getLastUpdatedAtMillis(String threadId); // NEW
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getPendingUploads(String userId);
}

class JournalMessageLocalDataSourceImpl implements JournalMessageLocalDataSource {
  // ... existing implementation

  @override
  Future<int?> getLastUpdatedAtMillis(String threadId) async {
    final messages = await isar.journalMessageModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMillisDesc()
        .findAll();

    if (messages.isEmpty) return null;
    return messages.first.updatedAtMillis;
  }
}
```

#### 3. Local Data Source - Add bulk upsert helper (optional optimization)
**File**: [lib/features/journal/data/datasources/journal_message_local_datasource.dart](lib/features/journal/data/datasources/journal_message_local_datasource.dart)

Add method to efficiently save multiple messages:

```dart
abstract class JournalMessageLocalDataSource {
  // ... existing methods
  Future<void> saveMessages(List<JournalMessageModel> messages); // NEW
}

class JournalMessageLocalDataSourceImpl implements JournalMessageLocalDataSource {
  // ... existing implementation

  @override
  Future<void> saveMessages(List<JournalMessageModel> messages) async {
    await isar.writeTxn(() async {
      await isar.journalMessageModels.putAll(messages);
    });
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] Unit tests for data sources pass (if they exist): `flutter test test/features/journal/data/datasources/`

#### Manual Verification:
- [ ] Query Firestore for updated messages using Firebase console with filter `updatedAtMillis > [some timestamp]` - verify query works
- [ ] Test `getLastUpdatedAtMillis()` by checking local Isar DB inspector
- [ ] Verify no crashes when calling new methods

**Implementation Note**: After automated tests pass, manually verify the Firestore query works in the Firebase console before proceeding to Phase 3.

---

## Phase 3: Implement Incremental Sync in Repository

### Overview
Add `syncThreadIncremental()` method to repository that uses the new data source methods to fetch only changed messages and merge them into local DB.

### Changes Required:

#### 1. Repository Interface - Add sync method
**File**: [lib/features/journal/domain/repositories/journal_message_repository.dart](lib/features/journal/domain/repositories/journal_message_repository.dart)

Add new method to interface:

```dart
abstract class JournalMessageRepository {
  Future<Result<JournalMessageEntity>> createMessage(JournalMessageEntity message);
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId);
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId);
  Future<Result<void>> updateMessage(JournalMessageEntity message);
  Future<Result<void>> syncMessages(String threadId);
  Future<Result<void>> syncThreadIncremental(String threadId); // NEW
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(String userId);
}
```

#### 2. Repository Implementation - Implement incremental sync
**File**: [lib/features/journal/data/repositories/journal_message_repository_impl.dart](lib/features/journal/data/repositories/journal_message_repository_impl.dart)

Add implementation:

```dart
@override
Future<Result<void>> syncThreadIncremental(String threadId) async {
  try {
    if (!await _isOnline) {
      return const Error(NetworkFailure(message: 'Device is offline'));
    }

    // Get the latest updatedAtMillis from local DB
    final lastUpdatedAtMillis = await localDataSource.getLastUpdatedAtMillis(threadId);

    // If no messages exist locally, use 0 to fetch all messages
    final sinceTimestamp = lastUpdatedAtMillis ?? 0;

    debugPrint('🔄 Incremental sync for thread $threadId since timestamp: $sinceTimestamp');

    // Fetch only messages updated after the last local timestamp
    final updatedMessages = await remoteDataSource.getUpdatedMessages(
      threadId,
      sinceTimestamp,
    );

    debugPrint('📥 Fetched ${updatedMessages.length} updated messages');

    if (updatedMessages.isEmpty) {
      debugPrint('✅ No new messages to sync');
      return const Success(null);
    }

    // Merge updated messages into local DB
    // Use saveMessages for bulk insert if available, otherwise loop
    for (final message in updatedMessages) {
      final existingMessage = await localDataSource.getMessageById(message.id);

      if (existingMessage != null) {
        // Message exists locally - merge remote updates with local-only fields
        final isNonUser = message.role != MessageRole.user.index;
        final isText = message.messageType == MessageType.text.index;

        final int uploadStatusToUse;
        if (isNonUser || isText) {
          uploadStatusToUse = UploadStatus.completed.index;
        } else if (message.uploadStatus > existingMessage.uploadStatus) {
          uploadStatusToUse = message.uploadStatus;
        } else {
          uploadStatusToUse = existingMessage.uploadStatus;
        }

        final mergedModel = message.copyWith(
          uploadStatus: uploadStatusToUse,
          uploadRetryCount: existingMessage.uploadRetryCount,
          localFilePath: existingMessage.localFilePath,
          localThumbnailPath: existingMessage.localThumbnailPath,
          audioDurationSeconds: existingMessage.audioDurationSeconds,
        );

        await localDataSource.updateMessage(mergedModel);
        debugPrint('📝 Updated message: ${message.id}');
      } else {
        // New message from remote (e.g., AI response)
        final normalized = message.copyWith(
          uploadStatus: UploadStatus.completed.index,
        );
        await localDataSource.saveMessage(normalized);
        debugPrint('✨ Added new message: ${message.id}');
      }
    }

    debugPrint('✅ Incremental sync completed successfully');
    return const Success(null);
  } catch (e) {
    debugPrint('❌ Incremental sync failed: $e');
    if (e.toString().contains('network')) {
      return Error(NetworkFailure(message: 'Network error during sync: $e'));
    }
    return Error(ServerFailure(message: 'Failed to sync messages: $e'));
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] Repository tests pass (if they exist): `flutter test test/features/journal/data/repositories/`

#### Manual Verification:
- [ ] Create messages in thread A
- [ ] Go offline, have Cloud Function write AI response to thread A
- [ ] Come back online
- [ ] Call `syncThreadIncremental(threadA.id)` manually via debug button or console
- [ ] Verify only the new AI message is fetched (check debug logs for count)
- [ ] Verify AI message appears in local DB and UI
- [ ] Repeat with thread that has no updates - verify "No new messages to sync" log appears

**Implementation Note**: After manual testing confirms incremental sync works, proceed to Phase 4 to create the use case layer.

---

## Phase 4: Create Sync Use Case

### Overview
Create a use case to encapsulate the incremental sync logic, making it reusable from UI and services.

### Changes Required:

#### 1. Create `SyncThreadMessagesUseCase`
**File**: `lib/features/journal/domain/usecases/sync_thread_messages_usecase.dart` (NEW FILE)

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

class SyncThreadMessagesUseCase {
  SyncThreadMessagesUseCase({required this.messageRepository});

  final JournalMessageRepository messageRepository;

  /// Performs incremental sync for the given thread
  /// Fetches only messages updated since the last local timestamp
  Future<Result<void>> execute(String threadId) async {
    return await messageRepository.syncThreadIncremental(threadId);
  }
}
```

#### 2. Add Use Case Provider
**File**: [lib/features/journal/presentation/providers/journal_providers.dart](lib/features/journal/presentation/providers/journal_providers.dart)

Add provider for the new use case:

```dart
import 'package:kairos/features/journal/domain/usecases/sync_thread_messages_usecase.dart';

// ... existing imports and providers

final syncThreadMessagesUseCaseProvider = Provider<SyncThreadMessagesUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return SyncThreadMessagesUseCase(messageRepository: messageRepository);
});
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] Use case tests pass (if they exist): `flutter test test/features/journal/domain/usecases/`

#### Manual Verification:
- [ ] Import and call use case from a debug screen or test file
- [ ] Verify it delegates to repository correctly
- [ ] Check that Result type is returned properly

**Implementation Note**: This is a simple layer - automated checks should be sufficient. Proceed to Phase 5 after tests pass.

---

## Phase 5: Add Connectivity Stream Provider

### Overview
Create a reactive connectivity stream provider that emits network status changes, enabling UI to listen for reconnection events.

### Changes Required:

#### 1. Extend `NetworkInfo` with Stream
**File**: [lib/core/network/network_info.dart](lib/core/network/network_info.dart)

Add stream to interface and implementation:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream; // NEW
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  @override
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    });
  }
}

/// NetworkInfo provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

/// Connectivity stream provider - emits true when connected, false when offline
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.connectivityStream;
});
```

#### 2. Test Stream Provider
**File**: [lib/core/network/network_info.dart](lib/core/network/network_info.dart)

No additional code needed - the stream is ready to use.

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] Network info tests pass (if they exist): `flutter test test/core/network/`

#### Manual Verification:
- [ ] Create a debug screen that watches `connectivityStreamProvider`
- [ ] Display current connectivity status
- [ ] Toggle airplane mode on/off
- [ ] Verify stream emits `false` when offline, `true` when online
- [ ] Check for rapid/duplicate events (should see immediate state changes)

**Implementation Note**: After manual testing confirms the stream works, proceed to Phase 6 to integrate with UI.

---

## Phase 6: Implement Auto-Sync on Reconnect in ThreadDetailScreen

### Overview
Add `ref.listen` to ThreadDetailScreen to detect connectivity changes and trigger incremental sync when the device reconnects (debounced by 2 seconds).

### Changes Required:

#### 1. Add Auto-Sync Listener in `initState()`
**File**: [lib/features/journal/presentation/screens/thread_detail_screen.dart](lib/features/journal/presentation/screens/thread_detail_screen.dart)

Import timer for debouncing:

```dart
import 'dart:async';
```

Add fields to state class:

```dart
class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentThreadId;

  // NEW - for debounced auto-sync
  Timer? _syncDebounceTimer;
  bool _wasOffline = false;

  // ... existing code
}
```

Update `initState()` to add connectivity listener:

```dart
@override
void initState() {
  super.initState();
  _currentThreadId = widget.threadId;

  // NEW - Listen for connectivity changes (auto-sync on reconnect)
  // Using Future.microtask to safely access ref in initState
  Future.microtask(() {
    ref.listen<AsyncValue<bool>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((isOnline) {
          // Detect transition from offline to online
          if (_wasOffline && isOnline && _currentThreadId != null) {
            debugPrint('🌐 Device reconnected - scheduling incremental sync');

            // Cancel any pending sync timer
            _syncDebounceTimer?.cancel();

            // Debounce sync by 2 seconds after reconnection
            _syncDebounceTimer = Timer(const Duration(seconds: 2), () {
              debugPrint('🔄 Triggering auto-sync for thread: $_currentThreadId');
              _performIncrementalSync();
            });
          }

          // Update offline tracking state
          _wasOffline = !isOnline;
        });
      },
    );
  });
}
```

Add helper method for sync:

```dart
void _performIncrementalSync() {
  if (_currentThreadId == null) return;

  final syncUseCase = ref.read(syncThreadMessagesUseCaseProvider);
  syncUseCase.execute(_currentThreadId!).then((result) {
    result.when(
      success: (_) {
        debugPrint('✅ Auto-sync completed successfully');
      },
      error: (failure) {
        debugPrint('❌ Auto-sync failed: ${failure.message}');
        // Optionally show a subtle error indicator (not a snackbar to avoid disruption)
      },
    );
  });
}
```

Update `dispose()` to clean up timer:

```dart
@override
void dispose() {
  _messageController.dispose();
  _scrollController.dispose();
  _syncDebounceTimer?.cancel(); // NEW
  super.dispose();
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] No widget rebuild loops detected

#### Manual Verification:
- [ ] Open thread detail screen
- [ ] Have another device/Cloud Function write a new AI message to Firestore
- [ ] Turn on airplane mode on the test device
- [ ] Wait a few seconds
- [ ] Turn off airplane mode
- [ ] Within ~2 seconds of reconnection, verify the new AI message appears
- [ ] Check debug logs for "Device reconnected" and "Triggering auto-sync" messages
- [ ] Verify rapid connectivity flapping doesn't trigger multiple syncs (debounce working)

**Implementation Note**: After manual verification, proceed to Phase 7 to add pull-to-refresh.

---

## Phase 7: Add Pull-to-Refresh in ThreadDetailScreen

### Overview
Wrap the message list in a `RefreshIndicator` to allow users to manually trigger incremental sync via pull-down gesture.

### Changes Required:

#### 1. Wrap ListView with RefreshIndicator
**File**: [lib/features/journal/presentation/screens/thread_detail_screen.dart](lib/features/journal/presentation/screens/thread_detail_screen.dart)

Modify the `Expanded` widget that contains the message list:

```dart
Expanded(
  child: messagesAsync.when(
    data: (messages) {
      if (messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Start a conversation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Type your first message below to begin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Scroll to bottom when messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // NEW - Wrap ListView in RefreshIndicator
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          itemCount: messages.length + (hasAiPending ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return const AiTypingIndicator();
            }

            final message = messages[index];
            final isUserMessage = message.role == MessageRole.user;

            return MessageBubble(
              message: message,
              isUserMessage: isUserMessage,
            );
          },
        ),
      );
    },
    loading: () => const Center(
      child: CircularProgressIndicator(),
    ),
    error: (error, stack) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading messages',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  ),
),
```

Add refresh handler method:

```dart
Future<void> _handleRefresh() async {
  if (_currentThreadId == null) return;

  debugPrint('🔄 Manual refresh triggered for thread: $_currentThreadId');

  final syncUseCase = ref.read(syncThreadMessagesUseCaseProvider);
  final result = await syncUseCase.execute(_currentThreadId!);

  result.when(
    success: (_) {
      debugPrint('✅ Manual sync completed successfully');
    },
    error: (failure) {
      debugPrint('❌ Manual sync failed: ${failure.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Type checking passes: `flutter analyze`
- [ ] No widget errors in test runs

#### Manual Verification:
- [ ] Open thread detail screen
- [ ] Pull down on the message list
- [ ] Verify refresh indicator appears
- [ ] Verify sync is triggered (check debug logs)
- [ ] Have another device create a new message in Firestore
- [ ] Pull to refresh
- [ ] Verify new message appears after refresh completes
- [ ] Pull to refresh when offline - verify error snackbar appears
- [ ] Pull to refresh when no new messages exist - verify no errors, smooth completion

**Implementation Note**: After manual testing confirms pull-to-refresh works correctly, proceed to Phase 8.

---

## Phase 8: Update Cloud Function to Set `updatedAtMillis`

### Overview
Modify the Cloud Function that generates AI responses to ensure it sets `updatedAtMillis` when writing messages to Firestore, enabling incremental sync to detect new AI responses.

### Changes Required:

#### 1. Update Cloud Function - Set `updatedAtMillis` on Write
**File**: `functions/src/journal/onMessageCreated.ts` (or wherever your AI response function lives)

**Note**: The exact file path depends on your Cloud Functions structure. Look for the function triggered by `onCreate` for `journalMessages`.

Add `updatedAtMillis` when creating AI response message:

```typescript
import * as admin from 'firebase-admin';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';

export const onMessageCreated = functions.firestore
  .document('journalMessages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const messageId = context.params.messageId;

    // Only process user messages
    if (message.role !== 0) return; // 0 = user role

    try {
      // Generate AI response (your existing logic)
      const aiResponseText = await generateAIResponse(message.content);

      const now = Date.now();

      // Create AI response message
      const aiMessage = {
        id: admin.firestore().collection('journalMessages').doc().id,
        threadId: message.threadId,
        userId: message.userId,
        role: 1, // AI role
        messageType: 0, // text
        content: aiResponseText,
        createdAtMillis: now,
        updatedAtMillis: now, // NEW - set updatedAtMillis
        aiProcessingStatus: 2, // completed
        isDeleted: false,
        version: 1,
      };

      // Write AI message to Firestore
      await admin.firestore()
        .collection('journalMessages')
        .doc(aiMessage.id)
        .set(aiMessage);

      // Update the original user message's AI processing status
      await snapshot.ref.update({
        aiProcessingStatus: 2, // completed
        updatedAtMillis: now, // NEW - update timestamp on status change
      });

      console.log(`AI response created for message ${messageId}`);
    } catch (error) {
      console.error('Error generating AI response:', error);

      // Mark user message as failed
      await snapshot.ref.update({
        aiProcessingStatus: 3, // failed
        updatedAtMillis: Date.now(), // NEW - update timestamp on failure
      });
    }
  });
```

#### 2. Update Any Other Cloud Functions that Modify Messages

If you have other Cloud Functions that update message fields (e.g., transcription processing, storage URL updates), ensure they also update `updatedAtMillis`:

```typescript
// Example: When updating transcription
await messageRef.update({
  transcription: transcribedText,
  aiProcessingStatus: 2, // completed
  updatedAtMillis: Date.now(), // NEW - always update timestamp
});
```

#### 3. Deploy Cloud Functions

Deploy the updated functions:

```bash
firebase deploy --only functions
```

### Success Criteria:

#### Automated Verification:
- [ ] Cloud Functions compile without errors: `npm run build` (in functions directory)
- [ ] Linting passes: `npm run lint` (in functions directory)
- [ ] Functions deploy successfully: `firebase deploy --only functions`

#### Manual Verification:
- [ ] Create a new user message in the app
- [ ] Wait for AI response to be generated
- [ ] Check Firestore console for the AI response message
- [ ] Verify `updatedAtMillis` field exists and has a recent timestamp
- [ ] Check the original user message - verify `updatedAtMillis` was updated when `aiProcessingStatus` changed
- [ ] Trigger incremental sync from app - verify it picks up the new AI message
- [ ] Test offline-to-online flow:
  - Go offline
  - Cloud Function writes AI response (message queued in Firestore)
  - Come back online while viewing thread
  - After ~2 seconds, verify AI message appears via auto-sync

**Implementation Note**: After manual testing confirms Cloud Functions are updating `updatedAtMillis` correctly, the implementation is complete. Proceed to Phase 9 for final integration testing.

---

## Phase 9: End-to-End Integration Testing

### Overview
Perform comprehensive end-to-end testing to verify the entire incremental sync flow works correctly across all scenarios.

### Test Scenarios:

#### Test 1: Online Stream Sync (Baseline - Should Still Work)
1. Open thread detail screen while online
2. Send a message
3. Verify AI response appears in real-time via stream
4. **Expected**: Live stream sync works as before, no regression

#### Test 2: Pull-to-Refresh Sync
1. Have another device/Cloud Function create a message in Firestore
2. Wait a few seconds (don't let live stream pick it up if app is backgrounded)
3. Open thread detail screen
4. Pull down to refresh
5. **Expected**: New message appears after refresh completes

#### Test 3: Auto-Sync on Reconnect
1. Open thread detail screen
2. Turn on airplane mode
3. Have Cloud Function write an AI message to Firestore (via another trigger or manually)
4. Wait 5 seconds
5. Turn off airplane mode
6. **Expected**: Within ~2 seconds of reconnection, new AI message appears automatically

#### Test 4: Incremental Sync Efficiency
1. Create a thread with 50 messages
2. Note the `updatedAtMillis` of the latest message
3. Have Cloud Function add 1 new message
4. Trigger pull-to-refresh
5. Check debug logs
6. **Expected**: Logs show "Fetched 1 updated messages", not 51

#### Test 5: Empty Sync (No New Messages)
1. Open thread detail screen
2. Pull to refresh when no new messages exist remotely
3. **Expected**: Refresh completes smoothly, logs show "No new messages to sync"

#### Test 6: Offline Pull-to-Refresh
1. Turn on airplane mode
2. Open thread detail screen
3. Pull to refresh
4. **Expected**: Error snackbar appears: "Device is offline"

#### Test 7: Multiple Rapid Reconnects (Debounce Test)
1. Open thread detail screen
2. Rapidly toggle airplane mode on/off 5 times within 5 seconds
3. **Expected**: Only one sync is triggered after the last reconnection (2-second debounce working)

#### Test 8: Background to Foreground
1. Open thread detail screen
2. Background the app
3. Have Cloud Function write a message
4. Wait 10 seconds
5. Foreground the app
6. Pull to refresh
7. **Expected**: New message appears

### Success Criteria:

#### Automated Verification:
- [ ] All unit tests pass: `flutter test`
- [ ] All integration tests pass (if they exist): `flutter test integration_test/`
- [ ] No analyzer warnings: `flutter analyze`
- [ ] App builds successfully: `flutter build apk --debug` (Android) or `flutter build ios --debug` (iOS)

#### Manual Verification:
- [ ] All 8 test scenarios pass
- [ ] No crashes or exceptions during testing
- [ ] Debug logs show expected sync behavior
- [ ] UI remains responsive during sync operations
- [ ] No duplicate messages appear in the list
- [ ] Message order is correct (sorted by `createdAtMillis`)

**Implementation Note**: This is the final phase. Once all tests pass, the feature is complete and ready for production.

---

## Testing Strategy

### Unit Tests:

**Data Layer:**
- Test `JournalMessageModel.fromMap()` with and without `updatedAtMillis` (backwards compatibility)
- Test `getUpdatedMessages()` query in remote data source (mock Firestore)
- Test `getLastUpdatedAtMillis()` in local data source (mock Isar)

**Domain Layer:**
- Test `SyncThreadMessagesUseCase.execute()` returns correct Result types
- Test repository `syncThreadIncremental()` logic with mock data sources

**Presentation Layer:**
- Test connectivity stream provider emits correct states
- Test debounce timer cancels properly on dispose

### Integration Tests:

**End-to-End Sync Flow:**
- Create message, trigger sync, verify it appears in local DB
- Test offline-to-online transition triggers sync
- Test pull-to-refresh calls use case correctly

### Manual Testing Steps:

1. **Baseline Test**: Verify existing stream sync still works
2. **Incremental Sync Test**: Verify only new messages are fetched (check logs)
3. **Auto-Sync Test**: Go offline, come back online, verify auto-sync fires
4. **Pull-to-Refresh Test**: Pull down, verify sync is triggered
5. **Debounce Test**: Rapid reconnects, verify only one sync happens
6. **Error Handling Test**: Pull-to-refresh while offline, verify error message
7. **Large Thread Test**: Test with 100+ messages, verify performance is acceptable
8. **Cloud Function Test**: Verify AI responses have `updatedAtMillis` in Firestore

---

## Performance Considerations

### Firestore Query Optimization:
- `updatedAtMillis` field has an index for efficient querying
- Queries filter by `threadId`, `isDeleted`, and `updatedAtMillis` (composite index may be required)
- Firestore will auto-suggest composite indexes if needed

### Local Database Performance:
- Isar index on `updatedAtMillis` ensures fast `sortByUpdatedAtMillisDesc()` queries
- Bulk upsert via `saveMessages()` reduces transaction overhead

### Network Efficiency:
- Incremental sync fetches only deltas, not full thread history
- Debounce prevents rapid sync spam on flaky connections
- Existing stream sync handles real-time updates when active

### UI Responsiveness:
- Sync operations run asynchronously (don't block UI)
- Pull-to-refresh provides visual feedback
- Auto-sync is silent (no disruptive UI changes)

---

## Migration Notes

### Database Migration (Isar):
- Isar auto-migrates when schema changes (adding `updatedAtMillis` field)
- Existing messages will have `updatedAtMillis = null` initially
- `fromMap()` defaults `updatedAtMillis` to `createdAtMillis` for backwards compatibility
- No manual migration script needed

### Firestore Migration:
- Use lazy migration: existing documents without `updatedAtMillis` default to `createdAtMillis` when read
- Cloud Functions will add `updatedAtMillis` on next update
- Optional: Run batch migration script to backfill existing documents (see Phase 1)

### Cloud Functions Deployment:
- Deploy updated functions that set `updatedAtMillis`
- No breaking changes to existing functions
- Backwards compatible: old client versions will ignore the new field

---

## References

- Current repository implementation: [journal_message_repository_impl.dart](lib/features/journal/data/repositories/journal_message_repository_impl.dart)
- Stream sync logic: [journal_message_repository_impl.dart:96-191](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L96-L191)
- ThreadDetailScreen: [thread_detail_screen.dart](lib/features/journal/presentation/screens/thread_detail_screen.dart)
- NetworkInfo: [network_info.dart](lib/core/network/network_info.dart)
- Connectivity provider: [core_providers.dart:35-37](lib/core/providers/core_providers.dart#L35-L37)
