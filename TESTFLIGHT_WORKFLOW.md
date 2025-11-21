# TestFlight Upload Workflow

This document provides a visual overview of the TestFlight upload process.

---

## 🎯 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     TESTFLIGHT UPLOAD WORKFLOW                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PHASE 1: ONE-TIME SETUP (First Upload Only)                       │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────┐
    │  Apple Developer Portal      │
    │  developer.apple.com         │
    └──────────────────────────────┘
                 │
                 ├─► Create App ID: com.kairos-app.prod
                 ├─► Enable Capabilities (Push, Sign In, etc.)
                 ├─► Create Distribution Certificate
                 └─► Create App Store Provisioning Profile
                          │
                          ▼
    ┌──────────────────────────────┐
    │  App Store Connect           │
    │  appstoreconnect.apple.com   │
    └──────────────────────────────┘
                 │
                 ├─► Create New App
                 ├─► Set Bundle ID: com.kairos-app.prod
                 └─► Set SKU: kairos-prod-001
                          │
                          ▼
    ┌──────────────────────────────┐
    │  Local Machine Setup         │
    └──────────────────────────────┘
                 │
                 ├─► Install Distribution Certificate
                 ├─► Download Provisioning Profile
                 └─► Verify Xcode is up to date
                          │
                          ▼
              ✅ Setup Complete!

┌─────────────────────────────────────────────────────────────────────┐
│  PHASE 2: BUILD & UPLOAD (Every Upload)                            │
└─────────────────────────────────────────────────────────────────────┘

    Choose Your Path:

    ╔═══════════════════════════════════════════════════════════════╗
    ║  PATH A: Automated Script (Easiest)                          ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    1. Run Build Script
       ./scripts/build_for_testflight.sh
              │
              ├─► Clean build cache
              ├─► Update dependencies
              ├─► Increment build number (optional)
              ├─► Run code generation
              └─► Build IPA file
                   │
                   ▼
    2. Upload via Transporter
       • Open Transporter app
       • Drag & drop IPA
       • Click "Deliver"
              │
              ▼
    3. Configure in App Store Connect
       (See Phase 3 below)


    ╔═══════════════════════════════════════════════════════════════╗
    ║  PATH B: Xcode Method (Traditional)                          ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    1. Open Xcode Workspace
       open ios/Runner.xcworkspace
              │
              ├─► Select Device: "Any iOS Device (arm64)"
              ├─► Select Scheme: "Runner"
              └─► Edit Scheme → Release-production
                   │
                   ▼
    2. Create Archive
       Product → Clean Build Folder
       Product → Archive
              │
              ▼
    3. Distribute App
       • Organizer → Distribute App
       • Select: App Store Connect
       • Select: Upload
       • Follow prompts
              │
              ▼
    4. Configure in App Store Connect
       (See Phase 3 below)

┌─────────────────────────────────────────────────────────────────────┐
│  PHASE 3: APP STORE CONNECT CONFIGURATION                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────┐
    │  Wait for Processing         │
    │  (5-30 minutes)              │
    └──────────────────────────────┘
              │
              ▼
    ┌──────────────────────────────┐
    │  Build Appears in            │
    │  App Store Connect           │
    └──────────────────────────────┘
              │
              ├─► Status: "Processing"
              ├─► Status: "Ready to Submit"
              └─► Status: "Ready to Test"
                   │
                   ▼
    ┌──────────────────────────────┐
    │  Complete Build Info         │
    └──────────────────────────────┘
              │
              ├─► "What to Test" notes
              └─► Export Compliance questions
                   │
                   ▼
    ┌──────────────────────────────┐
    │  Add Testers                 │
    └──────────────────────────────┘
              │
              ├─► Internal Testers (immediate)
              │   └─► Add team members with ASC access
              │
              └─► External Testers (24-48hr review)
                  └─► Add up to 10,000 email addresses
                   │
                   ▼
    ┌──────────────────────────────┐
    │  Distribution Complete! 🎉   │
    └──────────────────────────────┘
              │
              ├─► Testers receive email/notification
              ├─► They install TestFlight app
              └─► They can install your app


