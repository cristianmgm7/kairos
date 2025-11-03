# Internationalization (i18n) and Settings Feature Implementation Plan

## Overview

Integrate Flutter's official internationalization system (flutter_localizations and intl) to support multiple languages (English and Spanish initially), and replace the Profile tab with a Settings tab that allows users to change language and theme preferences. Preferences will be persisted locally using Isar and managed via Riverpod state management.

## Current State Analysis

**Existing Setup:**
- MaterialApp configured in [lib/main.dart:72-78](lib/main.dart#L72-L78) with static theme
- Bottom navigation with 4 tabs in [lib/core/widgets/main_scaffold.dart:35-60](lib/core/widgets/main_scaffold.dart#L35-L60)
- Profile tab currently shows user profile information
- Riverpod state management with StateNotifierProvider pattern
- Isar database already initialized for local persistence
- AppTheme provides `lightTheme` and `darkTheme` in [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart)

**Missing:**
- No i18n/l10n setup (flutter_localizations, intl packages not added)
- No locale or themeMode management
- No settings persistence mechanism
- No settings screen or feature

## Desired End State

After implementation:
1. App supports English (en) and Spanish (es) with dynamic language switching
2. Settings tab replaces Profile tab in bottom navigation
3. Users can change language (English/Spanish) and theme (Light/Dark/System)
4. Preferences persist across app restarts
5. All hardcoded strings replaced with localized versions
6. MaterialApp responds to theme and locale changes reactively

**Verification:**
- User can switch language and see all text update immediately
- User can switch theme and see UI update immediately
- Preferences persist after app restart
- System theme changes are respected when "System" theme is selected

## What We're NOT Doing

- Supporting languages beyond English and Spanish in this phase
- Creating a full settings menu with multiple options (only language and theme for now)
- Migrating Profile screen content elsewhere (it will remain accessible via a different route later)
- Implementing RTL (Right-to-Left) language support
- Adding locale-specific date/number formatting beyond basic support

## Implementation Approach

Use Flutter's official i18n system with ARB (Application Resource Bundle) files for translations. Create a Settings feature following the existing clean architecture pattern. Persist settings using Isar (consistent with existing persistence approach). Use Riverpod StateNotifierProvider to manage settings state and make MaterialApp reactive to changes.

---

## Phase 1: Dependencies and i18n Setup

### Overview
Add required packages and set up the Flutter localization infrastructure with ARB files for English and Spanish.

### Changes Required:

#### 1. Update Dependencies
**File**: `pubspec.yaml`
**Changes**: Add i18n and localization dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

  # ... existing dependencies
```

Run `flutter pub get` after updating.

#### 2. Configure Code Generation
**File**: `pubspec.yaml`
**Changes**: Add generate flag and l10n configuration

```yaml
flutter:
  uses-material-design: true
  generate: true  # Enable code generation

  assets:
    - .env.dev
    - .env.staging
    - .env.prod
```

#### 3. Create l10n Configuration
**File**: `l10n.yaml` (new file in project root)
**Content**:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

#### 4. Create English ARB File
**File**: `lib/l10n/app_en.arb` (new file)
**Content**:

```json
{
  "@@locale": "en",

  "appTitle": "Kairos",
  "@appTitle": {
    "description": "The application title"
  },

  "home": "Home",
  "@home": {
    "description": "Home tab label"
  },

  "journal": "Journal",
  "@journal": {
    "description": "Journal tab label"
  },

  "notifications": "Notifications",
  "@notifications": {
    "description": "Notifications tab label"
  },

  "settings": "Settings",
  "@settings": {
    "description": "Settings tab label"
  },

  "profile": "Profile",
  "@profile": {
    "description": "Profile label"
  },

  "language": "Language",
  "@language": {
    "description": "Language setting label"
  },

  "theme": "Theme",
  "@theme": {
    "description": "Theme setting label"
  },

  "themeLight": "Light",
  "@themeLight": {
    "description": "Light theme option"
  },

  "themeDark": "Dark",
  "@themeDark": {
    "description": "Dark theme option"
  },

  "themeSystem": "System",
  "@themeSystem": {
    "description": "System theme option"
  },

  "english": "English",
  "@english": {
    "description": "English language option"
  },

  "spanish": "Spanish",
  "@spanish": {
    "description": "Spanish language option"
  },

  "logout": "Logout",
  "@logout": {
    "description": "Logout button label"
  },

  "error": "Error",
  "@error": {
    "description": "Generic error label"
  },

  "loading": "Loading",
  "@loading": {
    "description": "Loading indicator label"
  }
}
```

#### 5. Create Spanish ARB File
**File**: `lib/l10n/app_es.arb` (new file)
**Content**:

```json
{
  "@@locale": "es",

  "appTitle": "Kairos",

  "home": "Inicio",
  "journal": "Diario",
  "notifications": "Notificaciones",
  "settings": "Ajustes",
  "profile": "Perfil",

  "language": "Idioma",
  "theme": "Tema",

  "themeLight": "Claro",
  "themeDark": "Oscuro",
  "themeSystem": "Sistema",

  "english": "Inglés",
  "spanish": "Español",

  "logout": "Cerrar sesión",
  "error": "Error",
  "loading": "Cargando"
}
```

#### 6. Update MaterialApp Configuration
**File**: `lib/main.dart`
**Changes**: Add localization delegates and supported locales

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,

      // Add localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Dependencies added successfully: `flutter pub get`
- [x] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs` or `flutter gen-l10n`
- [x] Generated file exists: `lib/.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
- [x] App builds without errors: `flutter build ios --debug` (or appropriate platform)
- [x] No linting errors: `dart format . && flutter analyze`

#### Manual Verification:
- [ ] App launches successfully with localization delegates
- [ ] Default language (English) displays correctly
- [ ] No missing localization errors in console

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Settings Data Layer (Domain & Data)

### Overview
Create the settings feature following clean architecture: domain entities, repository interface, Isar model, and repository implementation.

### Changes Required:

#### 1. Create Settings Entity
**File**: `lib/features/settings/domain/entities/settings_entity.dart` (new file)
**Content**:

```dart
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
```

#### 2. Create Settings Repository Interface
**File**: `lib/features/settings/domain/repositories/settings_repository.dart` (new file)
**Content**:

```dart
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
```

#### 3. Create Settings Isar Model
**File**: `lib/features/settings/data/models/settings_model.dart` (new file)
**Content**:

```dart
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:isar/isar.dart';

part 'settings_model.g.dart';

@collection
class SettingsModel {
  SettingsModel({
    required this.language,
    required this.themeMode,
  });

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

  /// Create from domain entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      language: entity.language,
      themeMode: entity.themeMode,
    );
  }

  /// Default settings
  factory SettingsModel.defaults() {
    return SettingsModel(
      language: AppLanguage.english,
      themeMode: AppThemeMode.system,
    );
  }
}
```

#### 4. Create Settings Local Data Source
**File**: `lib/features/settings/data/datasources/settings_local_datasource.dart` (new file)
**Content**:

```dart
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
```

#### 5. Create Settings Repository Implementation
**File**: `lib/features/settings/data/repositories/settings_repository_impl.dart` (new file)
**Content**:

```dart
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
```

#### 6. Update Database Provider
**File**: `lib/core/providers/database_provider.dart`
**Changes**: Add SettingsModel schema

```dart
import 'package:kairos/features/profile/data/models/user_profile_model.dart';
import 'package:kairos/features/settings/data/models/settings_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar provider must be overridden');
});

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      UserProfileModelSchema,
      SettingsModelSchema, // Add this
    ],
    directory: dir.path,
    name: 'kairos_db',
    inspector: true,
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Generated file exists: `lib/features/settings/data/models/settings_model.g.dart`
- [ ] No type errors: `flutter analyze`
- [ ] App builds successfully: `flutter build ios --debug`
- [ ] Isar schema updated with SettingsModel

