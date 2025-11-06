#!/bin/bash

# Script to create a simple DMG installer for easyshortcut
# This creates a drag-and-drop installer with the app and Applications folder symlink

set -e

# Configuration
APP_NAME="easyshortcut"
VERSION="1.0"
DMG_NAME="${APP_NAME}-${VERSION}"
SOURCE_APP="/Users/lucas/Library/Developer/Xcode/DerivedData/easyshortcut-fsksottlflufgpbbiekdbxizljox/Build/Products/Release/${APP_NAME}.app"
DMG_DIR="dmg_temp"
FINAL_DMG="${DMG_NAME}.dmg"

echo "🚀 Creating DMG installer for ${APP_NAME}..."

# Clean up any previous builds
if [ -d "$DMG_DIR" ]; then
    echo "Cleaning up previous build..."
    rm -rf "$DMG_DIR"
fi

if [ -f "$FINAL_DMG" ]; then
    echo "Removing old DMG..."
    rm -f "$FINAL_DMG"
fi

# Create temporary directory
echo "Creating temporary directory..."
mkdir -p "$DMG_DIR"

# Copy the app
echo "Copying ${APP_NAME}.app..."
cp -R "$SOURCE_APP" "$DMG_DIR/"

# Create Applications folder symlink
echo "Creating Applications folder symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$FINAL_DMG"

# Clean up
echo "Cleaning up..."
rm -rf "$DMG_DIR"

echo "✅ DMG created successfully: $FINAL_DMG"
echo ""
echo "To install:"
echo "1. Open ${FINAL_DMG}"
echo "2. Drag ${APP_NAME}.app to the Applications folder"
echo "3. Launch ${APP_NAME} from Applications"

