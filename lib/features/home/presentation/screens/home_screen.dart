import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/home/presentation/components/insights_section.dart';
import 'package:kairos/features/home/presentation/components/streak_section.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Home screen - displays welcome message and user profile info.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            StreakSection(),
            InsightsSection(),
          ],
        ),
      ),
    );
  }
}
