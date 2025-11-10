import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/utils/message_status_display.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Displays a single message in a chat bubble
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.isUserMessage,
    super.key,
  });

  final JournalMessageEntity message;
  final bool isUserMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = timeago.format(message.createdAt, locale: 'en_short');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            _buildAvatar(context, false),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isUserMessage
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUserMessage ? 16 : 4),
                      bottomRight: Radius.circular(isUserMessage ? 4 : 16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: _buildMessageContent(context),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment:
                        isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (message.status != MessageStatus.remoteCreated) ...[
                        const SizedBox(height: 2),
                        _buildStatusIndicator(context, ref),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: AppSpacing.sm),
            _buildAvatar(context, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                isUserMessage ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(context),
            ),
            if (message.transcription != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message.transcription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );

      case MessageType.audio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  size: 20,
                  color: isUserMessage
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _formatDuration(message.audioDurationSeconds ?? 0),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUserMessage
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (message.transcription != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message.transcription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _buildImageWidget(BuildContext context) {
    final theme = Theme.of(context);

    // Show uploaded image if available
    if (message.storageUrl != null) {
      return Image.network(
        message.storageUrl!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder(theme);
        },
      );
    }

    // Show local thumbnail if available (during upload or failed)
    if (message.localThumbnailPath != null) {
      final thumbnailFile = File(message.localThumbnailPath!);
      if (thumbnailFile.existsSync()) {
        return Image.file(
          thumbnailFile,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(theme);
          },
        );
      }
    }

    // Show local file if no thumbnail
    if (message.localFilePath != null) {
      final localFile = File(message.localFilePath!);
      if (localFile.existsSync()) {
        return Image.file(
          localFile,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(theme);
          },
        );
      }
    }

    return _buildImagePlaceholder(theme);
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      width: 200,
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, WidgetRef ref) {
    if (message.status == MessageStatus.remoteCreated) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final statusText = MessageStatusDisplay.getStatusText(message);
    final errorText = MessageStatusDisplay.getErrorText(message);
    final isRetryable = MessageStatusDisplay.isRetryable(message);
    
    // Determine icon and color based on status
    late IconData icon;
    late Color color;
    bool showSpinner = false;

    if (message.status == MessageStatus.failed) {
      icon = Icons.error_outline;
      color = theme.colorScheme.error;
    } else {
      // In-progress states
      showSpinner = true;
      color = theme.colorScheme.primary;
      switch (message.status) {
        case MessageStatus.uploadingMedia:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        case MessageStatus.processingAi:
          icon = Icons.smart_toy;
        default:
          icon = Icons.sync;
      }
    }

    // Show upload progress if available
    if (message.status == MessageStatus.uploadingMedia && message.uploadProgress != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: message.uploadProgress,
              strokeWidth: 2,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(message.uploadProgress! * 100).toInt()}%',
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          )
        else
          Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          errorText ?? statusText,
          style: TextStyle(fontSize: 10, color: color),
        ),
        if (isRetryable) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ref.read(messageControllerProvider.notifier).retryMessage(message.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                MessageStatusDisplay.getRetryButtonText(message),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
