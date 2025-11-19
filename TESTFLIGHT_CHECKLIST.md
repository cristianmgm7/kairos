# TestFlight Upload Checklist

## Before You Start

### One-Time Setup (if not done)
- [ ] Apple Developer Account is active and paid
- [ ] Added to development team: 46GH5N7V96
- [ ] Xcode installed (latest stable version)
- [ ] Transporter app installed (from Mac App Store)

### Apple Developer Portal (developer.apple.com)
- [ ] App ID created for `com.kairos-app.prod`
- [ ] Distribution Certificate installed in Keychain
- [ ] App Store Provisioning Profile created and downloaded
- [ ] Push Notifications capability enabled (for Firebase)

### App Store Connect (appstoreconnect.apple.com)
- [ ] App created with name "Kairos"
- [ ] Bundle ID `com.kairos-app.prod` selected
- [ ] SKU set (e.g., `kairos-prod-001`)

## Build and Upload Process

### 1. Prepare Code
- [ ] All changes committed to git (optional but recommended)
- [ ] Version number updated in `pubspec.yaml` if needed
  - Current: `version: 1.0.0+1`
  - Each upload needs unique build number (the +1 part)
- [ ] Test the production flavor locally:
  ```bash
  flutter run --flavor production --dart-define-from-file=.env.prod
  ```

### 2. Open in Xcode
- [ ] Navigate to: `/Users/cristian/Documents/tech/kairos/ios`
- [ ] Open `Runner.xcworkspace` (NOT Runner.xcodeproj)
- [ ] Wait for indexing to complete

### 3. Configure Xcode
- [ ] Scheme: "Runner" selected
- [ ] Device: "Any iOS Device (arm64)" selected (NOT simulator)
- [ ] Build Configuration: "Release-production"
  - Edit Scheme → Run → Build Configuration → Release-production
  - Edit Scheme → Archive → Build Configuration → Release-production
- [ ] Signing & Capabilities:
  - [ ] Team: 46GH5N7V96 selected
  - [ ] Automatically manage signing: ✅
  - [ ] No signing errors shown

### 4. Build Archive
- [ ] Product → Clean Build Folder (⇧⌘K)
- [ ] Product → Archive
- [ ] Wait for build to complete (5-15 minutes)
- [ ] Organizer window opens automatically
- [ ] Archive appears at top with today's date

### 5. Export/Upload

#### Option A: Upload via Xcode (Recommended)
- [ ] Click "Distribute App"
- [ ] Select "App Store Connect" → Next
- [ ] Select "Upload" → Next
- [ ] Distribution options:
  - [ ] App Thinning: All compatible device variants
  - [ ] Include symbols: ✅
- [ ] Click Next → Next → Upload
- [ ] Wait for upload to complete
- [ ] Success message appears

#### Option B: Export for Transporter
- [ ] Click "Distribute App"
- [ ] Select "App Store Connect" → Next
- [ ] Select "Export" → Next
- [ ] Choose save location
- [ ] IPA file created
- [ ] Open Transporter app
- [ ] Drag and drop IPA file
- [ ] Click "Deliver"
- [ ] Wait for upload to complete

### 6. App Store Connect Configuration
- [ ] Go to appstoreconnect.apple.com
- [ ] Select "Kairos" app
- [ ] Go to TestFlight tab
- [ ] Wait for build to appear (5-30 minutes)
- [ ] Build status: "Processing" → "Ready to Submit"
- [ ] Click on build number
- [ ] Fill in "What to Test" (testing notes)
- [ ] Complete Export Compliance:
  - [ ] Does your app use encryption? → No (if only using HTTPS)
  - [ ] Or: Yes → Standard encryption only
- [ ] Save

### 7. Add Testers

#### Internal Testers (recommended to start)
- [ ] TestFlight → Internal Testing
- [ ] Click "+" to add testers
- [ ] Add email addresses of testers
- [ ] Testers must have App Store Connect access
- [ ] Save
- [ ] Testers receive email/notification immediately

#### External Testers (optional)
- [ ] TestFlight → External Testing
- [ ] Create new group (e.g., "Beta Testers")
- [ ] Add build to group
- [ ] Add tester emails (up to 10,000)
- [ ] Submit for Beta App Review (first time)
- [ ] Wait 24-48 hours for approval
- [ ] Testers receive invitation

### 8. Verify Distribution
- [ ] Check email for build processing confirmation
- [ ] Verify build shows in TestFlight
- [ ] Install TestFlight app on your device
- [ ] Open invite link and test installation
- [ ] Verify app launches and works correctly

## Post-Upload

### For Next Upload
- [ ] Increment build number in `pubspec.yaml`
  - Example: `1.0.0+1` → `1.0.0+2`
- [ ] Or increment version: `1.0.0+1` → `1.0.1+1`
- [ ] Repeat build and upload process

### Monitoring
- [ ] Check TestFlight → Builds for install metrics
- [ ] Check TestFlight → Crashes for any issues
- [ ] Review feedback from testers
- [ ] Check Xcode Organizer → Crashes for detailed logs

## Common Issues Checklist

If upload fails:
- [ ] Bundle ID matches: `com.kairos-app.prod`
- [ ] Build number is higher than previous upload
- [ ] Distribution certificate is valid (not expired)
- [ ] Provisioning profile includes your certificate
- [ ] No code signing errors in Xcode
- [ ] All required capabilities enabled in App ID
- [ ] Info.plist has all required permissions (Camera, Photos, Microphone)

If build doesn't appear in App Store Connect:
- [ ] Wait 30 minutes (processing can be slow)
- [ ] Check email for any error messages from Apple
- [ ] Verify upload completed successfully
- [ ] Check App Store Connect → Activity tab for status

If TestFlight install fails:
- [ ] Device iOS version meets minimum (iOS 13.0+)
- [ ] Tester has accepted invitation
- [ ] Tester has TestFlight app installed
- [ ] Build is not expired (90 day limit)
- [ ] Export Compliance is complete

## Quick Commands Reference

```bash
# Check current directory
pwd

# Navigate to project
cd /Users/cristian/Documents/tech/kairos

# Check current version
grep version pubspec.yaml

# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Build IPA via command line (alternative)
flutter build ipa --release --flavor production

# Open Xcode workspace
open ios/Runner.xcworkspace

# Check git status (optional)
git status

# Commit changes before building (optional)
git add .
git commit -m "Prepare for TestFlight build 1.0.0+1"
```

## First Time Upload Timeline

1. **Apple Developer setup**: 30-60 minutes
2. **Build in Xcode**: 10-20 minutes
3. **Upload to App Store Connect**: 5-15 minutes
4. **Processing in App Store Connect**: 5-30 minutes
5. **Beta App Review** (external testers): 24-48 hours

**Total for internal testing**: ~1-2 hours  
**Total for external testing**: ~24-48 hours

## Support Resources

- Full Guide: `TESTFLIGHT_UPLOAD_GUIDE.md`
- Apple TestFlight: https://developer.apple.com/testflight/
- Flutter iOS Deploy: https://docs.flutter.dev/deployment/ios
- App Store Connect: https://appstoreconnect.apple.com

---

**Your Configuration:**
- App Name: Kairos
- Bundle ID: com.kairos-app.prod
- Team ID: 46GH5N7V96
- Current Version: 1.0.0+1





