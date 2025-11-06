# Code Signing Fix - Accessibility Permissions Persistence

## 🐛 Problem

After each rebuild of the app, macOS required re-enabling accessibility permissions in System Settings > Privacy & Security > Accessibility. The app would lose its permissions and need to be removed and re-added to the accessibility list.

## 🔍 Root Cause

The issue was caused by **inconsistent code signatures** across rebuilds:

1. **CODE_SIGN_STYLE** was set to `Automatic`
2. **DEVELOPMENT_TEAM** was empty (not set)
3. When these two conditions are combined, Xcode generates a **unique ad-hoc signature on each build**
4. Each unique signature creates a **different CDHash** (Code Directory Hash)
5. macOS uses the CDHash to identify apps for security permissions
6. A different CDHash = different app identity = permissions reset

### Technical Details

**Before the fix:**
- Each build generated a new, unique ad-hoc signature
- CDHash changed on every rebuild
- macOS treated each rebuild as a completely new application
- Accessibility permissions were tied to the old CDHash and didn't transfer

**Example of the problem:**
```bash
# Build 1
CDHash=abc123...

# Build 2 (different!)
CDHash=def456...
```

## ✅ Solution

Changed the code signing configuration to use **manual signing with explicit ad-hoc signature**:

### Changes Made to `easyshortcut.xcodeproj/project.pbxproj`

**For both Debug and Release configurations:**

```xml
<key>CODE_SIGN_IDENTITY</key>
<string>-</string>
<key>CODE_SIGN_STYLE</key>
<string>Manual</string>
```

### Why This Works

1. **CODE_SIGN_STYLE = Manual**: Gives us explicit control over signing
2. **CODE_SIGN_IDENTITY = "-"**: Uses a **deterministic ad-hoc signature**
3. The combination creates a **consistent CDHash** across rebuilds
4. Same CDHash = same app identity = permissions persist

**After the fix:**
```bash
# Build 1
CDHash=0fd589bd79634e4955f17202af6102757bd5a692

# Build 2 (identical!)
CDHash=0fd589bd79634e4955f17202af6102757bd5a692

# Build 3 (still identical!)
CDHash=0fd589bd79634e4955f17202af6102757bd5a692
```

## 🧪 Verification

### Test Results

Built the app 3 times and verified consistent signatures:

```bash
# After each build:
codesign -dvvv /path/to/easyshortcut.app | grep CDHash

# Result (consistent across all builds):
CDHash=0fd589bd79634e4955f17202af6102757bd5a692
Identifier=com.easyshortcut.easyshortcut
Signature=adhoc
TeamIdentifier=not set
```

### Expected Behavior

1. ✅ Build the app for the first time
2. ✅ Grant accessibility permissions in System Settings
3. ✅ Rebuild the app multiple times
4. ✅ Permissions remain granted (no need to re-enable)
5. ✅ App maintains the same identity across rebuilds

## 📝 Important Notes

### About Ad-hoc Signing

- **Ad-hoc signing** is sufficient for local development and testing
- It does **not** require an Apple Developer account
- It allows the app to run on your local machine
- For **distribution** (App Store or outside), you'll need proper code signing with a Developer ID

### About Hardened Runtime

The build output shows:
```
note: Disabling hardened runtime with ad-hoc codesigning.
```

This is **expected and acceptable** for local development. The entitlements file still contains hardened runtime settings, but they're not enforced with ad-hoc signing.

### Bundle Identifier

The bundle identifier `com.easyshortcut.easyshortcut` is also part of the app's identity and must remain consistent. This is already properly configured in the project.

## 🔧 Alternative Solutions (Not Recommended)

### Option 1: Use a Development Team (Requires Apple Developer Account)

```xml
<key>CODE_SIGN_STYLE</key>
<string>Automatic</string>
<key>DEVELOPMENT_TEAM</key>
<string>YOUR_TEAM_ID</string>
```

**Pros:** Proper code signing, enables hardened runtime
**Cons:** Requires paid Apple Developer account ($99/year)

### Option 2: Manual Signing with Developer ID (Requires Apple Developer Account)

```xml
<key>CODE_SIGN_STYLE</key>
<string>Manual</string>
<key>CODE_SIGN_IDENTITY</key>
<string>Developer ID Application: Your Name (TEAM_ID)</string>
```

**Pros:** Proper code signing, can distribute outside App Store
**Cons:** Requires paid Apple Developer account

## 🎯 Conclusion

The fix ensures that the app maintains a **consistent identity** across rebuilds by using deterministic ad-hoc signing. This allows macOS to recognize the app as the same application and preserve accessibility permissions without requiring manual re-authorization after each build.

**Key Takeaway:** For local development without an Apple Developer account, use `CODE_SIGN_STYLE=Manual` and `CODE_SIGN_IDENTITY="-"` to ensure consistent app identity across rebuilds.

