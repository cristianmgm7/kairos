# Firebase Functions Multi-Environment Deployment Guide

## 🌍 Your Firebase Environments

You have 3 Firebase projects configured:

| Environment | Project ID | Usage |
|------------|------------|-------|
| **Development** | `kairos-develop` | Local development and testing |
| **Staging** | `kairos-staging` | Pre-production testing |
| **Production** | `kairos-production` | Live app in production |

---

## 🚀 Quick Deployment Commands

### Deploy to Specific Environment

```bash
# Deploy to Development
cd functions
npm run deploy:dev

# Deploy to Staging
npm run deploy:staging

# Deploy to Production
npm run deploy:prod

# Deploy to ALL environments at once
npm run deploy:all
```

---

## 📋 Step-by-Step Deployment Process

### Prerequisites

Before deploying, ensure:

```bash
# 1. You're logged into Firebase CLI
firebase login

# 2. Verify your projects are set up
firebase projects:list

# 3. Check current project
firebase use
```

### Deploy Functions to Development

```bash
# Navigate to functions directory
cd /Users/cristian/Documents/tech/kairos/functions

# Build TypeScript
npm run build

# Deploy to development
npm run deploy:dev

# Or using Firebase CLI directly
firebase use develop
firebase deploy --only functions
```

### Deploy Functions to Staging

```bash
cd /Users/cristian/Documents/tech/kairos/functions

# Build and deploy to staging
npm run deploy:staging

# Or step by step
npm run build
firebase use staging
firebase deploy --only functions
```

### Deploy Functions to Production

```bash
cd /Users/cristian/Documents/tech/kairos/functions

# Build and deploy to production
npm run deploy:prod

# Or step by step
npm run build
firebase use production
firebase deploy --only functions
```

---

## 🔄 Deploy Everything (Functions + Firestore + Storage)

If you want to deploy functions, Firestore rules, and Storage rules together:

### Deploy All to Development
```bash
cd /Users/cristian/Documents/tech/kairos
firebase use develop
firebase deploy
```

### Deploy All to Staging
```bash
firebase use staging
firebase deploy
```

### Deploy All to Production
```bash
firebase use production
firebase deploy
```

### Deploy Specific Services

```bash
# Functions only
firebase deploy --only functions

# Firestore rules and indexes
firebase deploy --only firestore

# Storage rules
firebase deploy --only storage

# Multiple services
firebase deploy --only functions,firestore,storage
```

---

## 📊 Your Deployed Functions

Based on your `functions/src/index.ts`, these functions will be deployed:

### Callable Functions (Client-Side)
- ✅ `transcribeAudioMessage` - Transcribe audio to text
- ✅ `analyzeImageMessage` - Analyze images with AI
- ✅ `generateMessageResponse` - Generate AI responses
- ✅ `generatePeriodInsight` - Generate insights for time periods

### Trigger Functions (Automatic)
- ✅ `generateInsight` - Auto-generate insights
- ✅ `generateDailyInsights` - Scheduled daily insights
- ✅ `onThreadDeleted` - Cleanup when threads deleted

---

## 🔍 Monitoring & Logs

### View Logs

```bash
# Development logs
npm run logs:dev

# Staging logs
npm run logs:staging

# Production logs
npm run logs:prod

# Or using Firebase CLI
firebase use develop
firebase functions:log

# Follow logs in real-time
firebase functions:log --only transcribeAudioMessage
```

### Firebase Console

Monitor your functions in the Firebase Console:
- **Development**: https://console.firebase.google.com/project/kairos-develop/functions
- **Staging**: https://console.firebase.google.com/project/kairos-staging/functions
- **Production**: https://console.firebase.google.com/project/kairos-production/functions

---

## ⚙️ Environment-Specific Configuration

### Using Environment Variables

If you need different configurations per environment:

**Option 1: Firebase Functions Config (Deprecated but still works)**
```bash
# Set config for development
firebase use develop
firebase functions:config:set api.key="dev-key-123"

# Set config for staging
firebase use staging
firebase functions:config:set api.key="staging-key-456"

# Set config for production
firebase use production
firebase functions:config:set api.key="prod-key-789"

# In your code
const apiKey = functions.config().api.key;
```

**Option 2: Environment Variables (Recommended)**

Create `.env` files in the functions directory:

```bash
# functions/.env.develop
API_KEY=dev-key-123
ENVIRONMENT=development

# functions/.env.staging
API_KEY=staging-key-456
ENVIRONMENT=staging

# functions/.env.production
API_KEY=prod-key-789
ENVIRONMENT=production
```

Then load in your code:
```typescript
import * as dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.ENVIRONMENT}` });
```

**Option 3: Use Firebase Project ID**

Automatically detect environment:
```typescript
import * as admin from 'firebase-admin';

const projectId = admin.instanceId().app.options.projectId;

if (projectId === 'kairos-develop') {
  // Development config
} else if (projectId === 'kairos-staging') {
  // Staging config
} else if (projectId === 'kairos-production') {
  // Production config
}
```

---

## 🔐 Firestore Rules & Indexes

Your Firestore rules and indexes are defined in:
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Query indexes

### Deploy Rules to All Environments

```bash
# Deploy to development
firebase use develop
firebase deploy --only firestore

# Deploy to staging
firebase use staging
firebase deploy --only firestore

# Deploy to production
firebase use production
firebase deploy --only firestore
```

**Important:** The same rules will be deployed to all environments. Make sure your rules work across all environments!

---

## 📦 Storage Rules

Your Storage rules are in `storage.rules`.

### Deploy Storage Rules

```bash
# Deploy to specific environment
firebase use develop
firebase deploy --only storage

