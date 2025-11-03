import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/journal/presentation/controllers/journal_controller.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';

class CreateTextEntryScreen extends ConsumerStatefulWidget {
  const CreateTextEntryScreen({super.key});

  @override
  ConsumerState<CreateTextEntryScreen> createState() =>
      _CreateTextEntryScreenState();
}

class _CreateTextEntryScreenState extends ConsumerState<CreateTextEntryScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    final controller = ref.read(journalControllerProvider.notifier);
    await controller.createTextEntry(_textController.text);

    final state = ref.read(journalControllerProvider);
    if (state is JournalSuccess && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalControllerProvider);
    final isLoading = state is JournalLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Text Entry'),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _onSave,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Write your thoughts...',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
