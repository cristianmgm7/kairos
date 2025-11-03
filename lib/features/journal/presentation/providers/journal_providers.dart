import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_entry_repository_impl.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_entry_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';

// Data sources
final journalLocalDataSourceProvider = Provider<JournalEntryLocalDataSource>(
  (ref) {
    final isar = ref.watch(isarProvider);
    return JournalEntryLocalDataSourceImpl(isar);
  },
);

final journalRemoteDataSourceProvider = Provider<JournalEntryRemoteDataSource>(
  (ref) {
    final firestore = ref.watch(firestoreProvider);
    return JournalEntryRemoteDataSourceImpl(firestore);
  },
);

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

// Stream provider for journal entries
final journalEntriesStreamProvider =
    StreamProvider.family<List<JournalEntryEntity>, String>((ref, userId) {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.watchEntriesByUserId(userId);
});

// Controller
final journalControllerProvider =
    StateNotifierProvider<JournalController, JournalState>((ref) {
  final createTextEntryUseCase = ref.watch(createTextEntryUseCaseProvider);

  return JournalController(
    createTextEntryUseCase: createTextEntryUseCase,
    ref: ref,
  );
});
