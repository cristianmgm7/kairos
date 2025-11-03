import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/l10n/app_localizations.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/controllers/settings_controller.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';

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
                  _LanguageSelector(currentLanguage: settings.language),

                  const SizedBox(height: AppSpacing.xl),

                  // Theme Section
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ThemeSelector(currentThemeMode: settings.themeMode),
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

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector({required this.currentLanguage});

  final AppLanguage currentLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: Column(
        children: AppLanguage.values.map((language) {
          return RadioListTile<AppLanguage>(
            title: Text(
              language == AppLanguage.english ? l10n.english : l10n.spanish,
            ),
            value: language,
            groupValue: currentLanguage,
            onChanged: (AppLanguage? value) {
              if (value != null) {
                controller.updateLanguage(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.currentThemeMode});

  final AppThemeMode currentThemeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: Column(
        children: [
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeLight),
            value: AppThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeDark),
            value: AppThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeSystem),
            value: AppThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
