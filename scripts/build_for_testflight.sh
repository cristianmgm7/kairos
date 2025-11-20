#!/bin/bash

# Build for TestFlight Script
# This script helps you build and prepare your iOS app for TestFlight upload

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Kairos iOS TestFlight Build Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Ask user to select flavor
echo -e "${YELLOW}Select build flavor:${NC}"
echo "  1) Development (dev)"
echo "  2) Staging"
echo "  3) Production"
read -p "Choose (1, 2, or 3): " -n 1 -r FLAVOR_CHOICE
echo ""
echo ""

# Configure based on selection
case $FLAVOR_CHOICE in
    1)
        FLAVOR="dev"
        ENV_FILE=".env.dev"
        BUNDLE_ID="com.kairos-app.dev"
        DART_ENTRYPOINT="lib/main_dev.dart"
        echo -e "${GREEN}✓${NC} Selected: Development"
        ;;
    2)
        FLAVOR="staging"
        ENV_FILE=".env.staging"
        BUNDLE_ID="com.kairos-app.staging"
        DART_ENTRYPOINT="lib/main_staging.dart"
        echo -e "${GREEN}✓${NC} Selected: Staging"
        ;;
    3)
        FLAVOR="prod"
        ENV_FILE=".env.prod"
        BUNDLE_ID="com.kairos-app.prod"
        DART_ENTRYPOINT="lib/main_prod.dart"
        echo -e "${GREEN}✓${NC} Selected: Production"
        ;;
    *)
        echo -e "${RED}✗ Invalid selection${NC}"
        exit 1
        ;;
esac

TEAM_ID="46GH5N7V96"
echo ""

# Get project directory (script is in scripts/ subdirectory)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${GREEN}✓${NC} Project directory: $PROJECT_DIR"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}✗ Error: pubspec.yaml not found. Are you in the project root?${NC}"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${BLUE}Current version:${NC} $CURRENT_VERSION"
echo ""

# Ask if user wants to increment build number
echo -e "${YELLOW}Do you want to increment the build number?${NC}"
echo "Current: $CURRENT_VERSION"
read -p "Increment build number? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Extract version and build number
    VERSION_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f1)
    BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    NEW_VERSION="${VERSION_NUMBER}+${NEW_BUILD_NUMBER}"
    
    echo -e "${YELLOW}Updating version to:${NC} $NEW_VERSION"
    
    # Update pubspec.yaml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
    else
        # Linux
        sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
    fi
    
    echo -e "${GREEN}✓${NC} Version updated to $NEW_VERSION"
    echo ""
fi

# Verify environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Error: $ENV_FILE not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Environment file found: $ENV_FILE"

# Step 1: Clean
echo ""
echo -e "${BLUE}[1/5] Cleaning Flutter build...${NC}"
flutter clean
echo -e "${GREEN}✓${NC} Clean complete"

# Step 2: Get dependencies
echo ""
echo -e "${BLUE}[2/5] Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓${NC} Dependencies updated"

# Step 3: Run code generation (if needed)
if grep -q "build_runner" pubspec.yaml; then
    echo ""
    echo -e "${BLUE}[3/5] Running code generation...${NC}"
    flutter pub run build_runner build --delete-conflicting-outputs
    echo -e "${GREEN}✓${NC} Code generation complete"
else
    echo ""
    echo -e "${BLUE}[3/5] Skipping code generation (not needed)${NC}"
fi

# Step 4: Build iOS app
echo ""
echo -e "${BLUE}[4/5] Building iOS app for ${FLAVOR}...${NC}"
echo -e "${YELLOW}This may take 5-15 minutes...${NC}"
echo ""

# Choose build method
echo "Select build method:"
echo "  1) Build IPA (ready for Transporter upload)"
echo "  2) Build iOS only (open in Xcode for Archive)"
read -p "Choose (1 or 2): " -n 1 -r BUILD_METHOD
echo ""
echo ""

if [[ $BUILD_METHOD == "1" ]]; then
    # Build IPA directly
    echo -e "${BLUE}Building IPA file...${NC}"
    flutter build ipa \
        --release \
        --flavor="$FLAVOR" \
        -t "$DART_ENTRYPOINT" \
        --dart-define-from-file="$ENV_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓${NC} IPA build complete!"
        
        # Find the IPA file
        IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -n 1)
        
        if [ -n "$IPA_PATH" ]; then
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}   BUILD SUCCESSFUL!${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${BLUE}IPA Location:${NC}"
            echo "  $IPA_PATH"
            echo ""
            echo -e "${BLUE}IPA Size:${NC}"
            du -h "$IPA_PATH"
            echo ""
            echo -e "${BLUE}Next Steps:${NC}"
            echo "  1. Open Transporter app"
            echo "  2. Drag and drop the IPA file"
            echo "  3. Click 'Deliver' to upload to App Store Connect"
            echo ""
            echo -e "${BLUE}Or use command line:${NC}"
            echo "  xcrun altool --upload-app -f '$IPA_PATH' \\"
            echo "    -t ios -u YOUR_APPLE_ID@email.com"
            echo ""
            
            # Optionally open in Finder
            read -p "Open IPA location in Finder? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open "$(dirname "$IPA_PATH")"
            fi
        fi
    else
        echo -e "${RED}✗ IPA build failed${NC}"
        exit 1
    fi
    
elif [[ $BUILD_METHOD == "2" ]]; then
    # Build iOS only (for Xcode Archive)
    echo -e "${BLUE}Building iOS app...${NC}"
    flutter build ios \
        --release \
        --flavor="$FLAVOR" \
        -t "$DART_ENTRYPOINT" \
        --dart-define-from-file="$ENV_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓${NC} iOS build complete!"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}   BUILD SUCCESSFUL!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${BLUE}Next Steps:${NC}"
        echo "  1. Open Xcode workspace:"
        echo "     open ios/Runner.xcworkspace"
        echo ""
        echo "  2. In Xcode:"
        echo "     • Select 'Any iOS Device (arm64)'"
        echo "     • Product → Archive"
        echo "     • Distribute App → App Store Connect → Upload"
        echo ""
        
        # Optionally open in Xcode
        read -p "Open in Xcode now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open ios/Runner.xcworkspace
        fi
    else
        echo -e "${RED}✗ iOS build failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Invalid selection${NC}"
    exit 1
fi

# Step 5: Summary
echo ""
echo -e "${BLUE}[5/5] Build Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓${NC} Flavor: $FLAVOR"
echo -e "${GREEN}✓${NC} Environment: $ENV_FILE"
echo -e "${GREEN}✓${NC} Bundle ID: $BUNDLE_ID"
echo -e "${GREEN}✓${NC} Team ID: $TEAM_ID"
FINAL_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${GREEN}✓${NC} Version: $FINAL_VERSION"
echo ""

echo -e "${YELLOW}Remember:${NC}"
echo "  • Each upload needs a unique build number"
echo "  • First TestFlight build may take 24-48 hours for review"
echo "  • Subsequent builds are usually available in 5-30 minutes"
echo ""

echo -e "${BLUE}Need help? Check these files:${NC}"
echo "  • TESTFLIGHT_UPLOAD_GUIDE.md (detailed guide)"
echo "  • TESTFLIGHT_CHECKLIST.md (quick checklist)"
echo ""

echo -e "${GREEN}Build script complete! 🎉${NC}"
echo ""




