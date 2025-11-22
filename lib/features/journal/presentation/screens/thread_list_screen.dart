import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/sync/sync_controller.dart';
import 'package:kairos/core/sync/sync_coordinator.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/app_dialog.dart';
import 'package:kairos/core/widgets/app_error_view.dart';
import 'package:kairos/core/widgets/empty_state.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/presentation/components/thread_item.dart';
import 'package:kairos/features/journal/presentation/controllers/thread_controller.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Thread List Screen - Shows all journal conversation threads
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ThreadListScreen extends ConsumerStatefulWidget {
  const ThreadListScreen({super.key});

  @override
  ConsumerState<ThreadListScreen> createState() => _ThreadListScreenState();
}

class _ThreadListScreenState extends ConsumerState<ThreadListScreen> {
  @override
  void initState() {
    super.initState();

    // Trigger initial sync on screen entry
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      Future.microtask(
        () => ref.read(syncControllerProvider.notifier).syncThreads(currentUser.id),
      );
    }
  }

  Future<void> _handleRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    logger.i('🔄 Manual refresh triggered for thread list');

    await ref.read(syncControllerProvider.notifier).syncThreads(currentUser.id);

    // Show feedback based on sync state
    if (mounted) {
      final syncState = ref.read(syncControllerProvider);
      if (syncState is ThreadListSyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${syncState.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (syncState is ThreadListSyncSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threads synced successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final threadsAsync = currentUser != null
        ? ref.watch(threadsStreamProvider(currentUser.id))
        : const AsyncValue<List<JournalThreadEntity>>.data([]);

    // Listen for auto-sync trigger
    ref.listen<AsyncValue<void>>(
      syncTriggerProvider,
      (previous, next) {
        next.whenData((_) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            logger.i('🔄 Auto-sync triggered (Coordinator) - syncing threads');
            ref.read(syncControllerProvider.notifier).syncThreads(user.id);
          }
        });
      },
    );

    // Listen to sync controller state for background feedback
    ref.listen<SyncState>(syncControllerProvider, (previous, next) {
      if (next is ThreadListSyncError && mounted) {
        logger.i('❌ Background thread sync failed: ${next.message}');
        // Optionally show a subtle notification
      } else if (next is ThreadListSyncSuccess) {
        logger.i('✅ Background thread sync completed successfully');
      }
    });

    // Listen for delete state changes
    ref.listen<ThreadState>(threadControllerProvider, (previous, next) {
      if (next is ThreadDeleteError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(threadControllerProvider.notifier).reset();
      } else if (next is ThreadDeleteSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread deleted successfully')),
        );
        ref.read(threadControllerProvider.notifier).reset();
      }
    });

    return Column(
      children: [
        AppBar(
          title: Text(l10n.journal),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search coming soon')),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              threadsAsync.when<Widget>(
                data: (List<JournalThreadEntity> threads) {
                  if (threads.isEmpty) {
                    return EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No journal threads yet',
                      message: 'Start a conversation by tapping the + button',
                      action: ElevatedButton.icon(
                        onPressed: () => _createNewThread(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Start Writing'),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: 80, // Space for FAB
                      ),
                      itemCount: threads.length,
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1);
                      },
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return ThreadItem(
                          thread: thread,
                          onTap: () => _openThread(context, thread.id),
                          onShowDeleteConfirmation: _showDeleteConfirmationDialog,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (Object error, StackTrace stack) => AppErrorView.fromError(
                  error: error,
                  title: 'Error loading threads',
                  onRetry: () {
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser != null) {
                      ref.read(syncControllerProvider.notifier).syncThreads(currentUser.id);
                    }
                  },
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _createNewThread(context),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return await showAppConfirmationDialog(
          context: context,
          title: l10n.deleteThreadTitle,
          content: l10n.deleteThreadContent,
          confirmText: l10n.delete,
          isDestructive: true,
        ) ??
        false;
  }

  void _createNewThread(BuildContext context) {
    // Navigate to thread detail with no threadId (creates new thread)
    context.push('/journal/thread');
  }

  void _openThread(BuildContext context, String threadId) {
    context.push('/journal/thread/$threadId');
  }
}
