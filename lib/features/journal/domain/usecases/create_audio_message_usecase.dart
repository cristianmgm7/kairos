import 'dart:io';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:uuid/uuid.dart';

class CreateAudioMessageParams {
  const CreateAudioMessageParams({
    required this.userId,
    required this.audioFile,
    required this.durationSeconds,
    this.threadId,
  });

  final String userId;
  final File audioFile;
  final int durationSeconds;
  final String? threadId;
}

class CreateAudioMessageUseCase {
  CreateAudioMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;

  Future<Result<JournalMessageEntity>> call(
    CreateAudioMessageParams params,
  ) async {
    if (!params.audioFile.existsSync()) {
      return const Error(
        ValidationFailure(message: 'Audio file does not exist'),
      );
    }

    try {
      String threadId;
      if (params.threadId != null) {
        threadId = params.threadId!;
      } else {
        final now = DateTime.now().toUtc();
        final newThread = JournalThreadEntity(
          id: const Uuid().v4(),
          userId: params.userId,
          title: 'Audio Recording (${params.durationSeconds}s)',
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
        messageType: MessageType.audio,
        localFilePath: params.audioFile.path,
        audioDurationSeconds: params.durationSeconds,
        createdAt: now,
        updatedAt: now,
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
      return Error(
        UnknownFailure(message: 'Failed to create audio message: $e'),
      );
    }
  }
}