#### Manual Verification:
- [ ] Isar Inspector shows `settings_models` collection
- [ ] Default settings object created in database on first access

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Settings Presentation Layer (Providers & Controller)

### Overview
Create Riverpod providers for settings management and a settings controller to handle state changes and persistence.

### Changes Required:

#### 1. Create Settings Providers
**File**: `lib/features/settings/presentation/providers/settings_providers.dart` (new file)
**Content**:

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:kairos/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/domain/repositories/settings_repository.dart';
import 'package:kairos/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local data source provider
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
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
```

#### 2. Create Settings Controller
**File**: `lib/features/settings/presentation/controllers/settings_controller.dart` (new file)
**Content**:

```dart
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
```

#### 3. Update MaterialApp to Use Settings
**File**: `lib/main.dart`
**Changes**: Make MaterialApp reactive to locale and theme settings

```dart
import 'package:kairos/core/config/firebase_config.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/core/routing/router_provider.dart';
import 'package:kairos/core/theme/app_theme.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ... main function stays the same ...

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp.router(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Add this
      locale: locale, // Add this
      routerConfig: router,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] No type errors: `flutter analyze`
- [ ] Code compiles successfully: `flutter build ios --debug`
- [ ] No linting errors: `dart format .`

#### Manual Verification:
- [ ] App launches without errors
- [ ] Settings are loaded from database on startup
- [ ] MaterialApp responds to settings changes (can verify in next phase)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Settings UI Screen

