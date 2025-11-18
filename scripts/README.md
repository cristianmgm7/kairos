# Scripts Directory

This directory contains helpful scripts for building and deploying your Kairos app.

## Available Scripts

### 🚀 build_for_testflight.sh

**Purpose:** Automates the iOS build process for TestFlight distribution.

**Usage:**
```bash
# From project root
./scripts/build_for_testflight.sh

# Or from anywhere
/Users/cristian/Documents/tech/kairos/scripts/build_for_testflight.sh
```

**What it does:**
1. ✅ Cleans Flutter build cache
2. ✅ Gets latest dependencies
3. ✅ Optionally increments build number
4. ✅ Runs code generation (if needed)
5. ✅ Builds iOS app for production flavor
6. ✅ Creates IPA file ready for upload
7. ✅ Provides next steps and file location

**Interactive options:**
- Increment build number (y/n)
- Build IPA for Transporter (option 1)
- Build for Xcode Archive (option 2)
- Open result in Finder or Xcode

**Requirements:**
- Flutter SDK installed
- Xcode installed
- Run from project root or scripts directory
- Production environment file: `.env.prod`

---

### 📝 seed_mock_insights.sh

**Purpose:** Seeds mock insights data for development/testing.

**Usage:**
```bash
./scripts/seed_mock_insights.sh
```

---

### 🚀 deploy_functions.sh

**Purpose:** Interactive deployment of Firebase Functions to multiple environments.

**Usage:**
```bash
# From project root
./scripts/deploy_functions.sh

# Or from anywhere
/Users/cristian/Documents/tech/kairos/scripts/deploy_functions.sh
```

**What it does:**
1. ✅ Verifies Firebase CLI authentication
2. ✅ Prompts for environment selection (dev/staging/prod/all)
3. ✅ Builds TypeScript functions
4. ✅ Confirms before production deployment
5. ✅ Deploys to selected environment(s)
6. ✅ Shows deployment summary
7. ✅ Optionally displays logs

**Interactive options:**
- Deploy to development
- Deploy to staging
- Deploy to production
- Deploy to all environments at once
- View logs after deployment

**Requirements:**
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in to Firebase (`firebase login`)
- Node.js and npm installed

**Environments:**
- Development: kairos-develop
- Staging: kairos-staging-dbd31
- Production: kairos-prod-19461

---

## Creating New Scripts

When adding new scripts to this directory:

1. **Make executable:**
   ```bash
   chmod +x scripts/your_new_script.sh
   ```

2. **Add shebang:**
   ```bash
   #!/bin/bash
   ```

3. **Set error handling:**
   ```bash
   set -e  # Exit on error
   ```

4. **Document in this README**

---

## Script Conventions

- Use bash for cross-platform compatibility
- Add helpful colored output (see build_for_testflight.sh for examples)
- Include error checking and helpful error messages
- Provide clear next steps after completion
- Make scripts idempotent (safe to run multiple times)

---

## Troubleshooting

### Permission Denied
```bash
chmod +x scripts/build_for_testflight.sh
```

### Script not found
```bash
# Make sure you're in the project root
cd /Users/cristian/Documents/tech/kairos
./scripts/build_for_testflight.sh
```

### Flutter command not found
```bash
# Add Flutter to PATH in ~/.zshrc or ~/.bash_profile
export PATH="$PATH:/path/to/flutter/bin"
```

---

## Related Documentation

- TestFlight Quick Start: `../TESTFLIGHT_QUICK_START.md`
- Full Upload Guide: `../TESTFLIGHT_UPLOAD_GUIDE.md`
- Upload Checklist: `../TESTFLIGHT_CHECKLIST.md`

