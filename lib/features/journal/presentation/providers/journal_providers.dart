import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_message_remote_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_message_repository_impl.dart';
import 'package:kairos/features/journal/data/repositories/journal_thread_repository_impl.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';

// Data sources
final threadLocalDataSourceProvider =
    Provider<JournalThreadLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return JournalThreadLocalDataSourceImpl(isar);
});

final threadRemoteDataSourceProvider =
    Provider<JournalThreadRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return JournalThreadRemoteDataSourceImpl(firestore);
});

final messageLocalDataSourceProvider =
    Provider<JournalMessageLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return JournalMessageLocalDataSourceImpl(isar);
});

final messageRemoteDataSourceProvider =
    Provider<JournalMessageRemoteDataSource>((ref) {
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

// Services
final journalUploadServiceProvider = Provider<JournalUploadService>((ref) {
  final storageService = ref.watch(firebaseStorageServiceProvider);
  final messageRepository = ref.watch(messageRepositoryProvider);
  return JournalUploadService(
    storageService: storageService,
    messageRepository: messageRepository,
  );
});

// Use cases
final createTextMessageUseCaseProvider =
    Provider<CreateTextMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  return CreateTextMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
  );
});

final createImageMessageUseCaseProvider =
    Provider<CreateImageMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final storageService = ref.watch(firebaseStorageServiceProvider);
  return CreateImageMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    storageService: storageService,
  );
});

final createAudioMessageUseCaseProvider =
    Provider<CreateAudioMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  return CreateAudioMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
  );
});

// Stream providers
final threadsStreamProvider =
    StreamProvider.family<List<JournalThreadEntity>, String>((ref, userId) {
  final repository = ref.watch(threadRepositoryProvider);
  return repository.watchThreadsByUserId(userId);
});

final messagesStreamProvider =
    StreamProvider.family<List<JournalMessageEntity>, String>((ref, threadId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessagesByThreadId(threadId);
});

// Controller
final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase =
      ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase =
      ref.watch(createAudioMessageUseCaseProvider);
  final uploadService = ref.watch(journalUploadServiceProvider);
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  final audioRecorderService = ref.watch(audioRecorderServiceProvider);

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
    uploadService: uploadService,
    imagePickerService: imagePickerService,
    audioRecorderService: audioRecorderService,
  );
});
