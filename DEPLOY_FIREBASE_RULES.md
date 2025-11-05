# Deploy Firebase Security Rules

## 📋 What I Created

I've created the following files for you:

1. **`firestore.rules`** - Firestore database security rules
2. **`storage.rules`** - Firebase Storage security rules  
3. **`firebase.json`** - Firebase configuration file
4. **`firestore.indexes.json`** - Database indexes for optimal queries

## 🔒 Security Rules Overview

### Firestore Rules
- ✅ Users can only read/write their own profile
- ✅ Users can only access their own journal threads
- ✅ Users can only access messages in their own threads
- ✅ Validates required fields and timestamps
- ✅ Prevents accidental user deletion

### Storage Rules
- ✅ Users can only access files in their own folder: `users/{userId}/journals/`
- ✅ Image uploads limited to 10MB
- ✅ Audio uploads limited to 50MB
- ✅ Only valid image and audio types allowed

## 🚀 How to Deploy

### Option 1: Deploy via Firebase Console (Quick & Easy)

#### For Firestore Rules:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (dev/staging/prod)
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` file
5. Paste into the rules editor
6. Click **Publish**

#### For Storage Rules:
1. In the same Firebase Console
2. Navigate to **Storage** → **Rules** tab
3. Copy the contents of `storage.rules` file
4. Paste into the rules editor
5. Click **Publish**

**Repeat for all 3 Firebase projects** (dev, staging, prod)

### Option 2: Deploy via Firebase CLI (Automated)

#### Step 1: Install Firebase CLI (if not installed)
```bash
npm install -g firebase-tools
```

#### Step 2: Login to Firebase
```bash
firebase login
```

#### Step 3: Initialize Firebase (if needed)
```bash
# This will detect your firebase.json automatically
firebase use --add
```
- Select your **develop** project and alias it as `dev`
- Repeat for staging and prod projects

#### Step 4: Deploy Rules

##### Deploy to Development:
```bash
firebase use dev
firebase deploy --only firestore:rules,storage
```

##### Deploy to Staging:
```bash
firebase use staging
firebase deploy --only firestore:rules,storage
```

##### Deploy to Production:
```bash
firebase use prod
firebase deploy --only firestore:rules,storage
```

#### Deploy Firestore Indexes (important for performance):
```bash
firebase deploy --only firestore:indexes
```

## 🧪 Test Your Rules

After deploying, restart your app and try:

1. **✅ Should work:**
   - Create a journal thread
   - Add messages to your threads
   - Upload images and audio files
   - Read your own data

2. **❌ Should fail (security working):**
   - Try to read another user's data (won't be possible in the app)
   - Upload files larger than limits (won't work)

## 🔍 Verify Deployment

### Check Firestore Rules:
```bash
firebase firestore:rules get
```

### Check Storage Rules:
```bash
firebase storage:rules get
```

## 🎯 Quick Test Checklist

After deploying, test in your app:

- [ ] Create a new journal thread (should work)
- [ ] Add a text message (should work)
- [ ] Record and upload audio message (should work)
- [ ] Take and upload a photo (should work)
- [ ] Check that upload progress shows correctly
- [ ] Verify no permission errors in logs

## ⚠️ Important Notes

### Multiple Environments
You have 3 Firebase projects (dev/staging/prod). You need to:
- Deploy rules to **all 3 projects**
- Each project is independent
- Test on dev first, then staging, then prod

### Current Development
Based on your terminal output, you're running the **develop** flavor, so deploy to your **dev** project first:
```bash
firebase use dev
firebase deploy --only firestore:rules,storage,firestore:indexes
```

### If Errors Persist
If you still see permission errors after deployment:
1. Verify you're signed in with a valid user
2. Check the user's UID matches (log it in your app)
3. Wait 1-2 minutes for rules to propagate
4. Restart your app completely
5. Check Firebase Console → Firestore/Storage → Rules tab to verify they're published

## 📚 Understanding the Rules

### Firestore Rule Structure:
```javascript
match /journal_threads/{threadId} {
  allow read: if resource.data.userId == request.auth.uid;
  // Only read if the thread belongs to the authenticated user
}
```

### Storage Rule Structure:
```javascript
match /users/{userId}/journals/{journalId}/{filename} {
  allow write: if request.auth.uid == userId;
  // Only write to your own user folder
}
```

## 🐛 Troubleshooting

### "Permission denied" still appears:
- Verify rules are published (check Firebase Console)
- Make sure user is authenticated (`request.auth != null`)
- Check that data structure matches rules (userId field exists)

### "Index required" error:
```bash
# Deploy the indexes
firebase deploy --only firestore:indexes
```
Or click the link in the error message to create it via Console.

### Rules take time to update:
- Rules can take 1-2 minutes to propagate
- Restart your app after deploying
- Clear app data if needed

## 🎉 Next Steps

Once deployed and tested:
1. ✅ Mark this task complete
2. 🧪 Test all journal features end-to-end
3. 🚀 Deploy to staging and test there too
4. 📱 Test on both iOS and Android
5. 🔐 Keep rules secure and never open them to public

---

**Need help?** Check the [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)




