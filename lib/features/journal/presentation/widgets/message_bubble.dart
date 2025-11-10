import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
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
                      if (message.uploadStatus != UploadStatus.completed) ...[
                        const SizedBox(height: 2),
                        _buildUploadStatusIndicator(context, ref),
                      ] else if (message.role == MessageRole.user &&
                          message.aiProcessingStatus != AiProcessingStatus.completed) ...[
                        const SizedBox(height: 2),
                        _buildProcessingStatusIndicator(context),
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

  Widget _buildUploadStatusIndicator(BuildContext context, WidgetRef ref) {
    if (message.uploadStatus == UploadStatus.completed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String tooltip;
    var showRetry = false;

    switch (message.uploadStatus) {
      case UploadStatus.notStarted:
        icon = Icons.cloud_upload_outlined;
        color = theme.colorScheme.onSurfaceVariant;
        tooltip = 'Waiting to upload';
      case UploadStatus.uploading:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        tooltip = 'Uploading...';
      case UploadStatus.completed:
        return const SizedBox.shrink();
      case UploadStatus.failed:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        tooltip = 'Upload failed';
        showRetry = true;
      case UploadStatus.retrying:
        icon = Icons.refresh;
        color = Colors.orange;
        tooltip = 'Retrying upload...';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.uploadStatus == UploadStatus.uploading)
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
          tooltip,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
        if (showRetry) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ref.read(messageControllerProvider.notifier).retryUpload(message);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
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

  Widget _buildProcessingStatusIndicator(BuildContext context) {
    if (message.role != MessageRole.user) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    // Show AI processing status for user messages
    switch (message.aiProcessingStatus) {
      case AiProcessingStatus.pending:
      case AiProcessingStatus.processing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'AI is thinking...',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        );

      case AiProcessingStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 12, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(
              'AI response failed',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                try {
                  final callable = FirebaseFunctions.instance.httpsCallable('retryAiResponse');
                  await callable.call<Map<String, dynamic>>({'messageId': message.id});

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Retrying AI response...')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retry failed: $e')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );

      case AiProcessingStatus.completed:
        return const SizedBox.shrink();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
