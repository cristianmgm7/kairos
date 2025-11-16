import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:kairos/features/journal/domain/value_objects/value_objects.dart';
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

/// Use case for creating text messages with full pipeline orchestration
///
/// Pipeline steps:
/// 1. Create message locally (status: localCreated)
/// 2. Create remote message (status: remoteCreated)
/// 3. Request AI response (status: processingAi)
///
/// Status updates are written to local DB, which automatically updates UI via repository stream.
class CreateTextMessageUseCase {
  CreateTextMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.aiServiceClient,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final AiServiceClient aiServiceClient;

  final _uuid = const Uuid();

  /// Execute use case
  ///
  /// Creates message and orchestrates pipeline. Status updates are written to local DB,
  /// which triggers the repository stream to update the UI automatically.
  ///
  /// Returns success once pipeline is initiated (AI response will arrive via repository stream).
  Future<Result<void>> call(CreateTextMessageParams params) async {
    try {
      // Validate content
      if (params.content.trim().isEmpty) {
        return const Error(ValidationFailure(message: 'Message content cannot be empty'));
      }

      // Determine thread ID (create thread if needed)
      final threadId = params.threadId ?? _uuid.v4();

      if (params.threadId == null) {
        // Create new thread
        final threadTitle =
            params.content.length > 50 ? '${params.content.substring(0, 50)}...' : params.content;

        final thread = JournalThreadEntity(
          id: threadId,
          userId: params.userId,
          title: threadTitle,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastMessageAt: DateTime.now().toUtc(),
        );

        final threadResult = await threadRepository.createThread(thread);
        if (threadResult.isError) {
          return Error(threadResult.failureOrNull!);
        }
      }

      // STEP 1: Create message locally
      final messageId = _uuid.v4();
      final clientLocalId = _uuid.v4(); // For idempotency

      var message = JournalMessageEntity(
        id: messageId,
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.text,
        content: params.content,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        clientLocalId: clientLocalId,
      );

      logger.i('Creating text message locally: $messageId');

      final createResult = await messageRepository.createMessage(message);
      if (createResult.isError) {
        return Error(createResult.failureOrNull!);
      }

      // UI updates automatically via repository stream

      // STEP 2: Create remote message
      message = message.copyWith(status: MessageStatus.remoteCreated);

      logger.i('Updating message to remoteCreated: $messageId');

      final remoteResult = await messageRepository.updateMessage(message);
      if (remoteResult.isError) {
        // Mark as failed (repository stream will show error in UI)
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.remoteCreationFailed,
          aiError: 'Failed to sync message to server',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        return Error(remoteResult.failureOrNull!);
      }

      // STEP 3: Request AI response
      message = message.copyWith(status: MessageStatus.processingAi);

      logger.i('Requesting AI response for message: $messageId');

      await messageRepository.updateMessage(message);

      final aiResult = await aiServiceClient.generateAiResponse(messageId: messageId);

      if (aiResult.isError) {
        // Mark as failed (repository stream will show error in UI)
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: aiResult.failureOrNull?.message ?? 'AI response failed',
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        return Error(aiResult.failureOrNull!);
      }

      // Success! AI response will be created by backend and appear via repository stream
      logger.i('Text message pipeline complete: $messageId');

      // Update thread metadata
      await _updateThreadMetadata(threadId);

      return const Success(null);
    } catch (e) {
      logger.i('Unexpected error in CreateTextMessageUseCase: $e');
      return Error(UnknownFailure(message: 'Failed to create text message: $e'));
    }
  }

  Future<void> _updateThreadMetadata(String threadId) async {
    final threadResult = await threadRepository.getThreadById(threadId);
    if (threadResult.isSuccess) {
      final thread = threadResult.dataOrNull!;
      final updatedThread = thread.copyWith(
        lastMessageAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        messageCount: thread.messageCount + 1,
      );
      await threadRepository.updateThread(updatedThread);
    }
  }
}
