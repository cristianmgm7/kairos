import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Settings screen - allows user to change language and theme.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsStreamProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final userAsync = ref.watch(authStateProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.home),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    'Profile and Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // Show options menu
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => ListTile(
                        leading: const Icon(Icons.logout),
                        title: Text(l10n.logout),
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                      ),
                    );
                  },
                  tooltip: 'More options',
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: settingsAsync.when(
            data: (settings) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: profileAsync.when(
                        data: (profile) {
                          final user = userAsync.valueOrNull;
                          final name = profile?.name ?? user?.displayName ?? 'User';
                          final email = user?.email ?? '';
                          final avatarUrl = profile?.avatarUrl ?? user?.photoUrl;

                          return InkWell(
                            onTap: () {
                              // Navigate to profile edit screen (if exists)
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    // Settings Sections
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),

                          // App Settings Section
                          _SettingsSection(
                            title: 'App Settings',
                            children: [
                              _SettingsTile(
                                icon: Icons.contrast,
                                title: l10n.theme,
                                subtitle: _getThemeDisplayName(settings.themeMode, l10n),
                                onTap: () {
                                  context.push(AppRoutes.themeSettings);
                                },
                              ),
                              _SettingsTile(
                                icon: Icons.language,
                                title: l10n.language,
                                subtitle: settings.language.getName(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                onTap: () {
                                  context.push(AppRoutes.languageSettings);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Data & Privacy Section
                          _SettingsSection(
                            title: 'Data & Privacy',
                            children: [
                              _SettingsTile(
                                icon: Icons.privacy_tip,
                                title: 'Manage Your Data',
                                onTap: () {
                                  context.push(AppRoutes.manageData);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Notifications Section
                          _SettingsSection(
                            title: 'Notifications',
                            children: [
                              _SettingsTile(
                                icon: Icons.notifications,
                                title: 'Push Notifications',
                                onTap: () {
                                  context.push(AppRoutes.pushNotifications);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
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

  String _getThemeDisplayName(AppThemeMode themeMode, AppLocalizations l10n) {
    switch (themeMode) {
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
      case AppThemeMode.system:
        return l10n.themeSystem;
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 0,
            top: 0,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: _buildChildrenWithDividers(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56, // Icon width + padding
          ),
        );
      }
    }
    return result;
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
