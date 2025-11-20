#!/bin/sh
set -euo pipefail

# Script to copy the correct GoogleService-Info.plist based on the build configuration

# Default to develop if no configuration is set
CONFIGURATION=${CONFIGURATION:-develop}

# Determine which config folder to use.
# IMPORTANT: Match the specific build configurations first and avoid
# overly broad patterns like `*Debug*` or `*Release*` that would
# accidentally catch all flavors.
case "$CONFIGURATION" in
  # --- Develop ---
  *Debug-develop*|*Release-develop*|develop)
    CONFIG_FOLDER="develop"
    ;;

  # --- Staging ---
  *Debug-staging*|*Release-staging*|staging)
    CONFIG_FOLDER="staging"
    ;;

  # --- Production ---
  *Debug-production*|*Release-production*|production)
    CONFIG_FOLDER="production"
    ;;

  # Fallback to develop
  *)
    CONFIG_FOLDER="develop"
    ;;
esac

echo "Using configuration: $CONFIGURATION"
echo "Copying GoogleService-Info.plist from config/$CONFIG_FOLDER/"

# Copy the appropriate GoogleService-Info.plist
SOURCE_PATH="${SRCROOT}/config/${CONFIG_FOLDER}/GoogleService-Info.plist"
# Copy to the Runner directory (source location)
DEST_PATH="${SRCROOT}/Runner/GoogleService-Info.plist"
# Also copy to the built app bundle
BUNDLE_DEST_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
BUNDLE_DEST_DIR="$(dirname "${BUNDLE_DEST_PATH}")"

if [ -f "$SOURCE_PATH" ]; then
  # Copy to source directory
  cp "$SOURCE_PATH" "$DEST_PATH"
  echo "Successfully copied GoogleService-Info.plist to Runner directory from $CONFIG_FOLDER"
  
  # Copy to built app bundle if it exists
  if [ -d "$BUNDLE_DEST_DIR" ]; then
    cp "$SOURCE_PATH" "$BUNDLE_DEST_PATH"
    echo "Successfully copied GoogleService-Info.plist to app bundle from $CONFIG_FOLDER"
  fi
else
  echo "Error: GoogleService-Info.plist not found at $SOURCE_PATH"
  exit 1
fi