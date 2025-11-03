import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/thread_list_tile.dart';
import 'package:kairos/core/widgets/empty_state.dart';

/// Thread List Screen - Shows all journal conversation threads
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ThreadListScreen extends ConsumerWidget {
  const ThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final threadsAsync = currentUser != null
        ? ref.watch(threadsStreamProvider(currentUser.id))
        : const AsyncValue<List<JournalThreadEntity>>.data([]);

    return Column(
      children: [
        AppBar(
          title: const Text('Journal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search functionality
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
                        return ThreadListTile(
                          thread: thread,
                          onTap: () => _openThread(context, thread.id),
                        );
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

  void _createNewThread(BuildContext context) {
    // Navigate to thread detail with no threadId (creates new thread)
    context.push('/journal/thread');
  }

  void _openThread(BuildContext context, String threadId) {
    context.push('/journal/thread/$threadId');
  }
}
