import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/journal/presentation/widgets/thread_list_tile.dart';

/// A dismissible thread item widget with delete functionality
class ThreadItem extends ConsumerWidget {
  const ThreadItem({
    required this.thread,
    required this.onTap,
    required this.onShowDeleteConfirmation,
    super.key,
  });

  final JournalThreadEntity thread;
  final VoidCallback onTap;
  final Future<bool> Function(BuildContext) onShowDeleteConfirmation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(thread.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return onShowDeleteConfirmation(context);
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
        onTap: onTap,
      ),
    );
  }
}
