import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kairos/core/extensions/extensions.dart';
import 'package:kairos/l10n/app_localizations.dart';

// ignore: comment_references
/// Prefer using [context.l10n]
///
/// ```dart
/// context.l10n.translation
/// ```
///
/// [l10n] should be only used when [BuildContext] is not available
late AppLocalizations l10n;

abstract class L10n {
  const L10n._();

  static String onGenerateTitle(BuildContext context) {
    l10n = context.l10n;

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
