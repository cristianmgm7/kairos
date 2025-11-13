import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/empty_state.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/presentation/controllers/sync_controller.dart';
import 'package:kairos/features/journal/presentation/controllers/thread_controller.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/thread_list_tile.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Thread List Screen - Shows all journal conversation threads
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ThreadListScreen extends ConsumerStatefulWidget {
  const ThreadListScreen({super.key});

  @override
  ConsumerState<ThreadListScreen> createState() => _ThreadListScreenState();
}

class _ThreadListScreenState extends ConsumerState<ThreadListScreen> {
  // For debounced auto-sync on connectivity changes
  Timer? _connectivitySyncTimer;
  bool _wasOffline = false;

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

  @override
  void dispose() {
    _connectivitySyncTimer?.cancel();
    super.dispose();
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

    // Listen for connectivity changes (auto-sync on reconnect)
    ref.listen<AsyncValue<bool>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((isOnline) {
          final user = ref.read(currentUserProvider);

          // Detect transition from offline to online
          if (_wasOffline && isOnline && user != null) {
            logger.i('🌐 Device reconnected - scheduling thread list sync');

            // Cancel any pending sync timer
            _connectivitySyncTimer?.cancel();

            // Debounce sync by 2 seconds after reconnection
            _connectivitySyncTimer = Timer(const Duration(seconds: 2), () {
              logger.i('🔄 Triggering auto-sync for thread list');
              ref.read(syncControllerProvider.notifier).syncThreads(user.id);
            });
          }

          // Update offline tracking state
          _wasOffline = !isOnline;
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
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return _buildThreadItem(context, ref, thread);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (Object error, StackTrace stack) => Center(
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
                          'Error loading threads',
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

  Widget _buildThreadItem(BuildContext context, WidgetRef ref, JournalThreadEntity thread) {
    return Dismissible(
      key: Key(thread.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        ref.read(threadControllerProvider.notifier).deleteThread(thread.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ThreadListTile(
        thread: thread,
        onTap: () => _openThread(context, thread.id),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Thread'),
            content: const Text(
              'Are you sure you want to delete this thread? '
              'This will also delete all messages and media files. '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
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