### Overview
Create the Settings screen UI with language and theme selection, and add logout functionality.

### Changes Required:

#### 1. Create Settings Screen
**File**: `lib/features/settings/presentation/screens/settings_screen.dart` (new file)
**Content**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/settings/domain/entities/settings_entity.dart';
import 'package:kairos/features/settings/presentation/controllers/settings_controller.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';

/// Settings screen - allows user to change language and theme.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Column(
      children: [
        AppBar(
          title: Text(l10n.settings),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
              tooltip: l10n.logout,
            ),
          ],
        ),
        Expanded(
          child: settingsAsync.when(
            data: (settings) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Language Section
                  Text(
                    l10n.language,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LanguageSelector(currentLanguage: settings.language),

                  const SizedBox(height: AppSpacing.xl),

                  // Theme Section
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ThemeSelector(currentThemeMode: settings.themeMode),
                ],
              );
            },
            loading: () => Center(child: Text(l10n.loading)),
            error: (error, stack) => Center(
              child: Text('${l10n.error}: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector({required this.currentLanguage});

  final AppLanguage currentLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: Column(
        children: AppLanguage.values.map((language) {
          return RadioListTile<AppLanguage>(
            title: Text(
              language == AppLanguage.english ? l10n.english : l10n.spanish,
            ),
            value: language,
            groupValue: currentLanguage,
            onChanged: (AppLanguage? value) {
              if (value != null) {
                controller.updateLanguage(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.currentThemeMode});

  final AppThemeMode currentThemeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Card(
      child: Column(
        children: [
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeLight),
            value: AppThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeDark),
            value: AppThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.themeSystem),
            value: AppThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] No type errors: `flutter analyze`
- [ ] Code compiles successfully: `flutter build ios --debug`
- [ ] No linting errors: `dart format .`

#### Manual Verification:
- [ ] Settings screen displays with language and theme options
- [ ] Radio buttons show correct current selections
- [ ] Logout button is visible in app bar

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Update Navigation and Bottom Bar

### Overview
Replace the Profile tab with Settings tab in the bottom navigation and update routing configuration.

### Changes Required:

#### 1. Update App Routes
**File**: `lib/core/routing/app_routes.dart`
**Changes**: Replace profile route with settings route

```dart
class AppRoutes {
  AppRoutes._();

  // Authentication routes (outside shell)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding route (authenticated but outside shell)
  static const String createProfile = '/create-profile';

  // Main app routes (inside shell)
  static const String home = '/home';
  static const String journal = '/journal';
  static const String notifications = '/notifications';
  static const String settings = '/settings'; // Changed from profile

  // Error
  static const String error = '/error';
}
```

#### 2. Update Router Provider
**File**: `lib/core/routing/router_provider.dart`
**Changes**: Replace ProfileScreen route with SettingsScreen route

```dart
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/routing/auth_redirect.dart';
import 'package:kairos/core/routing/pages/error_page.dart';
import 'package:kairos/core/routing/pages/loading_page.dart';
import 'package:kairos/core/widgets/main_scaffold.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/auth/presentation/screens/login_screen.dart';
import 'package:kairos/features/auth/presentation/screens/register_screen.dart';
import 'package:kairos/features/home/presentation/screens/home_screen.dart';
import 'package:kairos/features/journal/presentation/screens/journal_screen.dart';
import 'package:kairos/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/profile/presentation/screens/create_profile_screen.dart';
import 'package:kairos/features/settings/presentation/screens/settings_screen.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ... keep existing keys and provider setup ...

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasProfile = ref.watch(hasCompletedProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // ... keep existing redirect logic ...
    },
    routes: [
      // ... keep existing routes (splash, login, register, createProfile) ...

      // Shell route (persistent bottom navigation for all main app routes)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.journal,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings, // Changed from profile
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(), // Changed from ProfileScreen
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(
      error: state.error?.toString(),
    ),
  );
});
```

#### 3. Update Bottom Navigation Bar
**File**: `lib/core/widgets/main_scaffold.dart`
**Changes**: Update navigation destinations and logic

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';

/// MainScaffold provides a persistent bottom navigation bar for the main app.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _MainBottomNavigationBar(),
    );
  }
}

class _MainBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String location = GoRouterState.of(context).matchedLocation;

    int currentIndex = _getSelectedIndex(location);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.book_outlined),
          selectedIcon: const Icon(Icons.book),
          label: l10n.journal,
        ),
        NavigationDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications),
          label: l10n.notifications,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings, // Changed from profile
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.journal)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3; // Changed
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.journal);
        break;
      case 2:
        context.go(AppRoutes.notifications);
        break;
      case 3:
        context.go(AppRoutes.settings); // Changed
        break;
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] No type errors: `flutter analyze`
- [ ] Code compiles successfully: `flutter build ios --debug`
- [ ] No linting errors: `dart format .`

