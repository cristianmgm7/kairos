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
        final threadTitle =
            params.content.length > 50 ? '${params.content.substring(0, 50)}...' : params.content;

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
        updatedAt: now,
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