┌─────────────────────────────────────────────────────────────────────┐
│  PHASE 4: MONITORING & UPDATES                                     │
└─────────────────────────────────────────────────────────────────────┘

    Monitor Your TestFlight Build:
    
    ┌──────────────────────────────┐
    │  App Store Connect           │
    │  → TestFlight Tab            │
    └──────────────────────────────┘
              │
              ├─► View install count
              ├─► Check crash reports
              ├─► Read tester feedback
              └─► Monitor session data
                   │
                   ▼
    Need to Upload New Build?
              │
              ├─► Increment build number in pubspec.yaml
              │   (1.0.0+1 → 1.0.0+2)
              │
              └─► Repeat Phase 2 (Build & Upload)
```

---

## ⏱️ Timeline Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│  FIRST-TIME UPLOAD                                                  │
└─────────────────────────────────────────────────────────────────────┘

Hour 0 ─────────────────────────────────────────────► Hour 2
  │                                                      │
  ├─► Apple Developer Setup (30-60 min)                │
  ├─► Build in Xcode (10-20 min)                       │
  ├─► Upload to ASC (5-15 min)                         │
  └─► Processing (5-30 min)                            │
                                                        ▼
                                            ✅ INTERNAL TESTING
                                               (Ready to test!)

Hour 2 ──────────────────────────────────────────────► Hour 48
  │                                                      │
  └─► Beta App Review (24-48 hours)                    │
                                                        ▼
                                            ✅ EXTERNAL TESTING
                                               (Ready for 10k testers!)

┌─────────────────────────────────────────────────────────────────────┐
│  SUBSEQUENT UPLOADS (After first time)                             │
└─────────────────────────────────────────────────────────────────────┘

0 min ───────────────────────────────────────────────► 45 min
  │                                                      │
  ├─► Build (10-20 min)                                 │
  ├─► Upload (5-15 min)                                 │
  └─► Processing (5-30 min)                             │
                                                        ▼
                                            ✅ READY TO TEST!
                                               (Same testers get update)
```

---

## 🔄 Version & Build Number Flow

```
Initial Version:    1.0.0+1
                      │ │ │ │
                      │ │ │ └─► Build Number (increment for each upload)
                      │ │ └───► Patch Version
                      │ └─────► Minor Version
                      └───────► Major Version

Examples:
  Upload #1:  1.0.0+1  ──► First TestFlight upload
  Upload #2:  1.0.0+2  ──► Bug fix for testers
  Upload #3:  1.0.0+3  ──► Added new feature
  Upload #4:  1.0.1+1  ──► Public release version bump
  Upload #5:  1.0.1+2  ──► Hotfix for 1.0.1
```

**Rules:**
- ✅ Build number MUST increase for each upload to same version
- ✅ Can have up to 100 builds per version (1.0.0+1 through 1.0.0+100)
- ✅ Version can stay same during TestFlight testing
- ✅ Usually bump version when releasing to App Store

---

## 📊 Decision Tree: Choose Your Build Method

```
                    Need to upload to TestFlight?
                              │
                              │
                    ┌─────────┴─────────┐
                    │                   │
              Have used             First time or
           Transporter before?    prefer Xcode GUI?
                    │                   │
                    │                   │
              ┌─────▼─────┐       ┌─────▼─────┐
              │  PATH A:  │       │  PATH B:  │
              │  Script + │       │  Xcode    │
              │ Transporter│       │  Archive  │
              └───────────┘       └───────────┘
                    │                   │
                    ▼                   ▼
            ./scripts/          open Runner.xcworkspace
        build_for_testflight.sh    Product → Archive
                    │                   │
                    │                   │
                    └─────────┬─────────┘
                              │
                              ▼
                    Upload to App Store Connect
                              │
                              ▼
                    Configure in TestFlight
                              │
                              ▼
                         🎉 Done!
```

