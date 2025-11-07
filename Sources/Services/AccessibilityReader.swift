internal import Foundation
internal import AppKit
@preconcurrency import ApplicationServices
internal import Combine

/// Authorization status for Accessibility API access
enum AccessibilityAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

/// Errors that can occur during accessibility operations
enum AccessibilityError: Error, Sendable {
    case permissionDenied
    case menuBarNotAccessible
    case applicationNotFound
    case invalidElement
}

/// Service class that reads menu structures and keyboard shortcuts from the active application using macOS Accessibility APIs
@MainActor
final class AccessibilityReader: ObservableObject {
    // MARK: - Singleton
    
    static let shared = AccessibilityReader()
    
    // MARK: - Published Properties
    
    /// The current list of shortcuts from active app
    @Published private(set) var shortcuts: [ShortcutItem] = []
    
    /// Current permission state
    @Published private(set) var authorizationStatus: AccessibilityAuthorizationStatus = .notDetermined
    
    /// Indicates if menu reading is in progress
    @Published private(set) var isReading: Bool = false
    
    /// Optional error message for debugging/display
    @Published private(set) var lastError: String?

    /// Indicates if the current shortcuts are from cache
    @Published private(set) var isUsingCache: Bool = false

    /// Tracks which app's shortcuts are currently displayed
    @Published private(set) var displayedAppInfo: (name: String, icon: NSImage?, bundleID: String)?

    // MARK: - Private Properties
    
    /// Store Combine subscription to AppWatcher
    private var appWatcherCancellable: AnyCancellable?
    
