import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_remote_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_entry_repository_impl.dart';
import 'package:kairos/features/journal/data/repositories/journal_message_repository_impl.dart';
import 'package:kairos/features/journal/data/repositories/journal_thread_repository_impl.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_entry_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';

// OLD Data sources (keeping for backward compatibility)
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

// NEW Data sources
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

// OLD Repository (keeping for backward compatibility)
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

// NEW Repositories
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

// OLD Use cases (keeping for backward compatibility)
final createTextEntryUseCaseProvider = Provider<CreateTextEntryUseCase>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return CreateTextEntryUseCase(repository);
});

// NEW Use cases
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

// OLD Stream provider (keeping for backward compatibility)
final journalEntriesStreamProvider =
    StreamProvider.family<List<JournalEntryEntity>, String>((ref, userId) {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.watchEntriesByUserId(userId);
});

// NEW Stream providers
final threadsStreamProvider = StreamProvider.family<List<JournalThreadEntity>, String>((ref, userId) {
  final repository = ref.watch(threadRepositoryProvider);
  return repository.watchThreadsByUserId(userId);
});

final messagesStreamProvider = StreamProvider.family<List<JournalMessageEntity>, String>((ref, threadId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessagesByThreadId(threadId);
});

// OLD Controller (keeping for backward compatibility)
final journalControllerProvider =
    StateNotifierProvider<JournalController, JournalState>((ref) {
  final createTextEntryUseCase = ref.watch(createTextEntryUseCaseProvider);

  return JournalController(
    createTextEntryUseCase: createTextEntryUseCase,
    ref: ref,
  );
});

// NEW Controller
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
