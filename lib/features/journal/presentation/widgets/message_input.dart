import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';

/// Input widget for composing and sending messages
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({
    required this.controller, required this.onSendMessage, super.key,
    this.threadId,
  });

  final TextEditingController controller;
  final void Function(String content) onSendMessage;
  final String? threadId;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (_hasText) {
      widget.onSendMessage(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAttachmentOptions(context, ref),
              tooltip: 'Add attachment',
            ),
            const SizedBox(width: AppSpacing.xs),
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 120,
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Send button
            IconButton(
              icon: Icon(
                _hasText ? Icons.send : Icons.mic,
                color: _hasText ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: _hasText ? _handleSend : () => _showRecordingDialog(context, ref),
              tooltip: _hasText ? 'Send' : 'Voice message',
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context, WidgetRef ref) {
    // Capture the parent context to use after closing the bottom sheet
    final rootContext = context;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo from gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final controller = ref.read(messageControllerProvider.notifier);
                  await controller.pickImageFromGallery();

                  // If image selected, show it in preview
                  if (controller.selectedImage != null) {
                    if (rootContext.mounted) {
                      _showImagePreview(rootContext, ref);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final controller = ref.read(messageControllerProvider.notifier);
                  await controller.pickImageFromCamera();

                  if (controller.selectedImage != null) {
                    if (rootContext.mounted) {
                      _showImagePreview(rootContext, ref);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRecordingDialog(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreview(BuildContext context, WidgetRef ref) {
    final controller = ref.read(messageControllerProvider.notifier);
    final image = controller.selectedImage;

    if (image == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              image,
              height: 300,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearSelectedImage();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Send image message
              final userId = ref.read(authStateProvider).valueOrNull?.id;
              if (userId != null) {
                await controller.createImageMessage(
                  userId: userId,
                  imageFile: image,
                  thumbnailPath: '', // Will be generated in use case
                  threadId: widget.threadId,
                );
                controller.clearSelectedImage();

                // Trigger onSendMessage callback to scroll to bottom
                widget.onSendMessage('');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showRecordingDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecordingDialog(
        threadId: widget.threadId,
        onSend: () => widget.onSendMessage(''),
      ),
    );
  }
}

class _RecordingDialog extends ConsumerStatefulWidget {
  const _RecordingDialog({
    required this.onSend, this.threadId,
  });

  final String? threadId;
  final VoidCallback onSend;

  @override
  ConsumerState<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends ConsumerState<_RecordingDialog> {
  Timer? _timer;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.startRecording();

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = controller.recordingDuration;
        });
      }
    });
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    final controller = ref.read(messageControllerProvider.notifier);
    await controller.stopRecording(
      userId: userId,
      threadId: widget.threadId,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onSend();
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    final controller = ref.read(messageControllerProvider.notifier);
    await controller.cancelRecording();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(messageControllerProvider.notifier);

    return AlertDialog(
      title: const Text('Recording'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.isRecording ? Icons.mic : Icons.mic_off,
            size: 64,
            color: controller.isRecording ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_duration),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            controller.isRecording ? 'Recording...' : 'Stopped',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        if (controller.isRecording)
          ElevatedButton.icon(
            onPressed: _stopAndSend,
            icon: const Icon(Icons.stop),
            label: const Text('Stop & Send'),
          ),
      ],
    );
  }
}
