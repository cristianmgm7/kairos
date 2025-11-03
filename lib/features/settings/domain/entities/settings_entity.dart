import 'package:equatable/equatable.dart';

/// Supported languages
enum AppLanguage {
  english('en', 'English', 'Inglés'),
  spanish('es', 'Spanish', 'Español');

  const AppLanguage(this.code, this.nameEn, this.nameEs);

  final String code;
  final String nameEn;
  final String nameEs;

  String getName(String currentLocale) {
    return currentLocale == 'es' ? nameEs : nameEn;
  }
}

/// Supported theme modes
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const AppThemeMode(this.value);

  final String value;
}

/// Settings entity
class SettingsEntity extends Equatable {
  const SettingsEntity({
    required this.language,
    required this.themeMode,
  });

  final AppLanguage language;
  final AppThemeMode themeMode;

  SettingsEntity copyWith({
    AppLanguage? language,
    AppThemeMode? themeMode,
  }) {
    return SettingsEntity(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [language, themeMode];
}
