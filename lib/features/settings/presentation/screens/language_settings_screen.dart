import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Language settings screen - allows user to change language.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: settingsAsync.when(
        data: (settings) => RadioGroup<AppLanguage>(
          groupValue: settings.language,
          onChanged: (value) {
            ref.read(settingsControllerProvider.notifier).updateLanguage(value!);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              const SizedBox(height: AppSpacing.lg),
              _LanguageOptionTile(
                title: l10n.english,
                value: AppLanguage.english,
                currentValue: settings.language,
              ),
              const Divider(),
              _LanguageOptionTile(
                title: l10n.spanish,
                value: AppLanguage.spanish,
                currentValue: settings.language,
              ),
            ],
          ),
        ),
        loading: () => Center(child: Text(l10n.loading)),
        error: (error, stack) => Center(
          child: Text('${l10n.error}: $error'),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.value,
    required this.currentValue,
  });

  final String title;
  final AppLanguage value;
  final AppLanguage currentValue;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return RadioListTile<AppLanguage>(
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
