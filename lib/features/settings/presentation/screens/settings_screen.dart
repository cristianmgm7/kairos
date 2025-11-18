import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/settings/presentation/components/lenguage_selector.dart';
import 'package:kairos/features/settings/presentation/components/theme_selector.dart';
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

    return Column(
      children: [
        AppBar(
          title: Text(l10n.settings),
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
          child: settingsAsync.when(
            data: (settings) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Language Section
                  Text(
                    l10n.language,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LanguageSelector(currentLanguage: settings.language),

                  const SizedBox(height: AppSpacing.xl),

                  // Theme Section
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ThemeSelector(currentThemeMode: settings.themeMode),
                ],
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
