import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/entities/journal_message_entity.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/domain/value_objects/value_objects.dart';
import 'package:kairos/features/journal/presentation/controllers/message_controller.dart';
import 'package:kairos/core/sync/sync_controller.dart';
import 'package:kairos/core/sync/sync_coordinator.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/ai_typing_indicator.dart';
import 'package:kairos/features/journal/presentation/widgets/message_bubble.dart';
import 'package:kairos/features/journal/presentation/widgets/message_input.dart';

/// Thread Detail Screen - Displays a chat-like conversation thread
class ThreadDetailScreen extends ConsumerStatefulWidget {
  const ThreadDetailScreen({
    super.key,
    this.threadId,
  });

  final String? threadId;

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentThreadId;

  @override
  void initState() {
    super.initState();
    _currentThreadId = widget.threadId;

    // Trigger initial sync on screen entry if we have a threadId
    if (_currentThreadId != null) {
      Future.microtask(
        () => ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!),
      );
    }
  }

  bool get hasAiPending {
    final messagesAsync = _currentThreadId != null
        ? ref.watch(messagesStreamProvider(_currentThreadId!))
        : const AsyncValue<List<JournalMessageEntity>>.data([]);

    return messagesAsync.maybeWhen(
      data: (messages) {
        // Check if last message is from user and AI response is pending
        if (messages.isEmpty) return false;
        final lastMessage = messages.last;
        // Show "AI thinking" if last message is from user and not failed
        // (AI response will arrive as a separate message)
        return lastMessage.role == MessageRole.user && lastMessage.status != MessageStatus.failed;
      },
      orElse: () => false,
    );
  }

  Future<void> _handleRefresh() async {
    if (_currentThreadId == null) return;

    logger.i('🔄 Manual refresh triggered for thread: $_currentThreadId');

    await ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);

    // Show feedback based on sync state
    if (mounted) {
      final syncState = ref.read(syncControllerProvider);
      if (syncState is SyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${syncState.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (syncState is SyncSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Messages synced successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auto-sync trigger
    ref
      ..listen<AsyncValue<void>>(
        syncTriggerProvider,
        (previous, next) {
          next.whenData((_) {
            if (_currentThreadId != null) {
              logger.i('🔄 Auto-sync triggered (Coordinator) - syncing thread: $_currentThreadId');
              ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);
            }
          });
        },
      )

      // Listen to sync controller state (optional - for UI feedback)
      ..listen<SyncState>(syncControllerProvider, (previous, next) {
        if (next is SyncError && mounted) {
          logger.i('❌ Background sync failed: ${next.message}');
          // Optionally show a subtle notification
        } else if (next is SyncSuccess) {
          logger.i('✅ Background sync completed successfully');
        }
      });

    final messagesAsync = _currentThreadId != null
        ? ref.watch(messagesStreamProvider(_currentThreadId!))
        : const AsyncValue<List<JournalMessageEntity>>.data([]);

    final threadAsync = _currentThreadId != null
        ? ref.watch(threadRepositoryProvider).getThreadById(_currentThreadId!)
        : null;

    // Listen to message controller state
    ref.listen<MessageState>(messageControllerProvider, (previous, next) {
      if (next is MessageSuccess) {
        // Clear input and scroll to bottom
        _messageController.clear();
        _scrollToBottom();

        // Reset controller state
        ref.read(messageControllerProvider.notifier).reset();

        // If this was a new thread, get thread ID from the messages stream
        if (_currentThreadId == null) {
          // Wait a frame for the stream to update, then grab the thread ID
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userId = ref.read(currentUserProvider)?.id;
            if (userId != null) {
              ref.read(threadsStreamProvider(userId)).whenData((threads) {
                if (threads.isNotEmpty && _currentThreadId == null) {
                  setState(() {
                    _currentThreadId = threads.first.id;
                  });
                }
              });
            }
          });
        }
      } else if (next is MessageError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(messageControllerProvider.notifier).reset();
      }
    });

    // Listen for message processing failures
    if (_currentThreadId != null) {
      ref.listen<AsyncValue<List<JournalMessageEntity>>>(
        messagesStreamProvider(_currentThreadId!),
        (previous, next) {
          next.whenData((messages) {
            // Check if any message just failed
            final previousMessages = previous?.valueOrNull ?? [];
            for (final message in messages) {
              if (message.role == MessageRole.user && message.status == MessageStatus.failed) {
                // Check if this is a new failure
                final previousMessage = previousMessages.firstWhere(
                  (m) => m.id == message.id,
                  orElse: () => message,
                );

                if (previousMessage.status != MessageStatus.failed) {
                  // Show error snackbar with specific error message
                  final errorMessage = message.uploadError ??
                      message.aiError ??
                      'Message processing failed. Please try again.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          ref.read(messageControllerProvider.notifier).retryMessage(message.id);
                        },
                      ),
                    ),
                  );
                }
              }
            }
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: FutureBuilder<Result<JournalThreadEntity?>>(
          future: threadAsync,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final result = snapshot.data!;
              final thread = result.dataOrNull;
              if (thread != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title ?? 'New Thread',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${thread.messageCount} ${thread.messageCount == 1 ? 'message' : 'messages'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              }
            }
            return const Text('New Thread');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show thread options menu
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thread options coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.pagePadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withAlpha(128),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Start a conversation',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Type your first message below to begin',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Scroll to bottom when messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: messages.length + (hasAiPending ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator at the end if AI is processing
                      if (index == messages.length) {
                        return const AiTypingIndicator();
                      }

                      final message = messages[index];
                      final isUserMessage = message.role == MessageRole.user;

                      return MessageBubble(
                        message: message,
                        isUserMessage: isUserMessage,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Error loading messages',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSendMessage: _handleSendMessage,
            threadId: _currentThreadId,
          ),
        ],
      ),
    );
  }

  void _handleSendMessage(String content) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send messages')),
      );
      return;
    }

    if (content.trim().isEmpty) {
      return;
    }

    ref.read(messageControllerProvider.notifier).createTextMessage(
          userId: currentUser.id,
          content: content.trim(),
          threadId: _currentThreadId,
        );
  }
}
