import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Displays a single message in a chat bubble
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isUserMessage,
  });

  final JournalMessageEntity message;
  final bool isUserMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = timeago.format(message.createdAt, locale: 'en_short');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            _buildAvatar(context, false),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (message.uploadStatus != UploadStatus.completed) ...[
                        const SizedBox(width: 4),
                        _buildUploadStatusIcon(context),
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
        color: isUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
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
            color: isUserMessage
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.localFilePath != null ||
                message.storageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.storageUrl ?? '',
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                  '${message.audioDurationSeconds ?? 0}s',
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

  Widget _buildUploadStatusIcon(BuildContext context) {
    final theme = Theme.of(context);
    switch (message.uploadStatus) {
      case UploadStatus.uploading:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      case UploadStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 12,
          color: theme.colorScheme.error,
        );
      case UploadStatus.retrying:
        return Icon(
          Icons.refresh,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        );
      case UploadStatus.notStarted:
      case UploadStatus.completed:
        return const SizedBox.shrink();
    }
  }
}
