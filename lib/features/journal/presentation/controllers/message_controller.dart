import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
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
  }) : super(MessageInitial());

  final CreateTextMessageUseCase createTextMessageUseCase;
  final CreateImageMessageUseCase createImageMessageUseCase;
  final CreateAudioMessageUseCase createAudioMessageUseCase;

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
      },
      error: (Failure failure) {
        state = MessageError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error: ${failure.message}',
      _ => 'An error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = MessageInitial();
  }
}
