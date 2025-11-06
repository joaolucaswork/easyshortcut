internal import Foundation

/// Represents cached menu data for an application with metadata for change detection
struct CachedMenuData: Codable, Sendable {
    /// The bundle identifier of the application
    let bundleID: String
    
    /// The version string of the application when cached
    let appVersion: String
    
    /// The modification date of the application bundle
    let bundleModificationDate: Date
    
    /// Hash of the menu structure for quick change detection
    let menuStructureHash: String
    
    /// The cached shortcuts
    let shortcuts: [CachedShortcutItem]
    
    /// When this cache entry was created
    let cachedAt: Date
    
    /// When this cache entry was last accessed
    var lastAccessedAt: Date
    
    // MARK: - Initialization
    
    init(
        bundleID: String,
        appVersion: String,
        bundleModificationDate: Date,
        menuStructureHash: String,
        shortcuts: [CachedShortcutItem],
        cachedAt: Date = Date(),
        lastAccessedAt: Date = Date()
    ) {
        self.bundleID = bundleID
        self.appVersion = appVersion
        self.bundleModificationDate = bundleModificationDate
        self.menuStructureHash = menuStructureHash
        self.shortcuts = shortcuts
        self.cachedAt = cachedAt
        self.lastAccessedAt = lastAccessedAt
    }
    
    // MARK: - Change Detection
    
    /// Checks if the cache is still valid for the given app metadata
    func isValid(
        currentVersion: String,
        currentModificationDate: Date,
        currentHash: String
    ) -> Bool {
        return appVersion == currentVersion &&
               bundleModificationDate == currentModificationDate &&
               menuStructureHash == currentHash
    }
    
    /// Updates the last accessed timestamp
    mutating func updateAccessTime() {
        lastAccessedAt = Date()
    }
}

/// Codable version of ShortcutItem for cache persistence
struct CachedShortcutItem: Codable, Sendable {
    let title: String
    let shortcut: String?
    let menuPath: [String]
    let isEnabled: Bool
    let role: String?
    let isSeparator: Bool
    
    // MARK: - Conversion
    
    /// Convert from ShortcutItem to CachedShortcutItem
    init(from item: ShortcutItem) {
        self.title = item.title
        self.shortcut = item.shortcut
        self.menuPath = item.menuPath
        self.isEnabled = item.isEnabled
        self.role = item.role
        self.isSeparator = item.isSeparator
    }
    
    /// Convert to ShortcutItem
    func toShortcutItem() -> ShortcutItem {
        ShortcutItem(
            title: title,
            shortcut: shortcut,
            menuPath: menuPath,
            isEnabled: isEnabled,
            role: role,
            isSeparator: isSeparator
        )
    }
}

