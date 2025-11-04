import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CreateImageMessageParams {
  const CreateImageMessageParams({
    required this.userId,
    required this.imageFile,
    required this.thumbnailPath,
    this.threadId,
  });

  final String userId;
  final File imageFile;
  final String thumbnailPath;
  final String? threadId;
}

class CreateImageMessageUseCase {
  CreateImageMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.storageService,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final FirebaseStorageService storageService;

  Future<Result<JournalMessageEntity>> call(
    CreateImageMessageParams params,
  ) async {
    if (!params.imageFile.existsSync()) {
      return const Error(
        ValidationFailure(message: 'Image file does not exist'),
      );
    }

    try {
      // Generate thumbnail for instant preview
      String? localThumbnailPath;
      final thumbnailResult =
          await storageService.generateThumbnail(params.imageFile);

      if (thumbnailResult.isSuccess) {
        try {
          // Save thumbnail to temp file
          final tempDir = await getTemporaryDirectory();
          final thumbnailFile = File(
            '${tempDir.path}/${const Uuid().v4()}_thumb.jpg',
          );
          await thumbnailFile.writeAsBytes(thumbnailResult.dataOrNull!);
          localThumbnailPath = thumbnailFile.path;
        } catch (e) {
          debugPrint('Failed to save thumbnail: $e');
          // Continue without thumbnail
        }
      } else {
        debugPrint(
          'Thumbnail generation failed: ${thumbnailResult.failureOrNull?.message}',
        );
      }

      String threadId;
      if (params.threadId != null) {
        threadId = params.threadId!;
      } else {
        final now = DateTime.now().toUtc();
        final newThread = JournalThreadEntity(
          id: const Uuid().v4(),
          userId: params.userId,
          title: 'Image Journal',
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
        messageType: MessageType.image,
        localFilePath: params.imageFile.path,
        localThumbnailPath: localThumbnailPath,
        createdAt: now,
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
        UnknownFailure(message: 'Failed to create image message: $e'),
      );
    }
  }
}
