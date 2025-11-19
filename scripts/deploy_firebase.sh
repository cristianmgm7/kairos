#!/bin/bash

# Deploy Firebase Resources Script
# Deploys functions, Firestore rules, Storage rules, and indexes to any environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENTS=("develop" "staging" "production")
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Firebase Deployment Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}✗ Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi
echo -e "${GREEN}✓${NC} Firebase CLI found"

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${RED}✗ Not logged in to Firebase${NC}"
    echo "Please run: firebase login"
    exit 1
fi
echo -e "${GREEN}✓${NC} Firebase authentication verified"

# Navigate to project directory
cd "$PROJECT_DIR"
echo -e "${GREEN}✓${NC} Project directory: $PROJECT_DIR"
echo ""

# Select environment
echo -e "${YELLOW}Select deployment environment:${NC}"
echo "  1) Development (kairos-develop)"
echo "  2) Staging (kairos-staging-dbd31)"
echo "  3) Production (kairos-prod-19461)"
echo ""
read -p "Enter choice (1-3): " -n 1 -r ENV_CHOICE
echo ""
echo ""

case $ENV_CHOICE in
    1)
        DEPLOY_ENV="develop"
        PROJECT_NAME="kairos-develop"
        ;;
    2)
        DEPLOY_ENV="staging"
        PROJECT_NAME="kairos-staging-dbd31"
        ;;
    3)
        DEPLOY_ENV="production"
        PROJECT_NAME="kairos-prod-19461"
        ;;
    *)
        echo -e "${RED}✗ Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}Selected Environment:${NC} $DEPLOY_ENV ($PROJECT_NAME)"
echo ""

# Select what to deploy
echo -e "${YELLOW}What would you like to deploy?${NC}"
echo "  1) Everything (functions, rules, indexes)"
echo "  2) Functions only"
echo "  3) Firestore rules only"
echo "  4) Firestore indexes only"
echo "  5) Storage rules only"
echo "  6) Rules and indexes (no functions)"
echo ""
read -p "Enter choice (1-6): " -n 1 -r DEPLOY_CHOICE
echo ""
echo ""

case $DEPLOY_CHOICE in
    1)
        DEPLOY_TARGET="all"
        DEPLOY_DESC="everything (functions, rules, indexes)"
        ;;
    2)
        DEPLOY_TARGET="functions"
        DEPLOY_DESC="functions only"
        ;;
    3)
        DEPLOY_TARGET="firestore:rules"
        DEPLOY_DESC="Firestore rules only"
        ;;
    4)
        DEPLOY_TARGET="firestore:indexes"
        DEPLOY_DESC="Firestore indexes only"
        ;;
    5)
        DEPLOY_TARGET="storage"
        DEPLOY_DESC="Storage rules only"
        ;;
    6)
        DEPLOY_TARGET="firestore,storage"
        DEPLOY_DESC="Firestore rules, indexes, and Storage rules"
        ;;
    *)
        echo -e "${RED}✗ Invalid choice${NC}"
        exit 1
        ;;
esac

# Confirmation for production
if [ "$DEPLOY_ENV" == "production" ]; then
    echo -e "${YELLOW}⚠️  WARNING: You are about to deploy to PRODUCTION${NC}"
    echo -e "${YELLOW}   Target: $DEPLOY_DESC${NC}"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
fi

# Deploy
echo -e "${BLUE}[1/2] Deploying $DEPLOY_DESC to $DEPLOY_ENV...${NC}"
echo ""

if [ "$DEPLOY_TARGET" == "all" ]; then
    firebase deploy --project "$DEPLOY_ENV"
else
    firebase deploy --only "$DEPLOY_TARGET" --project "$DEPLOY_ENV"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓${NC} Successfully deployed to $DEPLOY_ENV"
else
    echo ""
    echo -e "${RED}✗${NC} Deployment failed"
    exit 1
fi

# Summary
echo ""
echo -e "${BLUE}[2/2] Deployment Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓${NC} Environment: $DEPLOY_ENV"
echo -e "${GREEN}✓${NC} Project: $PROJECT_NAME"
echo -e "${GREEN}✓${NC} Deployed: $DEPLOY_DESC"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "  • Test in your app with the $DEPLOY_ENV flavor"
echo "  • Check Firebase Console: https://console.firebase.google.com/project/$PROJECT_NAME"
if [[ "$DEPLOY_TARGET" == "all" || "$DEPLOY_TARGET" == "functions" ]]; then
    echo "  • Monitor function logs: firebase functions:log --project $DEPLOY_ENV"
fi
echo ""

if [ "$DEPLOY_ENV" == "production" ]; then
    echo -e "${YELLOW}⚠️  Production Reminders:${NC}"
    echo "  • Monitor for errors in Firebase Console"
    echo "  • Test critical functionality immediately"
    echo "  • Alert team of deployment"
    echo ""
fi

echo -e "${GREEN}Deployment complete! 🎉${NC}"
echo ""

