# TestFlight Upload Guide for Kairos App

## Prerequisites Checklist
- [ ] Active Apple Developer account
- [ ] App ID created in Apple Developer Portal
- [ ] Distribution certificate installed
- [ ] App Store provisioning profile created
- [ ] App created in App Store Connect
- [ ] Xcode installed and up to date
- [ ] Transporter app installed

## Your App Configuration

**App Name:** Kairos  
**Bundle Identifiers:**
- Production: `com.kairos-app.prod`
- Staging: `com.kairos-app.staging`
- Development: `com.kairos-app.dev`

**Current Version:** 1.0.0 (Build 1)  
**Development Team:** 46GH5N7V96

## Step 1: Apple Developer Portal Setup

### 1.1 Create/Verify App ID
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. Click **"+"** to create a new identifier
4. Select **"App IDs"** → **"App"**
5. Fill in:
   - **Description:** Kairos Production
   - **Bundle ID:** `com.kairos-app.prod` (Explicit)
6. Enable capabilities:
   - ✅ Push Notifications (required for Firebase)
   - ✅ Sign in with Apple (if using Google Sign-In)
   - ✅ Associated Domains (if needed)
7. Click **"Continue"** → **"Register"**

### 1.2 Create Distribution Certificate (if needed)
1. Go to **Certificates** section
2. Click **"+"** → Select **"Apple Distribution"**
3. Follow instructions to create a Certificate Signing Request (CSR)
4. Upload CSR and download certificate
5. Double-click to install in **Keychain Access**

### 1.3 Create App Store Provisioning Profile
1. Go to **Profiles** section
2. Click **"+"** → Select **"App Store"** under Distribution
3. Select your App ID: `com.kairos-app.prod`
4. Select your Distribution certificate
5. Name it: `Kairos Production App Store`
6. Download and double-click to install in Xcode

## Step 2: App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in the form:
   - **Platforms:** ☑️ iOS
   - **Name:** Kairos
   - **Primary Language:** English (or your choice)
   - **Bundle ID:** Select `com.kairos-app.prod`
   - **SKU:** `kairos-prod-001` (any unique identifier)
   - **User Access:** Full Access
4. Click **"Create"**

## Step 3: Prepare and Build in Xcode

### 3.1 Open Project in Xcode
```bash
cd /Users/cristian/Documents/tech/kairos/ios
open Runner.xcworkspace
```

### 3.2 Configure Signing
1. Select **Runner** project in Project Navigator
2. Select **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. For **Release-production** configuration:
   - ✅ Automatically manage signing
   - **Team:** Select your team (46GH5N7V96)
   - **Provisioning Profile:** Should auto-select or choose "Kairos Production App Store"

### 3.3 Select Scheme and Configuration
1. Click on scheme selector (top left, next to play/stop buttons)
2. Select **"Runner"** scheme
3. Click **"Edit Scheme"**
4. Under **"Run"** → Change **"Build Configuration"** to **"Release-production"**
5. Under **"Archive"** → Change **"Build Configuration"** to **"Release-production"**
6. Click **"Close"**

### 3.4 Select Generic iOS Device
1. In the device selector (top bar), select **"Any iOS Device (arm64)"**
   - ⚠️ Do NOT select a simulator or connected device

### 3.5 Clean and Build
1. Menu: **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete

### 3.6 Create Archive
1. Menu: **Product** → **Archive** (⌘B)
2. Wait for build to complete (may take 5-15 minutes)
3. Organizer window should open automatically
4. If not, go to **Window** → **Organizer**

## Step 4: Export IPA

