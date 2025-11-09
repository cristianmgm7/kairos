#!/bin/bash

# Fix Cloud Functions Permissions for Audio Transcription
# This script grants the necessary IAM permissions for the Cloud Functions service account

PROJECT_ID="kairos-develop"
SERVICE_ACCOUNT="854546904017-compute@developer.gserviceaccount.com"
SECRET_NAME="GEMINI_API_KEY"

echo "🔧 Fixing Cloud Functions permissions..."
echo ""

# 1. Grant Service Account Token Creator role (for signing URLs)
echo "1️⃣ Granting Service Account Token Creator role..."
gcloud iam service-accounts add-iam-policy-binding \
  "$SERVICE_ACCOUNT" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project="$PROJECT_ID"

if [ $? -eq 0 ]; then
  echo "✅ Service Account Token Creator role granted"
else
  echo "❌ Failed to grant Service Account Token Creator role"
fi

echo ""

# 2. Grant Secret Manager Secret Accessor role
echo "2️⃣ Granting Secret Manager Secret Accessor role..."
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project="$PROJECT_ID"

if [ $? -eq 0 ]; then
  echo "✅ Secret Manager Secret Accessor role granted"
else
  echo "❌ Failed to grant Secret Manager Secret Accessor role"
fi

echo ""

# 3. Grant Storage Object Viewer role (for reading audio files)
echo "3️⃣ Granting Storage Object Viewer role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectViewer"

if [ $? -eq 0 ]; then
  echo "✅ Storage Object Viewer role granted"
else
  echo "❌ Failed to grant Storage Object Viewer role"
fi

echo ""
echo "🎉 Permission fixes complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Wait 1-2 minutes for IAM changes to propagate"
echo "   2. Try uploading an audio message again"
echo "   3. Check Firebase Console logs for success"
echo ""
