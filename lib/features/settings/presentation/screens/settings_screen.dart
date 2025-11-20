import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/components/settings_section.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/features/settings/presentation/widgets/settings_element.dart';
import 'package:kairos/features/user_profile/presentation/widgets/user_profile_card.dart';
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

                          return UserProfileCard(
                            name: name,
                            email: email,
                            avatarUrl: avatarUrl,
                            onTap: () {
                              // Navigate to profile edit screen (if exists)
                            },
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
                          SettingsSection(
                            title: 'App Settings',
                            children: [
                              SettingsElement(
                                icon: Icons.contrast,
                                title: l10n.theme,
                                subtitle: _getThemeDisplayName(settings.themeMode, l10n),
                                onTap: () {
                                  context.push(AppRoutes.themeSettings);
                                },
                              ),
                              SettingsElement(
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
                          SettingsSection(
                            title: 'Data & Privacy',
                            children: [
                              SettingsElement(
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
                          SettingsSection(
                            title: 'Notifications',
                            children: [
                              SettingsElement(
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