#### Manual Verification:
- [ ] Bottom navigation shows "Settings" instead of "Profile"
- [ ] Settings icon displays in navigation bar
- [ ] Tapping settings tab navigates to settings screen
- [ ] Navigation label updates when language is changed

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 6: Localize Existing Screens

### Overview
Update existing screens to use localized strings instead of hardcoded text. This is a comprehensive pass through the main screens.

### Changes Required:

#### 1. Update ARB Files with Additional Strings
**File**: `lib/l10n/app_en.arb`
**Changes**: Add strings for existing screens

```json
{
  "@@locale": "en",

  // ... existing strings ...

  "noProfileFound": "No profile found",
  "@noProfileFound": {
    "description": "Message when user profile is not found"
  },

  "dateOfBirth": "Date of Birth",
  "@dateOfBirth": {
    "description": "Date of birth label"
  },

  "country": "Country",
  "@country": {
    "description": "Country label"
  },

  "gender": "Gender",
  "@gender": {
    "description": "Gender label"
  },

  "mainGoal": "Main Goal",
  "@mainGoal": {
    "description": "Main goal label"
  },

  "experienceLevel": "Experience Level",
  "@experienceLevel": {
    "description": "Experience level label"
  },

  "interests": "Interests",
  "@interests": {
    "description": "Interests label"
  },

  "editProfile": "Edit Profile",
  "@editProfile": {
    "description": "Edit profile button label"
  },

  "editProfileComingSoon": "Edit profile - Coming soon",
  "@editProfileComingSoon": {
    "description": "Edit profile coming soon message"
  },

  "notSet": "Not set",
  "@notSet": {
    "description": "Placeholder when a field is not set"
  }
}
```

