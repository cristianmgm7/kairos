import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:kairos/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/domain/repositories/settings_repository.dart';
import 'package:kairos/features/settings/presentation/controllers/settings_controller.dart';

/// Local data source provider
final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return SettingsLocalDataSourceImpl(isar);
});

/// Repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localDataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(localDataSource: localDataSource);
});

/// Settings stream provider
final settingsStreamProvider = StreamProvider<SettingsEntity>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchSettings();
});

/// Settings controller provider
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsController(repository);
});

/// Current locale provider (derived from settings)
final currentLocaleProvider = Provider<Locale>((ref) {
  final settingsAsync = ref.watch(settingsStreamProvider);
  return settingsAsync.maybeWhen(
    data: (settings) => Locale(settings.language.code),
    orElse: () => const Locale('en'),
  );
});

/// Current theme mode provider (derived from settings)
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsStreamProvider);
  return settingsAsync.maybeWhen(
    data: (settings) {
      switch (settings.themeMode) {
        case AppThemeMode.light:
          return ThemeMode.light;
        case AppThemeMode.dark:
          return ThemeMode.dark;
        case AppThemeMode.system:
          return ThemeMode.system;
      }
    },
    orElse: () => ThemeMode.system,
  );
});
