import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/delete_thread_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/retry_message_pipeline_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/sync_thread_messages_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/sync_threads_usecase.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';
import 'package:kairos/core/sync/sync_controller.dart';
import 'package:kairos/features/journal/presentation/controllers/thread_controller.dart';

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

  return JournalThreadRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final messageRepositoryProvider = Provider<JournalMessageRepository>((ref) {
  final localDataSource = ref.watch(messageLocalDataSourceProvider);
  final remoteDataSource = ref.watch(messageRemoteDataSourceProvider);

  return JournalMessageRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// Services
final aiServiceClientProvider = Provider<AiServiceClient>((ref) {
  return AiServiceClient(FirebaseFunctions.instance);
});

// Use cases
final createTextMessageUseCaseProvider = Provider<CreateTextMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final aiServiceClient = ref.watch(aiServiceClientProvider);
  return CreateTextMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    aiServiceClient: aiServiceClient,
  );
});

final createImageMessageUseCaseProvider = Provider<CreateImageMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final mediaUploader = ref.watch(mediaUploaderProvider);
  final aiServiceClient = ref.watch(aiServiceClientProvider);
  return CreateImageMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    mediaUploader: mediaUploader,
    aiServiceClient: aiServiceClient,
  );
});

final createAudioMessageUseCaseProvider = Provider<CreateAudioMessageUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final threadRepository = ref.watch(threadRepositoryProvider);
  final mediaUploader = ref.watch(mediaUploaderProvider);
  final aiServiceClient = ref.watch(aiServiceClientProvider);
  return CreateAudioMessageUseCase(
    messageRepository: messageRepository,
    threadRepository: threadRepository,
    mediaUploader: mediaUploader,
    aiServiceClient: aiServiceClient,
  );
});

final deleteThreadUseCaseProvider = Provider<DeleteThreadUseCase>((ref) {
  final threadRepository = ref.watch(threadRepositoryProvider);
  return DeleteThreadUseCase(threadRepository: threadRepository);
});

final syncThreadMessagesUseCaseProvider = Provider<SyncThreadMessagesUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return SyncThreadMessagesUseCase(messageRepository: messageRepository);
});

final syncThreadsUseCaseProvider = Provider<SyncThreadsUseCase>((ref) {
  final threadRepository = ref.watch(threadRepositoryProvider);
  return SyncThreadsUseCase(threadRepository: threadRepository);
});

final retryMessagePipelineUseCaseProvider = Provider<RetryMessagePipelineUseCase>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final mediaUploader = ref.watch(mediaUploaderProvider);
  final aiServiceClient = ref.watch(aiServiceClientProvider);
  return RetryMessagePipelineUseCase(
    messageRepository: messageRepository,
    mediaUploader: mediaUploader,
    aiServiceClient: aiServiceClient,
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

// Controllers
final messageControllerProvider = StateNotifierProvider<MessageController, MessageState>((ref) {
  final createTextMessageUseCase = ref.watch(createTextMessageUseCaseProvider);
  final createImageMessageUseCase = ref.watch(createImageMessageUseCaseProvider);
  final createAudioMessageUseCase = ref.watch(createAudioMessageUseCaseProvider);
  final retryMessagePipelineUseCase = ref.watch(retryMessagePipelineUseCaseProvider);
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  final audioRecorderService = ref.watch(audioRecorderServiceProvider);

  return MessageController(
    createTextMessageUseCase: createTextMessageUseCase,
    createImageMessageUseCase: createImageMessageUseCase,
    createAudioMessageUseCase: createAudioMessageUseCase,
    retryMessagePipelineUseCase: retryMessagePipelineUseCase,
    imagePickerService: imagePickerService,
    audioRecorderService: audioRecorderService,
  );
});

final threadControllerProvider = StateNotifierProvider<ThreadController, ThreadState>((ref) {
  final deleteThreadUseCase = ref.watch(deleteThreadUseCaseProvider);
  return ThreadController(deleteThreadUseCase: deleteThreadUseCase);
});

final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>((ref) {
  final syncThreadMessagesUseCase = ref.watch(syncThreadMessagesUseCaseProvider);
  final syncThreadsUseCase = ref.watch(syncThreadsUseCaseProvider);
  return SyncController(
    syncThreadMessagesUseCase: syncThreadMessagesUseCase,
    syncThreadsUseCase: syncThreadsUseCase,
  );
});
