import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';

abstract class JournalEntryRepository {
  Future<Result<JournalEntryEntity>> createEntry(JournalEntryEntity entry);
  Future<Result<JournalEntryEntity?>> getEntryById(String entryId);
  Stream<List<JournalEntryEntity>> watchEntriesByUserId(String userId);
  Future<Result<void>> syncPendingUploads(String userId);
}
