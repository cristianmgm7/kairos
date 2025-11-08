import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/empty_state.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/presentation/controllers/thread_controller.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/thread_list_tile.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Thread List Screen - Shows all journal conversation threads
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ThreadListScreen extends ConsumerWidget {
  const ThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final threadsAsync = currentUser != null
        ? ref.watch(threadsStreamProvider(currentUser.id))
        : const AsyncValue<List<JournalThreadEntity>>.data([]);

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
                    onRefresh: () async {
                      if (currentUser != null) {
                        final repo = ref.read(threadRepositoryProvider);
                        await repo.syncThreads(currentUser.id);
                      }
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: 80, // Space for FAB
                      ),
                      itemCount: threads.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
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

  Widget _buildThreadItem(
      BuildContext context, WidgetRef ref, JournalThreadEntity thread) {
    return Dismissible(
      key: Key(thread.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
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
