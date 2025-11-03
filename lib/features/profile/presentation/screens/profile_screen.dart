import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Profile screen - displays user profile information.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Column(
      children: [
        AppBar(
          title: Text(l10n.profile),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
              tooltip: l10n.logout,
            ),
          ],
        ),
        Expanded(
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return Center(child: Text(l10n.noProfileFound));
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
                      title: l10n.dateOfBirth,
                      value: profile.dateOfBirth != null
                          ? '${profile.dateOfBirth!.month}/${profile.dateOfBirth!.day}/${profile.dateOfBirth!.year}'
                          : l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.public,
                      title: l10n.country,
                      value: profile.country ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.person_outline,
                      title: l10n.gender,
                      value: profile.gender ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.flag,
                      title: l10n.mainGoal,
                      value: profile.mainGoal ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.star,
                      title: l10n.experienceLevel,
                      value: profile.experienceLevel ?? l10n.notSet,
                    ),
                    if (profile.interests != null &&
                        profile.interests!.isNotEmpty)
                      _ProfileDetailTile(
                        icon: Icons.favorite,
                        title: l10n.interests,
                        value: profile.interests!.join(', '),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Edit button placeholder
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.editProfileComingSoon),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(l10n.editProfile),
                    ),
                  ],
                ),
              );
            },
            loading: () => Center(child: Text(l10n.loading)),
            error: (error, stack) => Center(
              child: Text('${l10n.error}: $error'),
            ),
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
