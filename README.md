# Flutter Blueprint App

A production-ready Flutter template with Clean Architecture, flavors, dependency injection, and Material 3 theming. This blueprint provides a solid foundation for building scalable Flutter applications.

## Features

- ✅ **3 Flavors**: Development, Staging, Production
- ✅ **Clean Architecture**: Organized folder structure with clear separation of concerns
- ✅ **Dependency Injection**: GetIt + Injectable for automatic DI
- ✅ **Navigation**: GoRouter with 5 base routes
- ✅ **Material 3 Theming**: Complete light/dark theme system
- ✅ **Reusable Widgets**: Essential UI components
- ✅ **Network Layer**: Dio client with error handling
- ✅ **Type-Safe Results**: Result type for error handling
- ✅ **Testing**: Unit and widget tests setup
- ✅ **CI/CD**: GitHub Actions pipeline
- ✅ **Linting**: Strict code quality with very_good_analysis

## Project Structure

```
lib/
├── core/
│   ├── config/              # App configuration (flavors, environment)
│   │   ├── flavor_config.dart
│   │   └── firebase_config.dart (placeholder)
│   ├── di/                  # Dependency injection
│   │   ├── injection.dart
│   │   └── core_module.dart
│   ├── errors/              # Error handling
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/             # API client
│   │   ├── api_client.dart
│   │   └── network_info.dart
│   ├── routing/             # Navigation
│   │   ├── app_router.dart
│   │   ├── app_routes.dart
│   │   └── pages/
│   ├── theme/               # Material 3 theming
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radii.dart
│   │   ├── app_shadows.dart
│   │   ├── app_durations.dart
│   │   ├── app_icons.dart
│   │   └── app_breakpoints.dart
│   ├── utils/               # Utilities
│   │   ├── result.dart
│   │   └── validators.dart
│   ├── widgets/             # Reusable widgets
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_text.dart
│   │   ├── app_loader.dart
│   │   └── app_error_view.dart
│   └── constants/
│       └── app_constants.dart
│
├── features/                # Feature modules (Clean Architecture)
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── [state_management]/
│
├── main.dart                # Common app entry
├── main_dev.dart            # Dev flavor entry
├── main_staging.dart        # Staging flavor entry
└── main_prod.dart           # Prod flavor entry
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.27.0
- Dart SDK >= 3.6.0
- Ruby (for iOS flavors) - optional
- Xcode (for iOS) - macOS only
- Android Studio / VS Code

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/flutter-blueprint.git
   cd flutter-blueprint
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   # Development
   flutter run --flavor dev -t lib/main_dev.dart

   # Staging
   flutter run --flavor staging -t lib/main_staging.dart

   # Production
   flutter run --flavor prod -t lib/main_prod.dart
   ```

## Development Workflow

### Code Generation

When adding new:
- Injectable services
- Freezed models
- JSON serializable classes
- Mockito mocks

Run:
```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (recommended)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/utils/validators_test.dart

# Run with coverage
flutter test --coverage

# View coverage (macOS/Linux)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Fix auto-fixable issues
dart fix --apply
```

### Building

```bash
# Android APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Android App Bundle
flutter build appbundle --flavor prod -t lib/main_prod.dart

# iOS (macOS only)
flutter build ios --flavor dev -t lib/main_dev.dart
```

## Configuration

### Flavors

Configured in `flavorizr.yaml`. To modify:

1. Update `flavorizr.yaml`
2. Run `flutter pub run flutter_flavorizr`
3. Clean and rebuild: `flutter clean && flutter pub get`

### Environment Variables

Edit `.env.dev`, `.env.staging`, `.env.prod` files:

```env
API_BASE_URL=https://api-dev.example.com
API_TIMEOUT=30000
APP_NAME=Blueprint Dev
ENVIRONMENT=development
ENABLE_LOGGING=true
```

Access in code:
```dart
FlavorConfig.instance.apiBaseUrl
FlavorConfig.instance.enableLogging
```

### Theme Customization

Update `lib/core/theme/app_colors.dart`:

