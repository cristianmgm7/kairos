import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';

/// Helper for converting MessageStatus to user-friendly display text
class MessageStatusDisplay {
  /// Get display text for message status
  static String getStatusText(JournalMessageEntity message) {
    switch (message.status) {
      case MessageStatus.localCreated:
        return 'Sending...';

      case MessageStatus.uploadingMedia:
        final progress = message.uploadProgress ?? 0.0;
        final percentage = (progress * 100).toInt();
        final mediaType = message.messageType == MessageType.audio ? 'audio' : 'image';
        return 'Uploading $mediaType $percentage%';

      case MessageStatus.mediaUploaded:
        return 'Uploaded';

      case MessageStatus.processingAi:
        if (message.transcription == null && message.messageType == MessageType.audio) {
          return 'Transcribing audio...';
        } else if (message.content == null && message.messageType == MessageType.image) {
          return 'Analyzing image...';
        } else {
          return 'AI is thinking...';
        }

      case MessageStatus.processed:
        return 'Processed';

      case MessageStatus.remoteCreated:
        return 'Waiting for AI response...';

      case MessageStatus.failed:
        return 'Failed';
    }
  }

  /// Get error message for failed status
  static String? getErrorText(JournalMessageEntity message) {
    if (message.status != MessageStatus.failed) {
      return null;
    }

    switch (message.failureReason) {
      case FailureReason.uploadFailed:
        return message.uploadError ?? 'Upload failed. Please try again.';

      case FailureReason.transcriptionFailed:
      case FailureReason.aiResponseFailed:
        return message.aiError ?? 'AI processing failed. Please try again.';

      case FailureReason.remoteCreationFailed:
        return 'Failed to sync to server. Please check your connection.';

      case FailureReason.networkError:
        return 'Network error. Please check your internet connection.';

      case FailureReason.unknown:
      case null:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if message is retryable
  static bool isRetryable(JournalMessageEntity message) {
    return message.status == MessageStatus.failed && message.attemptCount < 5;
  }

  /// Get retry button text
  static String getRetryButtonText(JournalMessageEntity message) {
    if (message.attemptCount == 0) {
      return 'Retry';
    } else {
      return 'Retry (${message.attemptCount}/5)';
    }
  }

  /// Check if message is in a processing state (show spinner)
  static bool isProcessing(JournalMessageEntity message) {
    return message.status == MessageStatus.uploadingMedia ||
        message.status == MessageStatus.processingAi ||
        message.status == MessageStatus.localCreated;
  }

  /// Check if message should show status indicator
  static bool shouldShowStatus(JournalMessageEntity message) {
    // Only show status for user messages that aren't fully synced
    if (message.role != MessageRole.user) {
      return false;
    }

    return message.status != MessageStatus.remoteCreated ||
        message.status == MessageStatus.failed;
  }
}

