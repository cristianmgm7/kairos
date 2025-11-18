#!/bin/bash

# Deploy Firebase Functions Script
# Deploys functions to development, staging, or production

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
FUNCTIONS_DIR="$PROJECT_DIR/functions"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Firebase Functions Deployment${NC}"
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
echo "  4) All environments"
echo ""
read -p "Enter choice (1-4): " -n 1 -r ENV_CHOICE
echo ""
echo ""

case $ENV_CHOICE in
    1)
        DEPLOY_ENV="develop"
        ;;
    2)
        DEPLOY_ENV="staging"
        ;;
    3)
        DEPLOY_ENV="production"
        ;;
    4)
        DEPLOY_ENV="all"
        ;;
    *)
        echo -e "${RED}✗ Invalid choice${NC}"
        exit 1
        ;;
esac

# Confirmation for production
if [ "$DEPLOY_ENV" == "production" ] || [ "$DEPLOY_ENV" == "all" ]; then
    echo -e "${YELLOW}⚠️  WARNING: You are about to deploy to PRODUCTION${NC}"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
fi

# Build functions
echo -e "${BLUE}[1/3] Building TypeScript functions...${NC}"
cd "$FUNCTIONS_DIR"

if ! npm run build; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Build complete"
echo ""

# Deploy functions
deploy_to_env() {
    local env=$1
    echo -e "${BLUE}[2/3] Deploying to ${env}...${NC}"
    
    # Switch to environment
    firebase use "$env"
    
    # Deploy
    if firebase deploy --only functions; then
        echo -e "${GREEN}✓${NC} Successfully deployed to ${env}"
        echo ""
        return 0
    else
        echo -e "${RED}✗${NC} Deployment to ${env} failed"
        echo ""
        return 1
    fi
}

# Deploy based on selection
if [ "$DEPLOY_ENV" == "all" ]; then
    echo -e "${BLUE}[2/3] Deploying to all environments...${NC}"
    echo ""
    
    FAILED=0
    for env in "${ENVIRONMENTS[@]}"; do
        if ! deploy_to_env "$env"; then
            FAILED=1
        fi
    done
    
    if [ $FAILED -eq 1 ]; then
        echo -e "${RED}✗ Some deployments failed${NC}"
        exit 1
    fi
else
    deploy_to_env "$DEPLOY_ENV"
fi

# Summary
echo -e "${BLUE}[3/3] Deployment Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

if [ "$DEPLOY_ENV" == "all" ]; then
    echo -e "${GREEN}✓${NC} Deployed to: develop, staging, production"
else
    echo -e "${GREEN}✓${NC} Deployed to: $DEPLOY_ENV"
fi

echo ""
echo -e "${BLUE}Deployed Functions:${NC}"
echo "  • transcribeAudioMessage"
echo "  • analyzeImageMessage"
echo "  • generateMessageResponse"
echo "  • generatePeriodInsight"
echo "  • generateInsight"
echo "  • generateDailyInsights"
echo "  • onThreadDeleted"
echo ""

# View logs prompt
echo -e "${YELLOW}Next Steps:${NC}"
echo "  • Monitor logs: npm run logs:${DEPLOY_ENV}"
echo "  • Test functions in your app"
echo "  • Check Firebase Console for metrics"
echo ""

if [ "$DEPLOY_ENV" == "production" ] || [ "$DEPLOY_ENV" == "all" ]; then
    echo -e "${YELLOW}⚠️  Production Reminders:${NC}"
    echo "  • Monitor logs for errors"
    echo "  • Test critical functions immediately"
    echo "  • Alert team of deployment"
    echo ""
fi

# Ask if user wants to view logs
if [ "$DEPLOY_ENV" != "all" ]; then
    read -p "View logs now? (y/n): " -n 1 -r SHOW_LOGS
    echo ""
    
    if [[ $SHOW_LOGS =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Showing logs for ${DEPLOY_ENV}...${NC}"
        echo -e "${BLUE}Press Ctrl+C to exit${NC}"
        echo ""
        firebase use "$DEPLOY_ENV"
        firebase functions:log
    fi
fi

echo -e "${GREEN}Deployment complete! 🎉${NC}"
echo ""

