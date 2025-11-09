import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/insights/presentation/providers/insight_providers.dart';
import 'package:kairos/features/insights/presentation/widgets/emotion_distribution_widget.dart';
import 'package:kairos/features/insights/presentation/widgets/mood_chart_widget.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Home screen - displays welcome message and user profile info.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final insightsAsync = ref.watch(currentUserGlobalInsightsProvider);

    return Column(
      children: [
        AppBar(
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
        Expanded(
          child: profileAsync.when(
            data: (profile) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile?.avatarUrl != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(profile!.avatarUrl!),
                          )
                        else if (user?.photoUrl != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(user!.photoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 40),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back, ${profile?.name ?? user?.displayName ?? 'User'}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your journaling companion',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Insights dashboard
                  insightsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Failed to load insights: $error'),
                      ),
                    ),
                    data: (insights) {
                      if (insights.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.insights_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No insights yet',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start journaling to see your mood patterns',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          MoodChartWidget(insights: insights),
                          const Divider(),
                          EmotionDistributionWidget(insights: insights),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}
