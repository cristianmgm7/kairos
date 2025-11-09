import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart' as functions;
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';

/// Service for uploading journal message media files to Firebase Storage
class JournalUploadService {
  JournalUploadService({
    required this.storageService,
    required this.messageRepository,
  });

  final FirebaseStorageService storageService;
  final JournalMessageRepository messageRepository;

  /// Upload image message with thumbnail
  Future<Result<void>> uploadImageMessage(JournalMessageEntity message) async {
    debugPrint('🚀 uploadImageMessage called for: ${message.id}');
    try {
      // Validate local file exists
      if (message.localFilePath == null) {
        return const Error(
          ValidationFailure(message: 'No local file path for image'),
        );
      }

      final file = File(message.localFilePath!);
      if (!file.existsSync()) {
        await _updateUploadStatus(message, UploadStatus.failed);
        return const Error(
          ValidationFailure(message: 'Image file does not exist'),
        );
      }

      // Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // Upload thumbnail first if exists
      String? thumbnailUrl;
      if (message.localThumbnailPath != null) {
        final thumbnailFile = File(message.localThumbnailPath!);
        if (thumbnailFile.existsSync()) {
          final thumbPath = storageService.buildJournalPath(
            userId: message.userId,
            journalId: message.threadId,
            filename: '${message.id}_thumb.jpg',
          );

          final thumbResult = await storageService.uploadFile(
            file: thumbnailFile,
            storagePath: thumbPath,
            fileType: FileType.image,
            imageMaxSize: 150,
            imageQuality: 70,
            metadata: {
              'messageId': message.id,
              'threadId': message.threadId,
              'type': 'thumbnail',
            },
          );
          debugPrint('Thumbnail upload result: ${thumbResult.dataOrNull}');

          if (thumbResult.isError) {
            debugPrint(
              'Failed to upload thumbnail: ${thumbResult.failureOrNull?.message}',
            );
            // Continue with full image upload even if thumbnail fails
          } else {
            thumbnailUrl = thumbResult.dataOrNull;
          }
        }
      }

      // Upload full image
      final imagePath = storageService.buildJournalPath(
        userId: message.userId,
        journalId: message.threadId,
        filename: '${message.id}.jpg',
      );

      debugPrint('📤 Starting image upload for: ${message.id}');
      final uploadResult = await storageService.uploadFile(
        file: file,
        storagePath: imagePath,
        fileType: FileType.image,
        imageMaxSize: 2048,
        imageQuality: 85,
        metadata: {
          'messageId': message.id,
          'threadId': message.threadId,
          'type': 'image',
        },
        onProgress: (progress) {
          // Validate progress before converting to int
          if (progress.isFinite && progress >= 0 && progress <= 1) {
            debugPrint('Image upload progress: ${(progress * 100).toInt()}%');
          }
          // Could emit to stream for UI updates
        },
      );

      debugPrint('📦 Upload completed, processing result for: ${message.id}');
      debugPrint(
          '📦 Upload result type: ${uploadResult.isSuccess ? "SUCCESS" : "ERROR"}');

      return uploadResult.when(
        success: (downloadUrl) async {
          // Update message with URLs and completed status
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            thumbnailUrl: thumbnailUrl,
            uploadStatus: UploadStatus.completed,
          );

          debugPrint(
              'Calling updateMessage for: ${updatedMessage.id} with storageUrl: ${updatedMessage.storageUrl}');
          final updateResult =
              await messageRepository.updateMessage(updatedMessage);

          return updateResult.when(
            success: (_) {
              debugPrint(
                  'Successfully updated message in repository: ${updatedMessage.id}');
              return const Success(null);
            },
            error: (failure) {
              debugPrint('Failed to update message in repository: $failure');
              return Error(failure);
            },
          );
        },
        error: (failure) async {
          await _updateUploadStatus(message, UploadStatus.failed);
          return Error(failure);
        },
      );
    } catch (e) {
      await _updateUploadStatus(message, UploadStatus.failed);
      return Error(UnknownFailure(message: 'Image upload failed: $e'));
    }
  }

  /// Upload audio message
  Future<Result<void>> uploadAudioMessage(JournalMessageEntity message) async {
    try {
      // Validate local file exists
      if (message.localFilePath == null) {
        return const Error(
          ValidationFailure(message: 'No local file path for audio'),
        );
      }

      final file = File(message.localFilePath!);
      if (!file.existsSync()) {
        await _updateUploadStatus(message, UploadStatus.failed);
        return const Error(
          ValidationFailure(message: 'Audio file does not exist'),
        );
      }

      // Update status to uploading
      await _updateUploadStatus(message, UploadStatus.uploading);

      // Upload audio file
      final audioPath = storageService.buildJournalPath(
        userId: message.userId,
        journalId: message.threadId,
        filename: '${message.id}.m4a',
      );

      final uploadResult = await storageService.uploadFile(
        file: file,
        storagePath: audioPath,
        fileType: FileType.audio,
        metadata: {
          'messageId': message.id,
          'threadId': message.threadId,
          'type': 'audio',
          'durationSeconds': message.audioDurationSeconds?.toString() ?? '0',
        },
        onProgress: (progress) {
          // Validate progress before converting to int
          if (progress.isFinite && progress >= 0 && progress <= 1) {
            debugPrint('Audio upload progress: ${(progress * 100).toInt()}%');
          }
        },
      );

      return uploadResult.when(
        success: (downloadUrl) async {
          // Update message with URL and completed status
          final updatedMessage = message.copyWith(
            storageUrl: downloadUrl,
            uploadStatus: UploadStatus.completed,
          );

          debugPrint(
              'Calling updateMessage for audio: ${updatedMessage.id} with storageUrl: ${updatedMessage.storageUrl}');
          final updateResult =
              await messageRepository.updateMessage(updatedMessage);

          return updateResult.when(
            success: (_) {
              debugPrint(
                  'Successfully updated audio message in repository: ${updatedMessage.id}');

              // Trigger transcription in background (don't await)
              // The Cloud Function will handle this automatically via Firestore trigger
              // But we can also call it explicitly for faster processing
              unawaited(
                transcribeAudio(updatedMessage)
                    .then<void>((transcriptionResult) {
                  if (transcriptionResult.isError) {
                    debugPrint(
                        'Manual transcription failed, will be handled by trigger: ${transcriptionResult.failureOrNull?.message}');
                  }
                }),
              );

              return const Success(null);
            },
            error: (failure) {
              debugPrint(
                  'Failed to update audio message in repository: $failure');
              return Error(failure);
            },
          );
        },
        error: (failure) async {
          await _updateUploadStatus(message, UploadStatus.failed);
          return Error(failure);
        },
      );
    } catch (e) {
      await _updateUploadStatus(message, UploadStatus.failed);
      return Error(UnknownFailure(message: 'Audio upload failed: $e'));
    }
  }

  /// Transcribe audio message after upload
  Future<Result<void>> transcribeAudio(JournalMessageEntity message) async {
    try {
      if (message.messageType != MessageType.audio) {
        return const Error(
            ValidationFailure(message: 'Message is not audio type'));
      }

      if (message.storageUrl == null) {
        return const Error(
            ValidationFailure(message: 'Audio not uploaded yet'));
      }

      // Call Cloud Function to transcribe
      final callable =
          functions.FirebaseFunctions.instance.httpsCallable('transcribeAudio');
      final result = await callable.call<Map<String, dynamic>>({
        'audioUrl': message.storageUrl,
        'messageId': message.id,
      });

      debugPrint('Transcription result: ${result.data}');
      return const Success(null);
    } catch (e) {
      if (e is functions.FirebaseFunctionsException) {
        debugPrint(
            'Transcription error (${e.code}): ${e.message} ${e.details ?? ''}');
        return Error(
            ServerFailure(message: 'Transcription failed: ${e.message}'));
      }
      debugPrint('Transcription error: $e');
      return Error(ServerFailure(message: 'Transcription failed: $e'));
    }
  }

  /// Process pending uploads for a user
  /// Returns count of successfully uploaded messages
  Future<Result<int>> processPendingUploads(String userId) async {
    try {
      final pendingResult = await messageRepository.getPendingUploads(userId);

      if (pendingResult.isError) {
        return Error(pendingResult.failureOrNull!);
      }

      final pendingMessages = pendingResult.dataOrNull!;
      var successCount = 0;

      for (final message in pendingMessages) {
        // Skip if retry count too high (max 5 attempts)
        if (message.uploadRetryCount >= 5) {
          debugPrint('Max retry count reached for message ${message.id}');
          continue;
        }

        // Exponential backoff: wait 2^retryCount seconds
        if (message.lastUploadAttemptAt != null) {
          final timeSinceLastAttempt =
              DateTime.now().difference(message.lastUploadAttemptAt!).inSeconds;
          final backoffSeconds =
              2 << message.uploadRetryCount; // 2, 4, 8, 16, 32

          if (timeSinceLastAttempt < backoffSeconds) {
            debugPrint('Backoff period not elapsed for message ${message.id}');
            continue;
          }
        }

        // Upload based on message type
        Result<void> uploadResult;
        if (message.messageType == MessageType.image) {
          uploadResult = await uploadImageMessage(message);
        } else if (message.messageType == MessageType.audio) {
          uploadResult = await uploadAudioMessage(message);
        } else {
          continue; // Text messages don't need upload
        }

        if (uploadResult.isSuccess) {
          successCount++;
        }
      }

      return Success(successCount);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to process uploads: $e'));
    }
  }

  /// Retry a specific failed upload manually
  Future<Result<void>> retryUpload(JournalMessageEntity message) async {
    if (message.messageType == MessageType.image) {
      return uploadImageMessage(message);
    } else if (message.messageType == MessageType.audio) {
      return uploadAudioMessage(message);
    } else {
      return const Error(
        ValidationFailure(message: 'Cannot retry text message upload'),
      );
    }
  }

  /// Helper to update upload status and retry count
  Future<void> _updateUploadStatus(
    JournalMessageEntity message,
    UploadStatus status,
  ) async {
    final updatedMessage = message.copyWith(
      uploadStatus: status,
      uploadRetryCount: status == UploadStatus.failed
          ? message.uploadRetryCount + 1
          : message.uploadRetryCount,
      lastUploadAttemptAt: DateTime.now().toUtc(),
    );

    await messageRepository.updateMessage(updatedMessage);
  }
}
