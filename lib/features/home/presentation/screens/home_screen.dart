import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:blueprint_app/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home screen - displays welcome message and user profile info.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Home'),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: profileAsync.when(
                data: (profile) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (profile?.avatarUrl != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(profile!.avatarUrl!),
                      )
                    else if (user?.photoUrl != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user!.photoUrl!),
                      )
                    else
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    if (profile?.name != null)
                      Text(
                        profile!.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 32),
                    Text(
                      'Your journaling journey starts here',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
