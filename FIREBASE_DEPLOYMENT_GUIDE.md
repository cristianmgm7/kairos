# Firebase Deployment Guide

Quick reference for deploying Firebase resources to different environments.

## Environments

- **Development**: `kairos-develop`
- **Staging**: `kairos-staging-dbd31`
- **Production**: `kairos-prod-19461`

## Quick Deploy Scripts

### Interactive Deployment (Recommended)

Deploy functions, rules, and indexes interactively:

```bash
./scripts/deploy_firebase.sh
```

This script will guide you through:
1. Selecting the environment (develop/staging/production)
2. Choosing what to deploy (everything, functions only, rules only, etc.)
3. Confirming production deployments

### Deploy Functions Only

```bash
./scripts/deploy_functions.sh
```

## Manual Deployment Commands

### Deploy Everything

```bash
# Staging
firebase deploy --project staging

# Production
firebase deploy --project production
```

### Deploy Specific Resources

#### Functions Only
```bash
firebase deploy --only functions --project staging
firebase deploy --only functions --project production
```

#### Firestore Rules Only
```bash
firebase deploy --only firestore:rules --project staging
firebase deploy --only firestore:rules --project production
```

#### Firestore Indexes Only
```bash
firebase deploy --only firestore:indexes --project staging
firebase deploy --only firestore:indexes --project production
```

#### Storage Rules Only
```bash
firebase deploy --only storage --project staging
firebase deploy --only storage --project production
```

#### Multiple Resources
```bash
# Deploy rules and indexes (no functions)
firebase deploy --only firestore,storage --project staging
```

## Pre-Deployment Checklist

### For Staging
- [ ] Test changes in development environment first
- [ ] Review function code changes
- [ ] Review rule changes (especially security implications)
- [ ] Notify team if major changes

### For Production
- [ ] ✅ Successfully deployed to staging
- [ ] ✅ Tested in staging environment
- [ ] ✅ Review all changes carefully
- [ ] ✅ Backup current production rules (if needed)
- [ ] ✅ Team notification sent
- [ ] ✅ Ready to monitor for issues

## Post-Deployment

### Monitoring

```bash
# View function logs
firebase functions:log --project staging
firebase functions:log --project production

# Tail logs (live)
firebase functions:log --project staging --tail
```

### Firebase Console
- **Staging**: https://console.firebase.google.com/project/kairos-staging-dbd31
- **Production**: https://console.firebase.google.com/project/kairos-prod-19461

### Testing

After deployment, test with the corresponding app flavor:

```bash
# Test with staging
flutter run --flavor staging --dart-define-from-file=.env.staging

# Test with production
flutter run --flavor production --dart-define-from-file=.env.prod
```

## Common Issues

### Functions not updating
```bash
# Clear functions cache and redeploy
cd functions
rm -rf node_modules lib
npm install
npm run build
cd ..
firebase deploy --only functions --project staging
```

### Rules validation error
```bash
# Test rules locally before deploying
firebase emulators:start --only firestore
```

### Index not created
- Indexes can take 5-15 minutes to build
- Check Firebase Console → Firestore → Indexes
- You may need to create custom indexes based on error messages in the app

## Emergency Rollback

If you need to rollback a deployment:

### Rules Rollback
1. Go to Firebase Console → Firestore → Rules
2. Click "Rules history"
3. Select previous version
4. Click "Publish"

### Functions Rollback
```bash
# Redeploy previous version from git
git checkout <previous-commit>
firebase deploy --only functions --project production
git checkout develop
```

## Environment Variables

Functions automatically load environment variables from:
- `.env.develop` (for develop project)
- `.env.staging` (for staging project)
- `.env.production` (for production project)

These files are in the project root and loaded via `--dart-define-from-file` during Flutter builds.

## Tips

1. **Always deploy to staging first** before production
2. **Use the interactive script** (`deploy_firebase.sh`) to avoid mistakes
3. **Monitor logs** immediately after production deployments
4. **Test critical paths** in the app after deploying
5. **Keep rules restrictive** - only allow what's necessary
6. **Document major changes** in commit messages

## Quick Commands Reference

```bash
# View all Firebase projects
firebase projects:list

# Switch project
firebase use develop
firebase use staging
firebase use production

# Check current project
firebase projects:list

# Deploy everything to staging
firebase deploy --project staging

# Deploy everything to production
firebase deploy --project production
```

