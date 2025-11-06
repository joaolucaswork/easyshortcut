internal import Foundation

/// Represents a keyboard shortcut extracted from an application's menu structure.
struct ShortcutItem: Identifiable, Equatable, Hashable, Sendable {
    /// Unique identifier for SwiftUI List iteration
    let id: UUID = UUID()
    
    /// The menu item's display name (e.g., "New Window", "Copy", "Paste")
    let title: String
    
    /// The formatted keyboard shortcut string (e.g., "⌘N", "⌘⇧T", "⌥⌘C"), nil if no shortcut exists
    let shortcut: String?
    
    /// The hierarchical path to this item (e.g., ["File", "New", "Window"] represents File > New > Window)
    let menuPath: [String]
    
    /// Whether the menu item is currently enabled
    let isEnabled: Bool
    
    /// Optional properties for future enhancement
    let role: String?
    let isSeparator: Bool
    
    // MARK: - Computed Properties
    
    /// Returns the full menu path as a readable string (e.g., "File > New > Window")
    var fullPath: String {
        menuPath.joined(separator: " > ")
    }
    
    /// Returns true if this item has a keyboard shortcut
    var hasShortcut: Bool {
        shortcut != nil && !shortcut!.isEmpty
    }
    
    // MARK: - Initializer
    
    init(
        title: String,
        shortcut: String? = nil,
        menuPath: [String],
        isEnabled: Bool = true,
        role: String? = nil,
        isSeparator: Bool = false
    ) {
        self.title = title
        self.shortcut = shortcut
        self.menuPath = menuPath
        self.isEnabled = isEnabled
        self.role = role
        self.isSeparator = isSeparator
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ShortcutItem, rhs: ShortcutItem) -> Bool {
        lhs.title == rhs.title &&
        lhs.shortcut == rhs.shortcut &&
        lhs.menuPath == rhs.menuPath &&
        lhs.isEnabled == rhs.isEnabled
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(shortcut)
        hasher.combine(menuPath)
        hasher.combine(isEnabled)
    }
}