```dart
static const Color seedColor = Color(0xFF6750A4); // Your brand color
```

Theme will auto-generate Material 3 colors.

## Adding a New Feature

Follow Clean Architecture pattern:

1. **Create feature folder**:
   ```bash
   mkdir -p lib/features/my_feature/{data,domain,presentation}
   mkdir -p lib/features/my_feature/data/{datasources,models,repositories}
   mkdir -p lib/features/my_feature/domain/{entities,repositories,usecases}
   mkdir -p lib/features/my_feature/presentation/{pages,widgets}
   ```

2. **Create domain layer** (business logic):
   - Define entities
   - Define repository interfaces
   - Create use cases

3. **Create data layer** (implementation):
   - Implement data sources
   - Create models
   - Implement repositories

4. **Create presentation layer** (UI):
   - Add state management (BLoC, Cubit, etc.)
   - Create pages and widgets

5. **Register dependencies** in DI:
   ```dart
   @injectable
   class MyFeatureRepository implements IMyFeatureRepository {
     // Implementation
   }
   ```

6. **Add routes** to `app_router.dart`

## CI/CD

GitHub Actions workflow in `.github/workflows/ci.yml`:

- ✅ Code analysis
- ✅ Tests with coverage
- ✅ Build for all flavors (Android & iOS)
- ✅ Code formatting check

## Best Practices

1. **Use dependency injection**: Always inject dependencies via constructors
2. **Follow Clean Architecture**: Keep layers separated
3. **Write tests**: Maintain high test coverage
4. **Use theme system**: Don't hardcode colors or styles
5. **Validate inputs**: Use `Validators` class
6. **Handle errors**: Use `Result` type for operations that can fail
7. **Use reusable widgets**: Leverage `app_*` widgets
8. **Format code**: Run `dart format .` before committing
9. **Run linting**: Fix issues before pushing

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a pull request

## iOS Deployment & TestFlight

### 🚀 Quick Start: Upload to TestFlight

Ready to distribute your app for testing? We've created comprehensive guides:

1. **Quick Start Guide** - `TESTFLIGHT_QUICK_START.md`
   - Fastest way to get your app on TestFlight
   - Two methods: Automated script or Xcode
   - Essential setup checklist

2. **Detailed Upload Guide** - `TESTFLIGHT_UPLOAD_GUIDE.md`
   - Complete step-by-step instructions
   - Apple Developer Portal setup
   - App Store Connect configuration
   - Troubleshooting tips

3. **Upload Checklist** - `TESTFLIGHT_CHECKLIST.md`
   - Checkbox-based workflow
   - Nothing to miss
   - Quick command reference

### Automated Build Script

Use the build script for the easiest experience:

```bash
# Run from project root
./scripts/build_for_testflight.sh
```

The script handles:
- ✅ Cleaning and dependencies
- ✅ Build number increment
- ✅ Production build
- ✅ IPA generation
- ✅ Ready for Transporter upload

### Manual Build Commands

```bash
# Build IPA for App Store upload
flutter build ipa --release --flavor production

# Or open in Xcode for Archive
open ios/Runner.xcworkspace
# Then: Product → Archive
```

### Your App Configuration

- **App Name**: Kairos
- **Bundle IDs**:
  - Production: `com.kairos-app.prod`
  - Staging: `com.kairos-app.staging`
  - Development: `com.kairos-app.dev`
- **Team ID**: 46GH5N7V96
- **Min iOS**: 13.0

### Required Apple Developer Setup

Before first upload:
1. Create App ID in Apple Developer Portal
2. Create Distribution Certificate
3. Create App Store Provisioning Profile
4. Create app in App Store Connect

📚 **See detailed instructions in `TESTFLIGHT_UPLOAD_GUIDE.md`**

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Material 3 Design System
- Flutter Team
- Very Good Ventures (for very_good_analysis)
- Community packages: GetIt, Injectable, GoRouter, Dio
- Firebase for backend services
- Apple Developer Program

---

Built with ❤️ using Flutter