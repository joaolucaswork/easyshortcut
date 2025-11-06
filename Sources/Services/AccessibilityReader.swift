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
    
    /// Manually trigger menu re-reading
    func refresh() {
        // Reset the last read bundle ID to force a fresh read
        lastReadBundleID = nil
        readMenusForActiveApp()
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

        do {
            let menuShortcuts = try await readMenusThrows(for: app)
            shortcuts = menuShortcuts
            lastError = nil

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

        // Get menu bar
        guard let menuBar: AXUIElement = copyAXAttribute(appElement, kAXMenuBarAttribute as CFString) else {
            throw .menuBarNotAccessible
        }

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

        // Debug: Log role and children count
        let children = copyAXArray(element, kAXChildrenAttribute as CFString)

        // Read shortcut information
        let cmdChar: String? = copyAXString(element, kAXMenuItemCmdCharAttribute as CFString)
        let modifiers: Int? = copyAXAttribute(element, kAXMenuItemCmdModifiersAttribute as CFString)
        let shortcut = parseShortcut(cmdChar: cmdChar, modifiers: modifiers)

        // Read enabled state
        let isEnabled: Bool = copyAXAttribute(element, kAXEnabledAttribute as CFString) ?? true

        // Determine if this element should be added to results
        let isMenuItem = role == "AXMenuItem"
        let hasShortcut = shortcut != nil && !shortcut!.isEmpty
        let shouldAddToResults = isMenuItem && hasShortcut

        // Enhanced debug logging
        NSLog("🔍 Processing Element:")
        NSLog("   Title: \(title)")
        NSLog("   Role: \(role ?? "nil")")
        NSLog("   Children: \(children.count)")
        NSLog("   Raw cmdChar: \(cmdChar ?? "nil")")
        NSLog("   Raw modifiers: \(modifiers.map { String($0) } ?? "nil")")
        NSLog("   Parsed shortcut: \(shortcut ?? "nil")")
        NSLog("   isMenuItem: \(isMenuItem)")
        NSLog("   hasShortcut: \(hasShortcut)")
        NSLog("   Will add to results: \(shouldAddToResults)")

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

    private func parseShortcut(cmdChar: String?, modifiers: Int?) -> String? {
        guard let cmdChar = cmdChar, !cmdChar.isEmpty else {
            return nil
        }

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

        // Uppercase the key character for consistency
        let key = cmdChar.uppercased()

        return modifierString + key
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