firebase use staging
firebase deploy --only storage

firebase use production
firebase deploy --only storage
```

---

## 🚨 Production Deployment Checklist

Before deploying to production:

```
□ All tests pass
   npm run test

□ Functions build successfully
   npm run build

□ Tested in development
   firebase use develop
   firebase deploy --only functions

□ Tested in staging
   firebase use staging
   firebase deploy --only functions

□ Reviewed code changes
   git diff

□ Version bumped (if applicable)

□ Team notified

□ Ready to deploy to production
   firebase use production
   firebase deploy --only functions

□ Monitor logs after deployment
   firebase functions:log

□ Test critical functions in production
```

---

## 🔄 Rollback Strategy

If something goes wrong in production:

### Option 1: Redeploy Previous Version

```bash
# If you have the previous code in git
git checkout <previous-commit>
cd functions
npm run build
firebase use production
firebase deploy --only functions

# Then return to latest
git checkout main
```

### Option 2: Quick Fix and Redeploy

```bash
# Fix the issue in code
# ... make changes ...

cd functions
npm run build
firebase use production
firebase deploy --only functions
```

### Option 3: Disable Problematic Function

Temporarily comment out the function in `functions/src/index.ts` and redeploy.

---

## 📊 Deployment Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   DEPLOYMENT WORKFLOW                       │
└─────────────────────────────────────────────────────────────┘

    Local Development
          │
          ├─► Write/Update Functions
          ├─► Test Locally (Emulator)
          │   $ npm run serve
          │
          ▼
    Deploy to DEVELOPMENT
          │
          ├─► $ npm run deploy:dev
          ├─► Test with dev app
          ├─► Review logs
          │
          ▼
    Deploy to STAGING
          │
          ├─► $ npm run deploy:staging
          ├─► QA Testing
          ├─► Team Review
          │
          ▼
    Deploy to PRODUCTION
          │
          ├─► $ npm run deploy:prod
          ├─► Monitor Logs
          ├─► Test Critical Functions
          └─► Ready for Users! 🎉
```

---

## 🛠️ Useful Commands Reference

```bash
# Switch between environments
firebase use develop
firebase use staging
firebase use production

# Check current environment
firebase use

# List all projects
firebase projects:list

# Deploy specific function
firebase deploy --only functions:generateMessageResponse

# Deploy with predeploy hooks skipped (not recommended)
firebase deploy --only functions --force

# View function details
firebase functions:list

# Delete a function
firebase functions:delete functionName

# View function config
firebase functions:config:get
```

---

## 🧪 Testing Before Deployment

### Local Testing with Emulator

```bash
cd functions

# Start emulator
npm run serve

# Test your functions locally at:
# http://localhost:5001/kairos-develop/us-central1/functionName
```

### Unit Tests

```bash
cd functions

# Run tests
npm run test

# Watch mode
npm run test:watch
```

---

## 🔔 CI/CD Integration

You can automate deployment with GitHub Actions or other CI/CD:

### Example GitHub Action (create `.github/workflows/deploy-functions.yml`)

```yaml
name: Deploy Firebase Functions

on:
  push:
    branches:
      - develop  # Auto-deploy develop to dev
      - staging  # Auto-deploy staging to staging
      - main     # Auto-deploy main to production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: |
          cd functions
          npm ci
      
      - name: Build functions
        run: |
          cd functions
          npm run build
      
      - name: Deploy to Firebase
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: |
          npm install -g firebase-tools
          if [ "${{ github.ref }}" == "refs/heads/develop" ]; then
            firebase use develop
          elif [ "${{ github.ref }}" == "refs/heads/staging" ]; then
            firebase use staging
          elif [ "${{ github.ref }}" == "refs/heads/main" ]; then
            firebase use production
          fi
          firebase deploy --only functions --token "$FIREBASE_TOKEN"
```

---

## 📝 Quick Start Summary

```bash
# 1. Navigate to functions
cd /Users/cristian/Documents/tech/kairos/functions

# 2. Deploy to development
npm run deploy:dev

# 3. Test in your dev app
# ... verify everything works ...

# 4. Deploy to staging
npm run deploy:staging

# 5. Test in staging app
# ... QA testing ...

# 6. Deploy to production
npm run deploy:prod

# 7. Monitor production
npm run logs:prod
```

---

## 🆘 Troubleshooting

### "Project not found"
```bash
# Make sure project exists
firebase projects:list

# Add project alias
firebase use --add
```

### "Permission denied"
```bash
# Re-login to Firebase
firebase login --reauth
```

### "Build failed"
```bash
# Clean and rebuild
cd functions
rm -rf lib
npm run build
```

### "Function not updating"
Sometimes Firebase caches. Clear by:
```bash
firebase deploy --only functions --force
```

---

## 🎯 Best Practices

1. **Always test in development first**
   - Deploy to dev → Test → Deploy to staging → Test → Deploy to prod

2. **Use version control**
   - Tag production deployments: `git tag v1.0.0`
   - Keep track of what's deployed where

3. **Monitor after deployment**
   - Watch logs for errors
   - Test critical paths immediately

4. **Keep environments in sync**
   - Deploy to all environments regularly
   - Keep Firestore rules consistent

5. **Document breaking changes**
   - Update mobile app if function signatures change
   - Coordinate with frontend team

---

## 📚 Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Multi-Project Setup](https://firebase.google.com/docs/projects/multiprojects)

---

**Your Functions are Ready to Deploy! 🚀**

Start with development, test thoroughly, then move to staging and production.


