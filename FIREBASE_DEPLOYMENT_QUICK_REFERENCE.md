# 🚀 Firebase Deployment Quick Reference

Quick commands for deploying Firebase services to different environments.

---

## ⚡ Quick Commands

### Deploy Functions

```bash
# Deploy to Development
cd functions && npm run deploy:dev

# Deploy to Staging
cd functions && npm run deploy:staging

# Deploy to Production
cd functions && npm run deploy:prod

# Deploy to ALL environments
cd functions && npm run deploy:all
```

### Deploy Using Script (Interactive)

```bash
# Run the deployment script
./scripts/deploy_functions.sh

# Follow the prompts to select environment
```

---

## 🗂️ Deploy All Services

### Development
```bash
firebase use develop
firebase deploy
```

### Staging
```bash
firebase use staging
firebase deploy
```

### Production
```bash
firebase use production
firebase deploy
```

---

## 📦 Deploy Specific Services

### Functions Only
```bash
firebase use develop
firebase deploy --only functions
```

### Firestore Rules & Indexes
```bash
firebase use develop
firebase deploy --only firestore
```

### Storage Rules
```bash
firebase use develop
firebase deploy --only storage
```

### Multiple Services
```bash
firebase use develop
firebase deploy --only functions,firestore,storage
```

---

## 🔍 View Logs

### From functions directory
```bash
cd functions
npm run logs:dev      # Development
npm run logs:staging  # Staging
npm run logs:prod     # Production
```

### Using Firebase CLI
```bash
firebase use develop
firebase functions:log

# Specific function
firebase functions:log --only generateMessageResponse

# Real-time
firebase functions:log --follow
```

---

## 🔄 Switch Environments

```bash
# Switch to development
firebase use develop

# Switch to staging
firebase use staging

# Switch to production
firebase use production

# Check current environment
firebase use
```

---

## 📊 Your Firebase Projects

| Environment | Project ID | Command |
|------------|------------|---------|
| Development | kairos-develop | `firebase use develop` |
| Staging | kairos-staging-dbd31 | `firebase use staging` |
| Production | kairos-prod-19461 | `firebase use production` |

---

## 🎯 Typical Deployment Flow

```bash
# 1. Test locally
cd functions
npm run serve

# 2. Deploy to development
npm run deploy:dev

# 3. Test in dev app
# ... verify everything works ...

# 4. Deploy to staging
npm run deploy:staging

# 5. QA testing in staging
# ... team testing ...

# 6. Deploy to production
npm run deploy:prod

# 7. Monitor production
npm run logs:prod
```

---

## ⚠️ Before Production Deployment

```bash
# Run tests
cd functions
npm run test

# Build successfully
npm run build

# Deploy to dev first
npm run deploy:dev

# Deploy to staging
npm run deploy:staging

# Finally deploy to production
npm run deploy:prod
```

---

## 🆘 Troubleshooting

### Re-login to Firebase
```bash
firebase login --reauth
```

### List all projects
```bash
firebase projects:list
```

### Clean and rebuild functions
```bash
cd functions
rm -rf lib node_modules
npm install
npm run build
```

### Force deploy (if cached)
```bash
firebase deploy --only functions --force
```

---

## 📚 Deployed Functions

Your app has these functions deployed:

**Callable Functions (Client → Server)**
- `transcribeAudioMessage` - Audio transcription
- `analyzeImageMessage` - Image analysis
- `generateMessageResponse` - AI response generation
- `generatePeriodInsight` - Period insights

**Trigger Functions (Automatic)**
- `generateInsight` - Auto insights
- `generateDailyInsights` - Scheduled daily
- `onThreadDeleted` - Cleanup on delete

---

## 🔗 Firebase Console Links

- **Development**: https://console.firebase.google.com/project/kairos-develop
- **Staging**: https://console.firebase.google.com/project/kairos-staging-dbd31
- **Production**: https://console.firebase.google.com/project/kairos-prod-19461

---

## 💡 Pro Tips

1. **Always test in dev first** before deploying to staging/prod
2. **Monitor logs** after each deployment
3. **Use the script** for safer deployments: `./scripts/deploy_functions.sh`
4. **Keep environments in sync** by deploying to all regularly
5. **Tag production releases** in git for easy rollback

---

**Need detailed instructions?** See `DEPLOY_FIREBASE_FUNCTIONS.md`