**File**: `lib/l10n/app_es.arb`
**Changes**: Add Spanish translations

```json
{
  "@@locale": "es",

  // ... existing strings ...

  "noProfileFound": "No se encontró perfil",
  "dateOfBirth": "Fecha de nacimiento",
  "country": "País",
  "gender": "Género",
  "mainGoal": "Objetivo principal",
  "experienceLevel": "Nivel de experiencia",
  "interests": "Intereses",
  "editProfile": "Editar perfil",
  "editProfileComingSoon": "Editar perfil - Próximamente",
  "notSet": "No establecido"
}
```

#### 2. Update ProfileScreen (for future use)
**File**: `lib/features/profile/presentation/screens/profile_screen.dart`
**Changes**: Replace hardcoded strings with localized versions

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Column(
      children: [
        AppBar(
          title: Text(l10n.profile),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
              tooltip: l10n.logout,
            ),
          ],
        ),
        Expanded(
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return Center(child: Text(l10n.noProfileFound));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    // Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Name
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Profile details
                    _ProfileDetailTile(
                      icon: Icons.calendar_today,
                      title: l10n.dateOfBirth,
                      value: profile.dateOfBirth != null
                          ? '${profile.dateOfBirth!.month}/${profile.dateOfBirth!.day}/${profile.dateOfBirth!.year}'
                          : l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.public,
                      title: l10n.country,
                      value: profile.country ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.person_outline,
                      title: l10n.gender,
                      value: profile.gender ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.flag,
                      title: l10n.mainGoal,
                      value: profile.mainGoal ?? l10n.notSet,
                    ),
                    _ProfileDetailTile(
                      icon: Icons.star,
                      title: l10n.experienceLevel,
                      value: profile.experienceLevel ?? l10n.notSet,
                    ),
                    if (profile.interests != null &&
                        profile.interests!.isNotEmpty)
                      _ProfileDetailTile(
                        icon: Icons.favorite,
                        title: l10n.interests,
                        value: profile.interests!.join(', '),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Edit button
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.editProfileComingSoon),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(l10n.editProfile),
                    ),
                  ],
                ),
              );
            },
            loading: () => Center(child: Text(l10n.loading)),
            error: (error, stack) => Center(
              child: Text('${l10n.error}: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

// ... keep _ProfileDetailTile unchanged ...
```

### Success Criteria:

#### Automated Verification:
- [ ] Code generation completes: `flutter gen-l10n`
- [ ] No type errors: `flutter analyze`
- [ ] Code compiles successfully: `flutter build ios --debug`
- [ ] No linting errors: `dart format .`

#### Manual Verification:
- [ ] All screens display text in current language
- [ ] Switching language updates all visible text immediately
- [ ] No hardcoded English strings visible when Spanish is selected
- [ ] Bottom navigation labels update with language

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 7: End-to-End Testing and Persistence Verification

### Overview
Final testing phase to ensure all features work together correctly and preferences persist across app restarts.

### Testing Checklist:

#### 1. Language Switching Tests
- [ ] Launch app and navigate to Settings
- [ ] Change language from English to Spanish
- [ ] Verify all UI text updates immediately (bottom nav, settings screen, app bar)
- [ ] Navigate to Home, Journal, Notifications screens
- [ ] Verify all screens display Spanish text
- [ ] Switch back to English
- [ ] Verify all text updates to English

#### 2. Theme Switching Tests
- [ ] In Settings, select Light theme
- [ ] Verify app displays in light mode regardless of system setting
- [ ] Select Dark theme
- [ ] Verify app displays in dark mode regardless of system setting
- [ ] Select System theme
- [ ] Change device theme setting
- [ ] Verify app follows system theme

#### 3. Persistence Tests
- [ ] Change language to Spanish
- [ ] Change theme to Dark
- [ ] Kill the app (force quit)
- [ ] Relaunch the app
- [ ] Verify language is still Spanish
- [ ] Verify theme is still Dark
- [ ] Repeat with different combinations

#### 4. Navigation Tests
- [ ] Verify Settings tab appears as 4th tab in bottom navigation
- [ ] Tap each tab and verify correct screen displays
- [ ] Verify Settings tab icon changes when selected/unselected
- [ ] Verify Settings tab label is localized

#### 5. Logout Test
- [ ] From Settings screen, tap logout button
- [ ] Verify app navigates to login screen
- [ ] Log back in
- [ ] Verify settings are still persisted

#### 6. Edge Cases
- [ ] Launch app with no internet connection
- [ ] Verify settings still load from local database
- [ ] Verify theme and language work offline
- [ ] Test rapid switching between languages
- [ ] Test rapid switching between themes

### Success Criteria:

#### Automated Verification:
- [ ] All unit tests pass (if any): `flutter test`
- [ ] Integration tests pass (if any): `flutter test integration_test`
- [ ] No console errors during normal operation
- [ ] No exceptions in debug logs during testing

#### Manual Verification:
- [ ] All language switching tests pass
- [ ] All theme switching tests pass
- [ ] All persistence tests pass
- [ ] All navigation tests pass
- [ ] Logout test passes
- [ ] All edge cases handled gracefully
- [ ] App performance is smooth (no lag when switching settings)
- [ ] Settings changes feel instant to the user

**Implementation Note**: This is the final phase. Once all automated and manual verification passes, the implementation is complete.

---

## Testing Strategy

### Unit Tests
Create unit tests for:
- `SettingsEntity` copyWith and equality
- `SettingsRepository` implementations
- `SettingsController` language and theme update logic
- Enum conversions (AppLanguage, AppThemeMode)

Example test file: `test/features/settings/domain/entities/settings_entity_test.dart`

### Integration Tests
Create integration tests for:
- End-to-end language switching flow
- End-to-end theme switching flow
- Settings persistence across app restarts
- Navigation to Settings screen

Example test file: `integration_test/settings_flow_test.dart`

### Manual Testing
Key scenarios to test manually:
1. First app launch with default settings
2. Language change affects all screens
3. Theme change is immediate and persists
4. System theme is respected when "System" is selected
5. Settings survive app restart
6. Settings work offline

## Performance Considerations

**State Management:**
- Settings are watched via StreamProvider for reactive updates
- Only settings changes trigger rebuilds, not every database access
- Isar provides efficient reactive queries

**Database Performance:**
- Settings use a single document (ID = 1) for O(1) access
- No complex queries or indexes needed
- Isar is very fast for single-document reads/writes

**Localization Performance:**
- Generated localization delegates are efficient
- No runtime lookups or file I/O for translations
- ARB files compiled into app bundle

**Memory:**
- Settings entity is small (2 enums)
- No image or large data in settings
- Minimal memory footprint

## Migration Notes

**No Data Migration Required:**
- Settings is a new feature
- Isar will create the settings collection automatically
- Default settings (English, System theme) used on first launch
- Existing users will start with defaults

**Backwards Compatibility:**
- ProfileScreen code remains but is not routed to
- Can be accessed later via a different route if needed
- No breaking changes to existing features

**Deployment:**
1. Deploy code with new dependencies
2. Users will see Settings tab on first launch after update
3. Default to English and System theme
4. No user action required

## References

- Official Flutter internationalization guide: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- Isar documentation: https://isar.dev
- Riverpod state management: https://riverpod.dev
- Material Design 3 theming: https://m3.material.io/styles/color/the-color-system/key-colors-tones
