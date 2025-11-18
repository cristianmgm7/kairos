import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key, required this.currentThemeMode});

  final AppThemeMode currentThemeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: RadioGroup<AppThemeMode>(
        groupValue: currentThemeMode,
        onChanged: (AppThemeMode? value) {
          if (value != null) {
            controller.updateThemeMode(value);
          }
        },
        child: Column(
          children: [
            RadioListTile<AppThemeMode>(
              title: Text(l10n.themeLight),
              value: AppThemeMode.light,
            ),
            RadioListTile<AppThemeMode>(
              title: Text(l10n.themeDark),
              value: AppThemeMode.dark,
            ),
            RadioListTile<AppThemeMode>(
              title: Text(l10n.themeSystem),
              value: AppThemeMode.system,
            ),
          ],
        ),
      ),
    );
  }
}


