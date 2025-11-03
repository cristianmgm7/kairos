import 'package:isar/isar.dart';

import 'package:kairos/features/settings/domain/entities/settings_entity.dart';

part 'settings_model.g.dart';

@collection
class SettingsModel {
  SettingsModel({
    required this.language,
    required this.themeMode,
  });

  /// Default settings
  factory SettingsModel.defaults() {
    return SettingsModel(
      language: AppLanguage.english,
      themeMode: AppThemeMode.system,
    );
  }

  /// Create from domain entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      language: entity.language,
      themeMode: entity.themeMode,
    );
  }

  /// Fixed ID to ensure only one settings object
  final Id id = 1;

  @enumerated
  late AppLanguage language;

  @enumerated
  late AppThemeMode themeMode;


  /// Convert to domain entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      language: language,
      themeMode: themeMode,
    );
  }
}