    /// Avoid redundant reads
    private var lastReadBundleID: String?
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
        setupAppWatcher()
    }
    
    deinit {
        // Note: deinit is already isolated to MainActor since the class is @MainActor
        // We need to use assumeIsolated to safely access MainActor-isolated properties
        MainActor.assumeIsolated {
            appWatcherCancellable?.cancel()
            appWatcherCancellable = nil
        }
    }
    
    // MARK: - Setup

    private func setupAppWatcher() {
        appWatcherCancellable = AppWatcher.shared.$activeAppInfo
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.readMenusForActiveApp()
                }
            }

        // CRITICAL FIX: Manually trigger initial read
        // Combine's sink only receives NEW values, not the current value
        // Since AppWatcher may have already set activeAppInfo before we subscribed,
        // we need to manually trigger the initial read
        readMenusForActiveApp()
    }
    
    // MARK: - Permission Management
    
    /// Check current accessibility permission status
    @discardableResult
    func checkAuthorizationStatus() -> AccessibilityAuthorizationStatus {
        let trusted = AXIsProcessTrusted()
        authorizationStatus = trusted ? .authorized : .denied
        return authorizationStatus
    }
    
    /// Request accessibility permission from the user
    nonisolated func requestAccessibilityPermission() {
        // Access the C API constant in a nonisolated context
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Update status on MainActor
        Task { @MainActor in
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually trigger menu re-reading (bypasses cache)
    func refresh() {
        // Invalidate cache for current app
        if let bundleID = AppWatcher.shared.activeAppInfo?.bundleID {
            MenuCacheManager.shared.invalidateCache(for: bundleID)
        }

        // Reset the last read bundle ID to force a fresh read
        lastReadBundleID = nil
        readMenusForActiveApp()
    }

    /// Clear all cached menu data
    func clearCache() {
        MenuCacheManager.shared.clearAllCache()
        NSLog("🗑️ AccessibilityReader: Cleared all cache")
    }

    /// Read menus for a specific app (not necessarily the active one)
    /// This is used for the Recent Apps feature
    func readMenusForSpecificApp(_ app: NSRunningApplication) async {
        // Check authorization
        checkAuthorizationStatus()
        guard authorizationStatus == .authorized else {
            shortcuts = []
            lastError = "Accessibility permission not granted"
            print("⚠️ AccessibilityReader: Permission not granted")
            return
        }

        // Clear error if permissions are granted
        lastError = nil

        // Update the last read bundle ID to this app
        lastReadBundleID = app.bundleIdentifier

        print("📱 AccessibilityReader: Reading menus for specific app: \(app.localizedName ?? "Unknown") (\(app.bundleIdentifier ?? "no bundle ID"))")

        // Update displayed app info
        displayedAppInfo = (
            name: app.localizedName ?? "Unknown",
            icon: app.icon,
            bundleID: app.bundleIdentifier ?? ""
        )

        // Read menus
        await readMenus(for: app)
    }

    // MARK: - Menu Reading
    
    private func readMenusForActiveApp() {
        // Check authorization
        checkAuthorizationStatus()
        guard authorizationStatus == .authorized else {
            shortcuts = []
            lastError = "Accessibility permission not granted"
            print("⚠️ AccessibilityReader: Permission not granted")
            return
        }

        // Clear error if permissions are granted
        lastError = nil

        // Get active app
        guard let activeApp = AppWatcher.shared.activeAppInfo else {
            shortcuts = []
            print("⚠️ AccessibilityReader: No active app info available")
            return
        }

        // Optimization: skip if same app
        if lastReadBundleID == activeApp.bundleID {
            print("ℹ️ AccessibilityReader: Skipping read for same app: \(activeApp.name ?? "Unknown")")
            return
        }

        lastReadBundleID = activeApp.bundleID
        print("📱 AccessibilityReader: Reading menus for app: \(activeApp.name ?? "Unknown") (\(activeApp.bundleID ?? "no bundle ID"))")

        // Update displayed app info for active app
        displayedAppInfo = (
            name: activeApp.name ?? "Unknown",
            icon: activeApp.app.icon,
            bundleID: activeApp.bundleID ?? ""
        )

        // Get running application
        guard let bundleID = activeApp.bundleID,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            shortcuts = []
            lastError = "Could not find running application"
            print("⚠️ AccessibilityReader: Could not find running application for bundle ID: \(activeApp.bundleID ?? "nil")")
            return
        }

        // Read menus
        Task {
            await readMenus(for: runningApp)
        }
    }
    
    private func readMenus(for app: NSRunningApplication) async {
        isReading = true
        defer { isReading = false }

        // CACHE CHECK: Try to get cached shortcuts first
        if let cachedShortcuts = MenuCacheManager.shared.getCachedShortcuts(for: app) {
            shortcuts = cachedShortcuts
            lastError = nil
            isUsingCache = true

            let withShortcuts = cachedShortcuts.filter { $0.hasShortcut }
            NSLog("🚀 AccessibilityReader: Using CACHED shortcuts (\(cachedShortcuts.count) items, \(withShortcuts.count) with shortcuts)")
            return
        }

        // CACHE MISS: Perform full menu scan
        isUsingCache = false
        NSLog("🔍 AccessibilityReader: Cache miss - performing full menu scan")

        do {
            let menuShortcuts = try await readMenusThrows(for: app)
            shortcuts = menuShortcuts
            lastError = nil

            // CACHE STORE: Save the scanned shortcuts
            MenuCacheManager.shared.cacheShortcuts(menuShortcuts, for: app)

            // Debug logging with NSLog to ensure visibility
            let withShortcuts = menuShortcuts.filter { $0.hasShortcut }
            NSLog("✅ AccessibilityReader: Successfully read \(menuShortcuts.count) menu items")
            NSLog("   📊 Items with shortcuts: \(withShortcuts.count)")
            NSLog("   📊 Items without shortcuts: \(menuShortcuts.count - withShortcuts.count)")

            // Log first few shortcuts for debugging
            if !withShortcuts.isEmpty {
                NSLog("   🔍 Sample shortcuts:")
                for item in withShortcuts.prefix(3) {
                    NSLog("      - \(item.title): \(item.shortcut ?? "nil")")
                }
            } else {
                NSLog("   ⚠️ NO SHORTCUTS FOUND WITH hasShortcut=true")
                // Log first few items regardless
                if !menuShortcuts.isEmpty {
                    NSLog("   🔍 Sample menu items (all):")
                    for item in menuShortcuts.prefix(5) {
                        NSLog("      - \(item.title): shortcut=\(item.shortcut ?? "nil"), hasShortcut=\(item.hasShortcut)")
                    }
                }
            }
        } catch let error as AccessibilityError {
            shortcuts = []
            lastError = error.localizedDescription
            NSLog("❌ AccessibilityReader: Error - \(error.localizedDescription)")
        } catch {
            shortcuts = []
            lastError = "Unknown error: \(error.localizedDescription)"
            NSLog("❌ AccessibilityReader: Unknown error - \(error.localizedDescription)")
        }
    }

    /// Reads menu shortcuts with typed throws for better error handling
    private func readMenusThrows(for app: NSRunningApplication) async throws(AccessibilityError) -> [ShortcutItem] {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        // Get menu bar - may need to activate the app first
        // Many apps only expose their menu bar when they are frontmost
        let menuBar: AXUIElement = try await getMenuBarWithActivation(appElement: appElement, app: app, appName: app.localizedName ?? "Unknown")

        // Get menu bar children (top-level menus)
        let menus = copyAXArray(menuBar, kAXChildrenAttribute as CFString)

        var allShortcuts: [ShortcutItem] = []
        var roleStats: [String: Int] = [:]

        // Iterate through each top-level menu
        for menu in menus {
            let menuShortcuts = extractShortcuts(from: menu, menuPath: [], roleStats: &roleStats)
            allShortcuts.append(contentsOf: menuShortcuts)
        }

        // Log role statistics summary
        NSLog("📊 Role Statistics Summary:")
        let sortedRoles = roleStats.sorted { $0.value > $1.value }
        var totalElements = 0
        for (role, count) in sortedRoles {
            NSLog("   \(role): \(count)")
            totalElements += count
        }
        NSLog("   Total elements processed: \(totalElements)")

        return allShortcuts
    }

    // MARK: - Menu Bar Access with App Activation

    /// Attempts to get the menu bar, activating the app if necessary
    /// Many apps only expose their menu bar when they are the frontmost application
    /// - Parameters:
    ///   - appElement: The AXUIElement for the application
    ///   - app: The NSRunningApplication to activate if needed
    ///   - appName: The application name for logging
    /// - Returns: The menu bar AXUIElement
    /// - Throws: AccessibilityError.menuBarNotAccessible if menu bar cannot be accessed
    private func getMenuBarWithActivation(appElement: AXUIElement, app: NSRunningApplication, appName: String) async throws(AccessibilityError) -> AXUIElement {
        // First attempt: Try to get menu bar without activating
        if let menuBar: AXUIElement = copyAXAttribute(appElement, kAXMenuBarAttribute as CFString) {
            NSLog("✅ AccessibilityReader: Menu bar accessible for \(appName) without activation")
            return menuBar
        }

        // Second attempt: Activate the app and try again
        NSLog("⚠️ AccessibilityReader: Menu bar not accessible for \(appName), activating app...")

        // Activate the application to make its menu bar accessible
        let activated = app.activate(options: [.activateIgnoringOtherApps])

        if !activated {
            NSLog("❌ AccessibilityReader: Failed to activate \(appName)")
            throw .menuBarNotAccessible
        }

        // Wait a brief moment for the app to become active and menu bar to be available
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Try to get the menu bar again
        if let menuBar: AXUIElement = copyAXAttribute(appElement, kAXMenuBarAttribute as CFString) {
            NSLog("✅ AccessibilityReader: Menu bar accessible for \(appName) after activation")
            return menuBar
        }

        // Final attempt with a bit more delay
        try? await Task.sleep(nanoseconds: 100_000_000) // Another 100ms

        if let menuBar: AXUIElement = copyAXAttribute(appElement, kAXMenuBarAttribute as CFString) {
            NSLog("✅ AccessibilityReader: Menu bar accessible for \(appName) after extended wait")
            return menuBar
        }

        // All attempts failed
        NSLog("❌ AccessibilityReader: Menu bar not accessible for \(appName) even after activation")
        throw .menuBarNotAccessible
    }

    // MARK: - Recursive Menu Traversal

    private func extractShortcuts(from element: AXUIElement, menuPath: [String], roleStats: inout [String: Int]) -> [ShortcutItem] {
        var items: [ShortcutItem] = []

        // Read title
        guard let title: String = copyAXString(element, kAXTitleAttribute as CFString),
              !title.isEmpty else {
            // Skip items without titles (separators, etc.)
            return items
        }

        // Build current path
        let currentPath = menuPath + [title]

        // Read role to determine element type
        let role: String? = copyAXString(element, kAXRoleAttribute as CFString)

        // Update role statistics
        let roleKey = role ?? "(no role)"
        roleStats[roleKey, default: 0] += 1

        // Get children WITHOUT pressing/expanding menus visually (preferred approach)
        // This is the elegant approach: just read the accessibility tree structure
        var children: [AXUIElement] = []

        if role == "AXMenuBarItem" {
            // HYBRID APPROACH: Try elegant method first, fallback to AXPress if needed

            // Step 1: Try to read children directly without AXPress (elegant, no visual expansion)
            let menuBarChildren = copyAXArray(element, kAXChildrenAttribute as CFString)
            if let firstChild = menuBarChildren.first {
                let menuRole: String? = copyAXString(firstChild, kAXRoleAttribute as CFString)
                if menuRole == "AXMenu" {
                    // Get the menu items from the AXMenu element
                    children = copyAXArray(firstChild, kAXChildrenAttribute as CFString)

                    // Step 2: If children is empty, some apps use lazy-loading and need AXPress
                    if children.isEmpty {
                        NSLog("   ⚠️ Menu appears lazy-loaded, using AXPress fallback for: \(title)")

                        // Perform AXPress action to force menu population
                        AXUIElementPerformAction(element, kAXPressAction as CFString)

                        // Small delay to allow menu to populate
                        Thread.sleep(forTimeInterval: 0.05)

                        // Re-read children after press
                        let menuBarChildrenAfterPress = copyAXArray(element, kAXChildrenAttribute as CFString)
                        if let firstChildAfterPress = menuBarChildrenAfterPress.first {
                            children = copyAXArray(firstChildAfterPress, kAXChildrenAttribute as CFString)

                            // Cancel the menu press to close it
                            AXUIElementPerformAction(element, kAXCancelAction as CFString)

                            NSLog("   📋 Found \(children.count) menu items after AXPress fallback")
                        }
                    } else {
                        NSLog("   📋 Found AXMenu with \(children.count) menu items (read-only, no visual expansion)")
                    }
                }
            }
        } else {
            // For all other elements, get children normally
            children = copyAXArray(element, kAXChildrenAttribute as CFString)
        }

        // Read shortcut information
        let cmdChar: String? = copyAXString(element, kAXMenuItemCmdCharAttribute as CFString)
        let modifiers: Int? = copyAXAttribute(element, kAXMenuItemCmdModifiersAttribute as CFString)
        let virtualKey: Int? = copyAXAttribute(element, kAXMenuItemCmdVirtualKeyAttribute as CFString)
        let shortcut = parseShortcut(cmdChar: cmdChar, modifiers: modifiers, virtualKey: virtualKey)

        // Read enabled state
        let isEnabled: Bool = copyAXAttribute(element, kAXEnabledAttribute as CFString) ?? true

        // Determine if this element should be added to results
        let isMenuItem = role == "AXMenuItem"
        let hasShortcut = shortcut != nil && !shortcut!.isEmpty
        let shouldAddToResults = isMenuItem && hasShortcut

        // Only create shortcut item for actual menu items with shortcuts
        if shouldAddToResults {
            let item = ShortcutItem(
                title: title,
                shortcut: shortcut,
                menuPath: currentPath,
                isEnabled: isEnabled,
                role: role,
                isSeparator: false
            )
            items.append(item)
        }

        // Recursively process children (ALWAYS executed, regardless of role)
        for child in children {
            let childItems = extractShortcuts(from: child, menuPath: currentPath, roleStats: &roleStats)
            items.append(contentsOf: childItems)
        }

        return items
    }

    // MARK: - Shortcut Parsing

    private func parseShortcut(cmdChar: String?, modifiers: Int?, virtualKey: Int?) -> String? {
        // Try character-based shortcut first
        if let cmdChar = cmdChar, !cmdChar.isEmpty {
            let modifierString = formatModifiers(modifiers)
            let key = cmdChar.uppercased()
            return modifierString + key
        }

        // Fall back to virtual key-based shortcut
        if let virtualKey = virtualKey {
            if let keyString = mapVirtualKeyToString(virtualKey) {
                let modifierString = formatModifiers(modifiers)
                return modifierString + keyString
            }
        }

        // No valid shortcut found
        return nil
    }

    private func formatModifiers(_ modifiers: Int?) -> String {
        var modifierString = ""
        let modifierValue = modifiers ?? 0

        // Decode modifiers bitmask
        // Bit 3 (8): Command INVERTED - if bit 3 is NOT set, Command (⌘) is present
        if (modifierValue & (1 << 3)) == 0 {
            modifierString += "⌘"
        }

        // Bit 1 (2): Option (⌥)
        if (modifierValue & (1 << 1)) != 0 {
            modifierString += "⌥"
        }

        // Bit 2 (4): Control (⌃)
        if (modifierValue & (1 << 2)) != 0 {
            modifierString += "⌃"
        }

        // Bit 0 (1): Shift (⇧)
        if (modifierValue & (1 << 0)) != 0 {
            modifierString += "⇧"
        }

        return modifierString
    }

    private func mapVirtualKeyToString(_ virtualKey: Int) -> String? {
        switch virtualKey {
        // Function Keys F1-F12
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"

        // Function Keys F13-F20
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        case 106: return "F16"
        case 64: return "F17"
        case 79: return "F18"
        case 80: return "F19"
        case 90: return "F20"

        // Arrow Keys
        case 126: return "↑"
        case 125: return "↓"
        case 123: return "←"
        case 124: return "→"

        // Special Keys
        case 51: return "⌫"      // Delete/Backspace
        case 117: return "⌦"     // Forward Delete
        case 53: return "⎋"      // Escape
        case 36: return "↩"      // Return
        case 76: return "⌅"      // Enter
        case 48: return "⇥"      // Tab
        case 49: return "Space"
        case 115: return "↖"     // Home
        case 119: return "↘"     // End
        case 116: return "⇞"     // Page Up
        case 121: return "⇟"     // Page Down
        case 71: return "⌧"      // Clear
        case 114: return "?⃝"    // Help

        default: return nil
        }
    }

    // MARK: - AX Attribute Helpers

    /// Generic helper to safely call AXUIElementCopyAttributeValue and cast result
    private func copyAXAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)

        guard error == .success, let value = value else {
            return nil
        }

        return value as? T
    }

    /// Specialized helper for string attributes
    private func copyAXString(_ element: AXUIElement, _ attribute: CFString) -> String? {
        return copyAXAttribute(element, attribute)
    }

    /// Specialized helper for array attributes (children)
    private func copyAXArray(_ element: AXUIElement, _ attribute: CFString) -> [AXUIElement] {
        guard let array: CFArray = copyAXAttribute(element, attribute) else {
            return []
        }

        return array as? [AXUIElement] ?? []
    }
}

// MARK: - AccessibilityError Extension

extension AccessibilityError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Accessibility permission not granted"
        case .menuBarNotAccessible:
            return "Could not access menu bar"
        case .applicationNotFound:
            return "Could not find running application"
        case .invalidElement:
            return "Invalid accessibility element"
        }
    }
}

