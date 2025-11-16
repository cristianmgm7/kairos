import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

/// Repository for journal messages - coordinates local and remote data sources
///
/// Responsibilities:
/// - Pure CRUD operations (create, read, update, delete)
/// - Coordinate between local (Isar) and remote (Firestore) data sources
/// - Provide streams for reactive UI updates
///
/// Does NOT handle:
/// - Business logic or state transitions
/// - File uploads or AI processing
/// - Retry logic or error recovery
/// - Status manipulation based on message type
///
/// Use cases are responsible for setting correct status before calling repository.
abstract class JournalMessageRepository {
  /// Create new message
  ///
  /// Always saves to local database first, then attempts remote save.
  /// Returns success if local save succeeds, even if remote fails.
  /// Entity should have status set by use case before calling.
  Future<Result<JournalMessageEntity>> createMessage(JournalMessageEntity message);

  /// Get message by ID from local database
  Future<Result<JournalMessageEntity?>> getMessageById(String messageId);

  /// Watch messages in a thread
  ///
  /// Returns stream of messages from local database.
  /// Automatically syncs updates from remote in the background.
  Stream<List<JournalMessageEntity>> watchMessagesByThreadId(String threadId);

  /// Update existing message
  ///
  /// Updates local database first, then attempts remote update.
  /// Returns success if local update succeeds, even if remote fails.
  /// Entity should have status set by use case before calling.
  Future<Result<void>> updateMessage(JournalMessageEntity message);

  /// Full sync of messages for a thread
  Future<Result<void>> syncMessages(String threadId);

  /// Incremental sync - fetch only messages updated since last sync
  Future<Result<void>> syncThreadIncremental(String threadId);

  /// Get messages with pending uploads (for background sync)
  Future<Result<List<JournalMessageEntity>>> getPendingUploads(String userId);
}
