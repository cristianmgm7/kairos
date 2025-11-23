import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/extensions/extensions.dart';
import 'package:kairos/l10n/app_localizations.dart';

// ignore: comment_references
/// Prefer using [context.l10n]
///
/// ```dart
/// context.l10n.translation
/// ```
///
/// [l10nProvider] should be only used when [BuildContext] is not available
final l10nProvider = Provider<AppLocalizations>((ref) {
  throw UnimplementedError('l10nProvider provider must be overridden');
});

abstract class L10n {
  const L10n._();

  static String onGenerateTitle(BuildContext context) {
    final l10n = context.l10n;
    l10nProvider.overrideWithValue(l10n);

    return 'Kairos';
  }

  static List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static List<Locale> supportedLocales = [
    const Locale('en'), // English
    const Locale('es'), // Spanish
  ];
}
