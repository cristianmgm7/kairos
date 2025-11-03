import 'package:kairos/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:kairos/features/settings/data/models/settings_model.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<SettingsEntity> getSettings() async {
    final model = await _localDataSource.getSettings();
    return model.toEntity();
  }

  @override
  Future<void> updateSettings(SettingsEntity settings) async {
    final model = SettingsModel.fromEntity(settings);
    await _localDataSource.saveSettings(model);
  }

  @override
  Stream<SettingsEntity> watchSettings() {
    return _localDataSource.watchSettings().map((model) => model.toEntity());
  }
}
