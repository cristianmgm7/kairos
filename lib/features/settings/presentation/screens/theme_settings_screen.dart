import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Theme settings screen - allows user to change theme mode.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.theme),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return RadioGroup(
            groupValue: settings.themeMode,
            onChanged: (value) {
              ref.read(settingsControllerProvider.notifier).updateThemeMode(value!);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                const SizedBox(height: AppSpacing.lg),
                _ThemeOptionTile(
                  title: l10n.themeLight,
                  value: AppThemeMode.light,
                  currentValue: settings.themeMode,
                ),
                const Divider(),
                _ThemeOptionTile(
                  title: l10n.themeDark,
                  value: AppThemeMode.dark,
                  currentValue: settings.themeMode,
                ),
                const Divider(),
                _ThemeOptionTile(
                  title: l10n.themeSystem,
                  value: AppThemeMode.system,
                  currentValue: settings.themeMode,
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
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.value,
    required this.currentValue,
  });

  final String title;
  final AppThemeMode value;
  final AppThemeMode currentValue;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return RadioListTile<AppThemeMode>(
      title: Text(title),
      value: value,
      secondary: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
