import 'dart:io';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/services/media_uploader.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/services/ai_service_client.dart';
import 'package:uuid/uuid.dart';

class CreateImageMessageParams {
  const CreateImageMessageParams({
    required this.userId,
    required this.imageFile,
    this.threadId,
  });

  final String userId;
  final File imageFile;
  final String? threadId;
}

/// Use case for creating image messages with full pipeline orchestration
///
/// Pipeline steps:
/// 1. Create message locally (status: localCreated)
/// 2. Upload image file (status: uploadingMedia → mediaUploaded)
/// 3. Analyze image (status: processingAi)
/// 4. Update with description (status: processed)
/// 5. Create remote message (status: remoteCreated)
/// 6. Request AI response (status: processingAi)
class CreateImageMessageUseCase {
  CreateImageMessageUseCase({
    required this.messageRepository,
    required this.threadRepository,
    required this.mediaUploader,
    required this.aiServiceClient,
  });

  final JournalMessageRepository messageRepository;
  final JournalThreadRepository threadRepository;
  final MediaUploader mediaUploader;
  final AiServiceClient aiServiceClient;

  final _uuid = const Uuid();

  Stream<Result<JournalMessageEntity>> call(CreateImageMessageParams params) async* {
    try {
      // Validate image file
      if (!params.imageFile.existsSync()) {
        yield const Error(ValidationFailure(message: 'Image file does not exist'));
        return;
      }

      // Determine thread ID
      String threadId = params.threadId ?? _uuid.v4();

      if (params.threadId == null) {
        final thread = JournalThreadEntity(
          id: threadId,
          userId: params.userId,
          title: 'Image Journal',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastMessageAt: DateTime.now().toUtc(),
          messageCount: 0,
        );

        final threadResult = await threadRepository.createThread(thread);
        if (threadResult.isError) {
          yield Error(threadResult.failureOrNull!);
          return;
        }
      }

      // STEP 1: Create message locally
      final messageId = _uuid.v4();
      final clientLocalId = _uuid.v4();

      var message = JournalMessageEntity(
        id: messageId,
        threadId: threadId,
        userId: params.userId,
        role: MessageRole.user,
        messageType: MessageType.image,
        localFilePath: params.imageFile.path,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: MessageStatus.localCreated,
        clientLocalId: clientLocalId,
        attemptCount: 0,
      );

      logger.i('Creating image message locally: $messageId');

      final createResult = await messageRepository.createMessage(message);
      if (createResult.isError) {
        yield Error(createResult.failureOrNull!);
        return;
      }

      yield Success(message);

      // STEP 2: Upload image file
      message = message.copyWith(
        status: MessageStatus.uploadingMedia,
        uploadProgress: 0.0,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      final storagePath = 'users/${params.userId}/journals/$threadId/$messageId.jpg';

      logger.i('Uploading image file: $messageId');

      final uploadResult = await mediaUploader.uploadFile(
        file: params.imageFile,
        storagePath: storagePath,
        contentType: 'image/jpeg',
        metadata: {
          'messageId': messageId,
          'threadId': threadId,
          'type': 'image',
        },
        onProgress: (progress) async {
          // Update progress in entity
          message = message.copyWith(uploadProgress: progress);
          await messageRepository.updateMessage(message);
          // Note: Not yielding here to avoid too many emissions
        },
      );

      if (uploadResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.uploadFailed,
          uploadError: uploadResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(uploadResult.failureOrNull!);
        return;
      }

      final imageUrl = uploadResult.dataOrNull!.remoteUrl;

      message = message.copyWith(
        status: MessageStatus.mediaUploaded,
        storageUrl: imageUrl,
        uploadProgress: 1.0,
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 3: Analyze image
      message = message.copyWith(status: MessageStatus.processingAi);
      await messageRepository.updateMessage(message);
      yield Success(message);

      logger.i('Analyzing image: $messageId');

      final analysisResult = await aiServiceClient.analyzeImage(
        messageId: messageId,
        imageUrl: imageUrl,
      );

      if (analysisResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: analysisResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(analysisResult.failureOrNull!);
        return;
      }

      // STEP 4: Update with description
      final description = analysisResult.dataOrNull!.description;

      message = message.copyWith(
        status: MessageStatus.processed,
        content: description, // Use image description as content
      );
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 5: Create remote message
      message = message.copyWith(status: MessageStatus.remoteCreated);
      await messageRepository.updateMessage(message);
      yield Success(message);

      // STEP 6: Request AI response
      message = message.copyWith(status: MessageStatus.processingAi);
      await messageRepository.updateMessage(message);
      yield Success(message);

      logger.i('Requesting AI response for image message: $messageId');

      final aiResult = await aiServiceClient.generateAiResponse(messageId: messageId);

      if (aiResult.isError) {
        message = message.copyWith(
          status: MessageStatus.failed,
          failureReason: FailureReason.aiResponseFailed,
          aiError: aiResult.failureOrNull?.message,
          attemptCount: message.attemptCount + 1,
          lastAttemptAt: DateTime.now().toUtc(),
        );
        await messageRepository.updateMessage(message);

        yield Error(aiResult.failureOrNull!);
        return;
      }

      logger.i('Image message pipeline complete: $messageId');
      yield Success(message);

      await _updateThreadMetadata(threadId);
    } catch (e) {
      logger.i('Unexpected error in CreateImageMessageUseCase: $e');
      yield Error(UnknownFailure(message: 'Failed to create image message: $e'));
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
