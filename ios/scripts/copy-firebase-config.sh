#!/bin/sh
set -euo pipefail

# Script to copy the correct GoogleService-Info.plist based on the build configuration

# Default to develop if no configuration is set
CONFIGURATION=${CONFIGURATION:-develop}

# Determine which config folder to use
case "$CONFIGURATION" in
  *Debug-develop*|*Release-develop*|*Debug*|develop)
    CONFIG_FOLDER="develop"
    ;;
  *Debug-staging*|*Release-staging*|staging)
    CONFIG_FOLDER="staging"
    ;;
  *Debug-production*|*Release-production*|*Release*|production)
    CONFIG_FOLDER="production"
    ;;
  *)
    CONFIG_FOLDER="develop"
    ;;
esac

echo "Using configuration: $CONFIGURATION"
echo "Copying GoogleService-Info.plist from config/$CONFIG_FOLDER/"

# Copy the appropriate GoogleService-Info.plist
SOURCE_PATH="${SRCROOT}/config/${CONFIG_FOLDER}/GoogleService-Info.plist"
DEST_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
DEST_DIR="$(dirname "${DEST_PATH}")"

if [ -f "$SOURCE_PATH" ]; then
  mkdir -p "$DEST_DIR"
  cp "$SOURCE_PATH" "$DEST_PATH"
  echo "Successfully copied GoogleService-Info.plist from $CONFIG_FOLDER"
else
  echo "Error: GoogleService-Info.plist not found at $SOURCE_PATH"
  exit 1
fi
