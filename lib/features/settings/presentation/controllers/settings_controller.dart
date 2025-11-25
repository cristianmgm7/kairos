import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';

import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/domain/repositories/settings_repository.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';

/// Settings controller
class SettingsController extends StreamNotifier<SettingsEntity> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Stream<SettingsEntity> build() {
    return ref.watch(settingsRepositoryProvider).watchSettings();
  }

  Future<void> updateLanguage(AppLanguage language) async {
    try {
      await _repository.updateSettings(state.requireValue.copyWith(language: language));
    } catch (e, s) {
      logger.e('Error updating language', error: e, stackTrace: s);

      state = AsyncError(e, s);
    }
  }

  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    try {
      await _repository.updateSettings(state.requireValue.copyWith(themeMode: themeMode));
    } catch (e, s) {
      logger.e('Error updating theme mode', error: e, stackTrace: s);

      state = AsyncError(e, s);
    }
  }
}
