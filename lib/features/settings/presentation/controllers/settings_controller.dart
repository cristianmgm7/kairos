import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings controller state
class SettingsState {
  const SettingsState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  SettingsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Settings controller
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._repository) : super(const SettingsState()) {
    _loadSettings();
  }

  final SettingsRepository _repository;
  SettingsEntity? _currentSettings;

  Future<void> _loadSettings() async {
    try {
      _currentSettings = await _repository.getSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update language
  Future<void> updateLanguage(AppLanguage language) async {
    if (_currentSettings == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final newSettings = _currentSettings!.copyWith(language: language);
      await _repository.updateSettings(newSettings);
      _currentSettings = newSettings;
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    if (_currentSettings == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final newSettings = _currentSettings!.copyWith(themeMode: themeMode);
      await _repository.updateSettings(newSettings);
      _currentSettings = newSettings;
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
