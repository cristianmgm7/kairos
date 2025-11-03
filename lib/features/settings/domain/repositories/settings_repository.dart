import 'package:kairos/features/settings/domain/entities/settings_entity.dart';

/// Repository interface for settings
abstract class SettingsRepository {
  /// Get current settings
  Future<SettingsEntity> getSettings();

  /// Update settings
  Future<void> updateSettings(SettingsEntity settings);

  /// Watch settings changes
  Stream<SettingsEntity> watchSettings();
}