### 4.1 In Xcode Organizer
1. Select your archive (should be at the top with today's date)
2. Click **"Distribute App"** button
3. Select **"App Store Connect"** → **"Next"**
4. Select **"Upload"** → **"Next"**
5. Distribution options:
   - ✅ App Thinning: All compatible device variants
   - ✅ Rebuild from Bitcode: No (already disabled in your project)
   - ✅ Include symbols for your app: Yes
   - ☐ Manage Version and Build Number: Leave unchecked
6. Click **"Next"**
7. Review signing settings → **"Next"**
8. Wait for processing (this validates your app)
9. Click **"Upload"**
10. Wait for upload to complete

**Alternative: Export for Manual Upload**
If you prefer to use Transporter (as you mentioned):
1. In step 3 above, select **"Export"** instead of "Upload"
2. Continue through the options
3. Choose a save location
4. Xcode will create a `.ipa` file

### 4.2 Upload via Transporter (Alternative Method)
1. Open **Transporter** app
2. Click **"+"** or drag and drop your `.ipa` file
3. Click **"Deliver"**
4. Wait for upload and processing

## Step 5: Configure TestFlight in App Store Connect

### 5.1 Wait for Processing
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Select your app (Kairos)
3. Go to **TestFlight** tab
4. Wait for build to appear (can take 5-30 minutes)
5. Status will change from "Processing" → "Ready to Submit" → "Ready to Test"

### 5.2 Add Test Information (First Time Only)
1. Click on your build number
2. Fill in required fields:
   - **What to Test:** Describe what testers should focus on
   - **Export Compliance:** Answer questions about encryption
     - If you use HTTPS only: Select "No" to encryption
     - If you use Firebase: Select "No" (uses standard encryption)
3. Click **"Save"**

### 5.3 Add Internal Testers
1. Go to **TestFlight** → **"Internal Testing"**
2. Default group should exist, or create one
3. Click **"+"** next to testers
4. Add testers (they must have App Store Connect access)
5. Click **"Add"**

### 5.4 Add External Testers (Optional)
1. Go to **TestFlight** → **"External Testing"**
2. Click **"+"** → **"Add Group"**
3. Name the group (e.g., "Beta Testers")
4. Add your build
5. Add testers by email (up to 10,000 testers)
6. Submit for Beta App Review (first time only, 24-48 hours)

## Step 6: Test Distribution

Once build is "Ready to Test":
1. Testers receive email/notification
2. They install TestFlight app from App Store
3. They can install your app through TestFlight
4. You can view crash logs and feedback in App Store Connect

## Quick Command Reference

### Build Archive via Command Line (Alternative to Xcode)
```bash
cd /Users/cristian/Documents/tech/kairos

# Clean
flutter clean
flutter pub get

# Build for iOS production
flutter build ios --release --flavor production --dart-define-from-file=.env.prod

# Or build IPA directly (exports as IPA)
flutter build ipa --release --flavor production --export-options-plist=ios/ExportOptions.plist
```

### Check Current Version
```bash
cd /Users/cristian/Documents/tech/kairos
cat pubspec.yaml | grep version
```

### Update Version Before Building
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # 1.0.1 = version, 2 = build number
```

## Troubleshooting

### Common Issues

**1. "No provisioning profiles found"**
- Ensure you downloaded and installed the provisioning profile
- Try: Xcode → Preferences → Accounts → Download Manual Profiles

**2. "Code signing error"**
- Ensure distribution certificate is installed in Keychain
- Check Team ID matches in Xcode

**3. "Missing compliance"**
- Fill out Export Compliance in App Store Connect → Build → Export Compliance

**4. "Build is invalid"**
- Check minimum iOS deployment target (currently 13.0)
- Ensure all required icons are included
- Check for API usage that requires privacy descriptions

**5. "Upload failed in Transporter"**
- Ensure bundle ID matches App Store Connect
- Check that version/build number is higher than previous uploads
- Try uploading via Xcode instead

### Logs and Validation
```bash
# Validate IPA before upload
xcrun altool --validate-app -f path/to/Kairos.ipa -t ios -u your-apple-id@email.com

# Upload IPA via command line
xcrun altool --upload-app -f path/to/Kairos.ipa -t ios -u your-apple-id@email.com

# Check code signing
codesign -dv --verbose=4 path/to/Runner.app
```

## Important Notes

1. **First build takes longest:** 24-48 hours for Beta App Review
2. **Increment build numbers:** Each upload needs unique build number
3. **TestFlight builds expire after 90 days:** Need to upload new builds
4. **Max 100 builds per version:** Can have builds 1.0.0+1 through 1.0.0+100
5. **External testing requires review:** First time and when adding features

## Next Steps After TestFlight

When ready for App Store release:
1. Complete all App Store information
2. Add screenshots and descriptions
3. Set pricing and availability
4. Submit for App Store Review
5. Usually takes 24-48 hours for review

## Resources

- [Apple TestFlight Documentation](https://developer.apple.com/testflight/)
- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

**Last Updated:** November 2025  
**App Version:** 1.0.0+1  
**Target Environment:** Production (`com.kairos-app.prod`)