---

## 🎯 Quick Reference: Key URLs

```
┌─────────────────────────────────────────────────────────────────────┐
│  Important Links                                                    │
└─────────────────────────────────────────────────────────────────────┘

📱 Apple Developer Portal
   https://developer.apple.com
   └─► Certificates, Identifiers & Profiles

🏪 App Store Connect
   https://appstoreconnect.apple.com
   └─► My Apps → TestFlight

📚 Apple TestFlight Documentation
   https://developer.apple.com/testflight/

🐛 Submit Feedback
   https://feedbackassistant.apple.com

📖 Flutter iOS Deployment Guide
   https://docs.flutter.dev/deployment/ios
```

---

## 🚦 Status Indicators

During the upload process, you'll see these statuses:

```
App Store Connect Build Statuses:

  📤 Uploading            → Your IPA is being uploaded
  ⏳ Processing           → Apple is processing your build
  ⚠️  Processing Failed   → Check email for error details
  ✅ Ready to Submit      → Build processed, complete info
  🎯 Ready to Test        → Available for TestFlight!
  ❌ Invalid Binary       → Something wrong, check issues
  🕐 Waiting for Review   → External testing (first time)
  ✅ In Testing          → External testers can install
```

---

## 📋 Pre-Upload Checklist

Before each upload, verify:

```
✅ Code Changes
   ├─► All changes committed (optional but recommended)
   ├─► Tests passing
   └─► No linter errors

✅ Version Number
   ├─► Build number incremented in pubspec.yaml
   └─► Higher than last upload

✅ Certificates & Profiles
   ├─► Distribution certificate valid
   ├─► Provisioning profile not expired
   └─► No signing errors in Xcode

✅ App Configuration
   ├─► Bundle ID: com.kairos-app.prod
   ├─► All required capabilities enabled
   ├─► Info.plist permissions up to date
   └─► Firebase config present (if using)

✅ Build Environment
   ├─► Flutter SDK up to date
   ├─► Xcode up to date
   ├─► CocoaPods up to date (if using)
   └─► No pod install errors
```

---

## 🎓 Learning Resources

```
For First-Time Uploaders:
  1. Read: TESTFLIGHT_QUICK_START.md
  2. Watch: Apple's TestFlight video tutorials
  3. Follow: TESTFLIGHT_CHECKLIST.md

For Detailed Configuration:
  1. Read: TESTFLIGHT_UPLOAD_GUIDE.md
  2. Reference: Apple Developer Documentation
  3. Troubleshoot: Check common issues section

For Automation:
  1. Use: ./scripts/build_for_testflight.sh
  2. Customize: Edit script for your workflow
  3. Integrate: Add to CI/CD pipeline
```

---

## 💡 Pro Tips

```
✨ Speed up future uploads:
   • Save your export options
   • Keep certificates/profiles organized
   • Automate version bumping
   • Use CI/CD for builds

🔧 Avoid common issues:
   • Always increment build number
   • Test on real device before uploading
   • Complete export compliance immediately
   • Keep provisioning profiles updated

📱 Optimize testing:
   • Start with internal testers
   • Get feedback before external testing
   • Use TestFlight feedback feature
   • Monitor crash reports daily

🚀 Prepare for App Store:
   • Test thoroughly in TestFlight
   • Gather screenshots from TestFlight
   • Address all tester feedback
   • Ensure compliance with App Store guidelines
```

---

**Ready to get started? Check out:**
- 📖 `TESTFLIGHT_QUICK_START.md` - Start here!
- 📋 `TESTFLIGHT_CHECKLIST.md` - Step-by-step checklist
- 📚 `TESTFLIGHT_UPLOAD_GUIDE.md` - Complete reference

**Good luck with your upload! 🚀**









