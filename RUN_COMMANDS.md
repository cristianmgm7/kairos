# Quick Run Commands

## 🤖 Android

### Development
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### Staging
```bash
flutter run --flavor staging -t lib/main_staging.dart
```

### Production
```bash
flutter run --flavor prod -t lib/main_prod.dart
```

## 🍎 iOS

**FIRST:** Add build script in Xcode (see FIREBASE_SETUP.md)

### Development
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### Staging
```bash
flutter run --flavor staging -t lib/main_staging.dart
```

### Production
```bash
flutter run --flavor prod -t lib/main_prod.dart
```

## 🔧 Build APKs

```bash
# Dev
flutter build apk --flavor dev -t lib/main_dev.dart

# Staging
flutter build apk --flavor staging -t lib/main_staging.dart

# Prod
flutter build apk --flavor prod -t lib/main_prod.dart
```

## 🧹 Clean Build

If you encounter issues:
```bash
flutter clean
flutter pub get
rm -rf build/
rm -rf ios/Pods/
cd ios && pod install && cd ..
```

## 📱 Run on Specific Device

```bash
# List devices
flutter devices

# Run on specific device
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```
