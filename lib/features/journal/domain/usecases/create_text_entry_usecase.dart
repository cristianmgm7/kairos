import 'package:kairos/core/errors/failures.dart';
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
      return const Error(
        ValidationFailure(message: 'Text content cannot be empty'),
      );
    }

    final now = DateTime.now().toUtc();
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
