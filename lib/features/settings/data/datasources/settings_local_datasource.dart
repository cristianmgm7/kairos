import 'package:kairos/features/settings/data/models/settings_model.dart';
import 'package:isar/isar.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
  Stream<SettingsModel> watchSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._isar);

  final Isar _isar;

  @override
  Future<SettingsModel> getSettings() async {
    final settings = await _isar.settingsModels.get(1);
    return settings ?? SettingsModel.defaults();
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _isar.writeTxn(() async {
      await _isar.settingsModels.put(settings);
    });
  }

  @override
  Stream<SettingsModel> watchSettings() {
    return _isar.settingsModels
        .watchObject(1, fireImmediately: true)
        .map((settings) => settings ?? SettingsModel.defaults());
  }
}
