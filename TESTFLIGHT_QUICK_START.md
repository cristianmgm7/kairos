# TestFlight Quick Start Guide

## 🚀 Getting Your App to TestFlight in 3 Steps

### Prerequisites
✅ Active Apple Developer account  
✅ Xcode installed  
✅ Transporter app installed (optional)

---

## Option 1: Quick Script Method (Easiest)

### Step 1: Run the build script
```bash
cd /Users/cristian/Documents/tech/kairos
./scripts/build_for_testflight.sh
```

The script will:
- Clean and prepare your project
- Ask if you want to increment the build number
- Build your app for production
- Create an IPA file ready for upload

### Step 2: Upload via Transporter
1. Open **Transporter** app
2. Drag and drop the generated IPA file
3. Click **"Deliver"**
4. Wait for upload to complete ✓

### Step 3: Configure in App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Select your **Kairos** app → **TestFlight** tab
3. Wait for build to appear (~10-30 minutes)
4. Fill in **"What to Test"** notes
5. Complete **Export Compliance** questions
6. Add your **testers**
7. Done! 🎉

---

## Option 2: Xcode Method (Traditional)

### Step 1: Open in Xcode
```bash
cd /Users/cristian/Documents/tech/kairos/ios
open Runner.xcworkspace
```

### Step 2: Configure and Archive
1. Select device: **"Any iOS Device (arm64)"**
2. Select scheme: **"Runner"**
3. Edit Scheme → Set configuration to **"Release-production"**
4. Menu: **Product** → **Clean Build Folder**
5. Menu: **Product** → **Archive**
6. Wait for build (~10-15 minutes)

### Step 3: Upload
1. In Organizer: Click **"Distribute App"**
2. Select **"App Store Connect"** → **"Upload"**
3. Follow the prompts
4. Wait for upload to complete ✓

### Step 4: Configure TestFlight
(Same as Option 1, Step 3)

---

## First Time Setup Required

### 1. Apple Developer Portal
Create these at [developer.apple.com](https://developer.apple.com):
- ✅ App ID: `com.kairos-app.prod`
- ✅ Distribution Certificate
- ✅ App Store Provisioning Profile

### 2. App Store Connect
Create app at [appstoreconnect.apple.com](https://appstoreconnect.apple.com):
- ✅ New App with bundle ID: `com.kairos-app.prod`
- ✅ Set SKU (any unique ID like `kairos-prod-001`)

📚 **Need detailed instructions?** See `TESTFLIGHT_UPLOAD_GUIDE.md`

---

## Important Things to Know

### Version Numbers
- Current version: **1.0.0+1**
- Format: `version+buildNumber`
- Each upload needs a unique build number
- Example progression: 1.0.0+1 → 1.0.0+2 → 1.0.0+3

### Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+2  # Increment the +X number for each upload
```

### Build Configurations
Your app has 3 flavors:
- 🔴 **Production**: `com.kairos-app.prod` ← Use this for TestFlight
- 🟡 **Staging**: `com.kairos-app.staging`
- 🟢 **Development**: `com.kairos-app.dev`

### Timeline
| Phase | Time |
|-------|------|
| First-time Apple setup | 30-60 min |
| Build + Upload | 15-30 min |
| Processing in App Store Connect | 5-30 min |
| **Internal Testing** | ✅ Ready immediately |
| **External Testing** (first time) | 24-48 hours (review) |

---

## Troubleshooting

### Build fails?
```bash
cd /Users/cristian/Documents/tech/kairos
flutter clean
flutter pub get
rm -rf ios/Pods
cd ios && pod install && cd ..
```

### Upload rejected?
- Check bundle ID matches: `com.kairos-app.prod`
- Increment build number in `pubspec.yaml`
- Verify distribution certificate is valid

### Build doesn't appear in App Store Connect?
- Wait 30 minutes (can be slow)
- Check email for error messages
- Verify upload completed successfully

---

## Quick Commands Reference

```bash
# Navigate to project
cd /Users/cristian/Documents/tech/kairos

# Check current version
grep version pubspec.yaml

# Run build script
./scripts/build_for_testflight.sh

# Or build manually
flutter build ipa --release --flavor production

# Open in Xcode
open ios/Runner.xcworkspace

# Clean everything
flutter clean && flutter pub get
```

---

## File Resources You Have

| File | Purpose |
|------|---------|
| `TESTFLIGHT_QUICK_START.md` | This file - quick overview |
| `TESTFLIGHT_UPLOAD_GUIDE.md` | Detailed step-by-step guide |
| `TESTFLIGHT_CHECKLIST.md` | Checkbox checklist |
| `scripts/build_for_testflight.sh` | Automated build script |
| `ios/ExportOptions.plist` | Export configuration |

---

## Getting Help

### Documentation
- 📖 Full guide: `TESTFLIGHT_UPLOAD_GUIDE.md`
- ✅ Checklist: `TESTFLIGHT_CHECKLIST.md`
- 🍎 [Apple TestFlight Docs](https://developer.apple.com/testflight/)
- 📱 [Flutter iOS Deploy](https://docs.flutter.dev/deployment/ios)

### Your App Details
- **App Name**: Kairos
- **Bundle ID**: com.kairos-app.prod
- **Team ID**: 46GH5N7V96
- **Current Version**: 1.0.0+1
- **Min iOS**: 13.0

---

## Next Steps After TestFlight

Once your app is tested and ready:
1. Complete App Store listing (screenshots, description, etc.)
2. Submit for App Store Review
3. Set pricing and availability
4. Release to the App Store! 🎉

---

**Good luck with your TestFlight upload! 🚀**

If you run into issues, check the detailed guide or refer to Apple's documentation.


