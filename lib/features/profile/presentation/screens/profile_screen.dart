import 'package:blueprint_app/core/theme/app_spacing.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:blueprint_app/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile screen - displays user profile information.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Profile'),
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
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('No profile found'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    // Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Name
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Profile details
                    _ProfileDetailTile(
                      icon: Icons.calendar_today,
                      title: 'Date of Birth',
                      value: profile.dateOfBirth != null
                          ? '${profile.dateOfBirth!.month}/${profile.dateOfBirth!.day}/${profile.dateOfBirth!.year}'
                          : 'Not set',
                    ),
                    _ProfileDetailTile(
                      icon: Icons.public,
                      title: 'Country',
                      value: profile.country ?? 'Not set',
                    ),
                    _ProfileDetailTile(
                      icon: Icons.person_outline,
                      title: 'Gender',
                      value: profile.gender ?? 'Not set',
                    ),
                    _ProfileDetailTile(
                      icon: Icons.flag,
                      title: 'Main Goal',
                      value: profile.mainGoal ?? 'Not set',
                    ),
                    _ProfileDetailTile(
                      icon: Icons.star,
                      title: 'Experience Level',
                      value: profile.experienceLevel ?? 'Not set',
                    ),
                    if (profile.interests != null && profile.interests!.isNotEmpty)
                      _ProfileDetailTile(
                        icon: Icons.favorite,
                        title: 'Interests',
                        value: profile.interests!.join(', '),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Edit button placeholder
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile - Coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
