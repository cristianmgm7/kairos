import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/services/audio_recorder_service.dart';
import 'package:kairos/core/services/image_picker_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
import 'package:kairos/features/journal/domain/usecases/create_audio_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_image_message_usecase.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_message_usecase.dart';

sealed class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageSuccess extends MessageState {
  MessageSuccess(this.message);
  final JournalMessageEntity message;
}

class MessageError extends MessageState {
  MessageError(this.message);
  final String message;
}

class MessageController extends StateNotifier<MessageState> {
  MessageController({
    required this.createTextMessageUseCase,
    required this.createImageMessageUseCase,
    required this.createAudioMessageUseCase,
    required this.uploadService,
    required this.imagePickerService,
    required this.audioRecorderService,
  }) : super(MessageInitial());

  final CreateTextMessageUseCase createTextMessageUseCase;
  final CreateImageMessageUseCase createImageMessageUseCase;
  final CreateAudioMessageUseCase createAudioMessageUseCase;
  final JournalUploadService uploadService;
  final ImagePickerService imagePickerService;
  final AudioRecorderService audioRecorderService;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<void> createTextMessage({
    required String userId,
    required String content,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateTextMessageParams(
      userId: userId,
      content: content,
      threadId: threadId,
    );

    final result = await createTextMessageUseCase.call(params);

    result.when<void>(
      success: (JournalMessageEntity message) {
        state = MessageSuccess(message);
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  Future<void> createImageMessage({
    required String userId,
    required File imageFile,
    required String thumbnailPath,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateImageMessageParams(
      userId: userId,
      imageFile: imageFile,
      thumbnailPath: thumbnailPath,
      threadId: threadId,
    );

    final result = await createImageMessageUseCase.call(params);

    result.when<void>(
      success: (JournalMessageEntity message) {
        state = MessageSuccess(message);

        // Trigger background upload
        logger.i('🎬 Triggering background upload for: ${message.id}');
        uploadService.uploadImageMessage(message).then((uploadResult) {
          uploadResult.when(
            success: (_) {
              logger.i('✅ Image upload completed successfully for: ${message.id}');
            },
            error: (failure) {
              logger.i('❌ Upload failed: ${failure.message}');
              // Message saved locally, will retry later
            },
          );
        }).catchError((Object error) {
          logger.i('❌ Unexpected error in upload: $error');
        });
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  Future<void> createAudioMessage({
    required String userId,
    required File audioFile,
    required int durationSeconds,
    String? threadId,
  }) async {
    state = MessageLoading();

    final params = CreateAudioMessageParams(
      userId: userId,
      audioFile: audioFile,
      durationSeconds: durationSeconds,
      threadId: threadId,
    );

    final result = await createAudioMessageUseCase.call(params);

    result.when<void>(
      success: (JournalMessageEntity message) {
        state = MessageSuccess(message);

        // Trigger background upload
        uploadService.uploadAudioMessage(message).then((uploadResult) {
          if (uploadResult.isError) {
            logger.i(
              'Upload failed: ${uploadResult.failureOrNull?.message}',
            );
          }
        });
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error. Please check your connection.',
      StorageFailure() => 'Storage error: ${failure.message}',
      PermissionFailure() => 'Permission denied. Please enable access in Settings.',
      UserCancelledFailure() => failure.message,
      CacheFailure() => 'Local storage error: ${failure.message}',
      ServerFailure() => 'Server error: ${failure.message}',
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    final result = await imagePickerService.pickImageFromGallery();

    result.when(
      success: (file) {
        _selectedImage = file;
        state = MessageInitial(); // Reset any errors
      },
      error: (failure) {
        if (failure is UserCancelledFailure) {
          // User cancelled - silent return
          return;
        }
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    final result = await imagePickerService.pickImageFromCamera();

    result.when(
      success: (file) {
        _selectedImage = file;
        state = MessageInitial();
      },
      error: (failure) {
        if (failure is UserCancelledFailure) {
          return;
        }
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  /// Clear selected image
  void clearSelectedImage() {
    _selectedImage = null;
    state = MessageInitial();
  }

  /// Start audio recording
  Future<void> startRecording() async {
    final result = await audioRecorderService.startRecording();

    result.when(
      success: (_) {
        _isRecording = true;
        state = MessageInitial();
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  /// Stop recording and create audio message
  Future<void> stopRecording({
    required String userId,
    String? threadId,
  }) async {
    final result = await audioRecorderService.stopRecording();

    await result.when(
      success: (recordingResult) async {
        _isRecording = false;

        // Create audio message
        await createAudioMessage(
          userId: userId,
          audioFile: recordingResult.file,
          durationSeconds: recordingResult.durationSeconds,
          threadId: threadId,
        );
      },
      error: (failure) {
        _isRecording = false;
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await audioRecorderService.cancelRecording();
    _isRecording = false;
    state = MessageInitial();
  }

  /// Get current recording duration
  int get recordingDuration => audioRecorderService.currentDurationSeconds;

  /// Manually retry a failed upload
  Future<void> retryUpload(JournalMessageEntity message) async {
    state = MessageLoading();

    final result = await uploadService.retryUpload(message);

    result.when<void>(
      success: (_) {
        state = MessageSuccess(message);
      },
      error: (failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  void reset() {
    state = MessageInitial();
  }
}
