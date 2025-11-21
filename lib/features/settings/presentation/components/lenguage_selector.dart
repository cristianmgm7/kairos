import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, required this.currentLanguage});

  final AppLanguage currentLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: RadioGroup<AppLanguage>(
        groupValue: currentLanguage,
        onChanged: (AppLanguage? value) {
          if (value != null) {
            controller.updateLanguage(value);
          }
        },
        child: Column(
          children: AppLanguage.values.map((language) {
            return RadioListTile<AppLanguage>(
              title: Text(
                language == AppLanguage.english ? l10n.english : l10n.spanish,
              ),
              value: language,
            );
          }).toList(),
        ),
      ),
    );
  }
}








