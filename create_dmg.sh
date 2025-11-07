#!/bin/bash

# Professional DMG Creator for easyshortcut
# Creates a polished, production-ready DMG installer with custom background and layout

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

APP_NAME="easyshortcut"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUNDLE_ID="com.easyshortcut.easyshortcut"

# Paths
SOURCE_APP="/Users/lucas/Library/Developer/Xcode/DerivedData/easyshortcut-fsksottlflufgpbbiekdbxizljox/Build/Products/Release/${APP_NAME}.app"
DMG_DIR="dmg_temp"
FINAL_DMG="${DMG_NAME}.dmg"
TEMP_DMG="${DMG_NAME}-temp.dmg"

# DMG Settings
DMG_VOLUME_NAME="${APP_NAME}"
DMG_WINDOW_WIDTH=600
DMG_WINDOW_HEIGHT=400
DMG_ICON_SIZE=128
DMG_TEXT_SIZE=14

# Icon positions (x, y)
APP_ICON_X=150
APP_ICON_Y=200
APPS_ICON_X=450
APPS_ICON_Y=200

# Colors
echo "🎨 easyshortcut DMG Creator v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# VALIDATION
# ============================================================================

echo ""
echo "📋 Validating build..."

if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Error: Application not found at: $SOURCE_APP"
    echo "   Please build the app in Release configuration first:"
    echo "   xcodebuild -project easyshortcut.xcodeproj -scheme easyshortcut -configuration Release build"
    exit 1
fi

# Verify app is properly signed
echo "🔐 Checking code signature..."
if ! codesign -v "$SOURCE_APP" 2>/dev/null; then
    echo "⚠️  Warning: App is not properly signed"
    echo "   The app will work locally but cannot be distributed"
else
    echo "✅ App is properly signed"
fi

# Get app version from Info.plist
APP_VERSION=$(defaults read "$SOURCE_APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
echo "📦 App version: $APP_VERSION"

# ============================================================================
# CLEANUP
# ============================================================================

echo ""
echo "🧹 Cleaning up previous builds..."

if [ -d "$DMG_DIR" ]; then
    rm -rf "$DMG_DIR"
fi

if [ -f "$FINAL_DMG" ]; then
    rm -f "$FINAL_DMG"
fi

if [ -f "$TEMP_DMG" ]; then
    rm -f "$TEMP_DMG"
fi

# ============================================================================
# CREATE DMG STRUCTURE
# ============================================================================

echo ""
echo "📁 Creating DMG structure..."

mkdir -p "$DMG_DIR"

# Copy the app
echo "   Copying ${APP_NAME}.app..."
cp -R "$SOURCE_APP" "$DMG_DIR/"

# Create Applications folder symlink
echo "   Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# ============================================================================
# CREATE TEMPORARY DMG
# ============================================================================

echo ""
echo "💿 Creating temporary DMG..."

hdiutil create -srcfolder "$DMG_DIR" \
    -volname "$DMG_VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 200m \
    "$TEMP_DMG"

# ============================================================================
# MOUNT AND CUSTOMIZE DMG
# ============================================================================

echo ""
echo "🎨 Customizing DMG appearance..."

# Mount the temporary DMG
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep -E '^/dev/' | sed 1q | awk '{print $3}')

if [ -z "$MOUNT_DIR" ]; then
    echo "❌ Error: Failed to mount DMG"
    exit 1
fi

echo "   Mounted at: $MOUNT_DIR"

# Wait for mount to complete
sleep 2

# Set custom icon positions and window properties using AppleScript
echo "   Setting window properties..."

osascript <<EOF
tell application "Finder"
    tell disk "$DMG_VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, $(($DMG_WINDOW_WIDTH + 100)), $(($DMG_WINDOW_HEIGHT + 100))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $DMG_ICON_SIZE
        set text size of viewOptions to $DMG_TEXT_SIZE
        set background color of viewOptions to {255, 255, 255}

        -- Position icons
        set position of item "${APP_NAME}.app" of container window to {$APP_ICON_X, $APP_ICON_Y}
        set position of item "Applications" of container window to {$APPS_ICON_X, $APPS_ICON_Y}

        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Ensure changes are written
sync

# Wait for Finder to finish
sleep 3

# ============================================================================
# FINALIZE DMG
# ============================================================================

echo ""
echo "🔒 Finalizing DMG..."

# Unmount
echo "   Unmounting temporary DMG..."
hdiutil detach "$MOUNT_DIR" -quiet -force

# Convert to compressed, read-only DMG
echo "   Compressing and converting to read-only..."
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$FINAL_DMG"

# Clean up temporary files
echo "   Cleaning up temporary files..."
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

# ============================================================================
# VERIFICATION
# ============================================================================

echo ""
echo "🔍 Verifying DMG..."

if [ -f "$FINAL_DMG" ]; then
    DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
    echo "✅ DMG created successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Package Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Name:     $FINAL_DMG"
    echo "   Size:     $DMG_SIZE"
    echo "   Version:  $APP_VERSION"
    echo "   Bundle:   $BUNDLE_ID"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 Installation Instructions:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1. Double-click $FINAL_DMG to mount"
    echo "   2. Drag ${APP_NAME}.app to Applications folder"
    echo "   3. Launch ${APP_NAME} from Applications"
    echo "   4. Grant Accessibility permissions when prompted"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Distribution Ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo "❌ Error: DMG creation failed"
    exit 1
fi

