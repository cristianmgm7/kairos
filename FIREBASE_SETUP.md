# Firebase Setup Complete - Next Steps

## ✅ What's Already Done

### Android Setup
- ✅ `google-services.json` files copied to:
  - `android/app/src/dev/google-services.json`
  - `android/app/src/staging/google-services.json`
  - `android/app/src/prod/google-services.json`
- ✅ Google Services plugin configured in Gradle
- ✅ Android should build and run immediately

### iOS Setup
- ✅ `GoogleService-Info.plist` files copied to:
  - `ios/config/develop/GoogleService-Info.plist`
  - `ios/config/staging/GoogleService-Info.plist`
  - `ios/config/production/GoogleService-Info.plist`
- ✅ URL scheme added to `Info.plist` for Google Sign-In
- ✅ Build script created: `ios/scripts/copy-firebase-config.sh`

## 🔧 iOS Xcode Configuration Needed

You need to configure iOS schemes in Xcode. Here's how:

### Option 1: Quick Setup (Recommended for Testing)

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add the copy-firebase-config.sh script to build phases:**
   - Click on "Runner" project in the left sidebar
   - Select the "Runner" target
   - Go to "Build Phases" tab
   - Click "+" and select "New Run Script Phase"
   - Drag it above "Compile Sources"
   - Add this script:
     ```bash
     "${SRCROOT}/scripts/copy-firebase-config.sh"
     ```
   - Name it "Copy Firebase Config"

3. **Test the build:**
   ```bash
   flutter run --flavor dev -t lib/main_dev.dart
   ```

### Option 2: Full Scheme Setup (Production Ready)

If you want proper schemes like Android (dev/staging/prod), follow these steps:

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Create Build Configurations:**
   - Click "Runner" project → "Info" tab
   - Under "Configurations", duplicate existing configs:
     - Duplicate "Debug" → "Debug-develop"
     - Duplicate "Debug" → "Debug-staging"
     - Duplicate "Debug" → "Debug-production"
     - Duplicate "Release" → "Release-develop"
     - Duplicate "Release" → "Release-staging"
     - Duplicate "Release" → "Release-production"

3. **Create Schemes:**
   - Product → Scheme → Manage Schemes
   - Create new schemes:
     - "develop" (uses Debug-develop/Release-develop)
     - "staging" (uses Debug-staging/Release-staging)
     - "production" (uses Debug-production/Release-production)

4. **Add Build Script** (same as Option 1, step 2)

5. **Update Bundle Identifiers** (in project settings):
   - develop: `com.blueprint.blueprint_app.dev`
   - staging: `com.blueprint.blueprint_app.staging`
   - production: `com.blueprint.blueprint_app`

## 🚀 Quick Start (Testing Now)

### Android:
```bash
# Dev flavor
flutter run --flavor dev -t lib/main_dev.dart

# Staging flavor
flutter run --flavor staging -t lib/main_staging.dart

# Prod flavor
flutter run --flavor prod -t lib/main_prod.dart
```

### iOS (after adding build script):
```bash
# Dev
flutter run --flavor dev -t lib/main_dev.dart

# Note: For iOS, the script will automatically use develop config
# Full scheme support requires Option 2 above
```

## 🧪 Testing Authentication

Once the app launches:

1. **Test Email Registration:**
   - Tap "Sign Up"
   - Enter email and password
   - Should create account and navigate to dashboard

2. **Test Email Login:**
   - Sign out
   - Enter credentials
   - Should sign in and show user info

3. **Test Google Sign-In:**
   - Tap "Sign in with Google"
   - Complete OAuth flow
   - Should show user profile pic and name

4. **Test Session Persistence:**
   - Close app completely
   - Reopen
   - Should stay logged in and go to dashboard

5. **Test Sign Out:**
   - Tap sign out button
   - Should redirect to login screen

## ⚠️ Important Notes

### URL Schemes for iOS
The URL scheme in `Info.plist` is from the **develop** config. If you need different URL schemes per flavor:

1. Each `GoogleService-Info.plist` has its own `REVERSED_CLIENT_ID`
2. You'll need to configure this per build configuration in Xcode
3. Or use a script to inject it dynamically (more advanced)

For now, all flavors will use the develop URL scheme for Google Sign-In on iOS.

### Firebase Console Settings
Make sure in your Firebase console:
- ✅ Email/Password authentication is enabled
- ✅ Google authentication is enabled
- ✅ OAuth consent screen is configured
- ✅ SHA-1/SHA-256 fingerprints added for Android (for Google Sign-In)

### Getting SHA-1 Fingerprint (if needed):
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## 📝 What's Next

1. **Immediate:** Add the Xcode build script (Option 1)
2. **Today:** Test the app with all auth flows
3. **Later:** Set up proper iOS schemes (Option 2) if needed
4. **Phase 7:** Add unit tests (optional, in the plan)

## 🐛 Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Make sure the build script ran (check Xcode build logs)
- Verify `GoogleService-Info.plist` is in the app bundle

### Google Sign-In doesn't work on iOS
- Check URL schemes are correct in `Info.plist`
- Verify OAuth consent screen is configured in Firebase
- Make sure the OAuth client is added to the Firebase project

### Android build fails
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild: `flutter run --flavor dev -t lib/main_dev.dart`

## 🎯 Current Status
- ✅ Firebase files configured
- ✅ Android ready to run
- ⏳ iOS needs build script in Xcode (5 minutes)
- 🚀 Ready to test auth flows!
