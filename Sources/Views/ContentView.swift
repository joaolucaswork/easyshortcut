//
//  ContentView.swift
//  easyshortcut
//
//  Main SwiftUI view displayed inside the popover.
//  Contains the search field and shortcuts list.
//

internal import SwiftUI

struct ContentView: View {
    // MARK: - View State
    enum ViewMode {
        case activeApp
        case recentApps
    }

    enum SortMode: String {
        case alphabetical = "Alphabetical"
        case menuOrder = "Menu Order"
    }

    @State private var searchQuery = ""
    @State private var viewMode: ViewMode = .activeApp
    @State private var selectedRecentApp: RecentAppInfo?
    @State private var isHoveringIcon = false
    @State private var showingExportMenu = false
    @State private var hiddenGroups: Set<String> = []
    @AppStorage("shortcutSortMode") private var sortMode: SortMode = .menuOrder

    @ObservedObject private var accessibilityReader = AccessibilityReader.shared
    @ObservedObject private var appWatcher = AppWatcher.shared
    @ObservedObject private var recentAppsManager = RecentAppsManager.shared

    private var filteredShortcuts: [ShortcutItem] {
        let shortcuts = accessibilityReader.shortcuts.filter { $0.hasShortcut }

        guard !searchQuery.isEmpty else {
            return shortcuts
        }

        let query = searchQuery.lowercased()
        return shortcuts.filter { item in
            item.title.lowercased().contains(query) ||
            (item.shortcut?.lowercased().contains(query) ?? false) ||
            item.fullPath.lowercased().contains(query)
        }
    }

    /// Returns all available menu groups (for filter UI)
    private var availableGroups: [String] {
        let shortcuts = filteredShortcuts.filter { shortcut in
            guard let firstMenu = shortcut.menuPath.first else { return false }
            return !firstMenu.isEmpty && firstMenu != "Apple" && firstMenu != ""
        }

        var seenGroups = Set<String>()
        var groupOrder: [String] = []
        for shortcut in shortcuts {
            if let firstMenu = shortcut.menuPath.first, !seenGroups.contains(firstMenu) {
                seenGroups.insert(firstMenu)
                groupOrder.append(firstMenu)
            }
        }

        return groupOrder
    }

    /// Groups shortcuts by their top-level menu path, filtering out Apple menu and hidden groups
    private var groupedShortcuts: [(menuGroup: String, shortcuts: [ShortcutItem])] {
        // Filter out Apple menu shortcuts (empty string, Apple symbol, or "Apple")
        let shortcuts = filteredShortcuts.filter { shortcut in
            guard let firstMenu = shortcut.menuPath.first else { return false }
            // Filter out empty strings and common Apple menu identifiers
            return !firstMenu.isEmpty && firstMenu != "Apple" && firstMenu != ""
        }

        // Group by first element of menuPath
        let grouped = Dictionary(grouping: shortcuts) { shortcut -> String in
            shortcut.menuPath.first ?? "Other"
        }

        // Sort groups and shortcuts based on selected sort mode
        let sortedGroups: [(menuGroup: String, shortcuts: [ShortcutItem])]

        switch sortMode {
        case .alphabetical:
            // Sort both groups and shortcuts alphabetically
            sortedGroups = grouped.sorted { $0.key < $1.key }.map { (menuGroup: $0.key, shortcuts: $0.value.sorted { $0.title < $1.title }) }
        case .menuOrder:
            // Keep both groups and shortcuts in their original menu order
            // Groups are sorted by the order they appear in the original shortcuts array
            var seenGroups = Set<String>()
            var groupOrder: [String] = []
            for shortcut in shortcuts {
                if let firstMenu = shortcut.menuPath.first, !seenGroups.contains(firstMenu) {
                    seenGroups.insert(firstMenu)
                    groupOrder.append(firstMenu)
                }
            }

            sortedGroups = groupOrder.compactMap { menuGroup in
                guard let items = grouped[menuGroup] else { return nil }
                return (menuGroup: menuGroup, shortcuts: items)
            }
        }

        // Filter out hidden groups
        return sortedGroups.filter { !hiddenGroups.contains($0.menuGroup) }
    }

    /// Parses a shortcut string into individual key components
    /// Example: "⌘⇧N" -> ["⌘", "⇧", "N"]
    /// Example: "⌘F1" -> ["⌘", "F1"]
    /// Example: "⇧F10" -> ["⇧", "F10"]
    private func parseShortcutKeys(_ shortcut: String) -> [String] {
        var keys: [String] = []
        var currentKey = ""

        // Modifier symbols that should be separate keys
        let modifierSymbols: Set<Character> = ["⌘", "⇧", "⌥", "⌃"]

        // Special single-character symbols that should be separate keys
        let specialSymbols: Set<Character> = ["↑", "↓", "←", "→", "⌫", "⌦", "⎋", "↩", "⌅", "⇥", "↖", "↘", "⇞", "⇟", "⌧", "?⃝"]

        // Special multi-character keys that should stay together (sorted by length, longest first)
        let multiCharKeys = ["Space", "F20", "F19", "F18", "F17", "F16", "F15", "F14", "F13",
                             "F12", "F11", "F10", "F9", "F8", "F7", "F6", "F5", "F4", "F3", "F2", "F1"]

        var i = shortcut.startIndex
        while i < shortcut.endIndex {
            let char = shortcut[i]

            // Check if this is a modifier symbol or special symbol
            if modifierSymbols.contains(char) || specialSymbols.contains(char) {
                // Add any accumulated key first
                if !currentKey.isEmpty {
                    keys.append(currentKey)
                    currentKey = ""
                }
                // Add the symbol
                keys.append(String(char))
                i = shortcut.index(after: i)
                continue
            }

            // Check if we're starting a multi-character key
            var foundMultiCharKey = false
            for multiKey in multiCharKeys {
                let endIndex = shortcut.index(i, offsetBy: multiKey.count, limitedBy: shortcut.endIndex)
                if let endIndex = endIndex {
                    let substring = String(shortcut[i..<endIndex])
                    if substring == multiKey {
                        // Add any accumulated key first
                        if !currentKey.isEmpty {
                            keys.append(currentKey)
                            currentKey = ""
                        }
                        // Add the multi-character key
                        keys.append(multiKey)
                        i = endIndex
                        foundMultiCharKey = true
                        break
                    }
                }
            }

            if !foundMultiCharKey {
                // Regular character - accumulate it
                currentKey.append(char)
                i = shortcut.index(after: i)
            }
        }

        // Add any remaining accumulated key
        if !currentKey.isEmpty {
            keys.append(currentKey)
        }

        return keys
    }

    private var isShowingShortcuts: Bool {
        viewMode == .activeApp || selectedRecentApp != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Picker for mode switching (moved to top)
            HStack {
                Picker("", selection: $viewMode) {
                    Text("Active App").tag(ViewMode.activeApp)
                    Text("Recent Apps").tag(ViewMode.recentApps)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .focusable(false)
                .onChange(of: viewMode) { _, newMode in
                    searchQuery = ""
                    if newMode == .activeApp {
                        selectedRecentApp = nil
                        // Trigger reload of active app if needed
                        if let activeApp = appWatcher.activeAppInfo {
                            if accessibilityReader.displayedAppInfo?.bundleID != activeApp.bundleID {
                                accessibilityReader.refresh()
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)

            /* Commented out - Original header section
            // Header with back button support (only show when needed)
            if !headerTitle.isEmpty {
                HStack(spacing: 8) {
                    // Back button when viewing a selected recent app
                    if viewMode == .recentApps && selectedRecentApp != nil {
                        Button(action: {
                            selectedRecentApp = nil
                            searchQuery = ""
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    // App icon
                    if let icon = headerIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }

                    Text(headerTitle)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Divider
                Divider()
            }
            */

            // Header for selected recent app (with back button)
            if viewMode == .recentApps && selectedRecentApp != nil {
                HStack(spacing: 8) {
                    // Back button
                    Button(action: {
                        selectedRecentApp = nil
                        searchQuery = ""
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)

                    // App icon
                    if let icon = headerIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }

                    Text(headerTitle)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Divider
                Divider()
            }

            // Search field (only show when viewing shortcuts)
            if isShowingShortcuts {
                HStack(spacing: 8) {
                    // App icon (only for Active App mode)
                    if viewMode == .activeApp, let icon = headerIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 26, height: 26)
                            .onHover { hovering in
                                isHoveringIcon = hovering
                            }
                            .help(headerTitle)
                    }

                    // Search bar - takes remaining available width
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search shortcuts...", text: $searchQuery)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(6)
                    .layoutPriority(1)

                    // Export button (no background)
                    Button(action: {
                        exportShortcuts()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .help("Export shortcuts to Markdown")

                    // Sort menu button (three-dot menu)
                    Menu {
                        // Filter section
                        Section(header: Text("Filter Groups")) {
                            ForEach(availableGroups, id: \.self) { group in
                                Button(action: {
                                    toggleGroupVisibility(group)
                                }) {
                                    HStack {
                                        Text(group)
                                        Spacer()
                                        if !hiddenGroups.contains(group) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        Divider()

                        // Sort section
                        Section(header: Text("Sort Order")) {
                            Button(action: {
                                sortMode = .alphabetical
                            }) {
                                HStack {
                                    Text("Alphabetical Order")
                                    if sortMode == .alphabetical {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            Button(action: {
                                sortMode = .menuOrder
                            }) {
                                HStack {
                                    Text("Menu Order")
                                    if sortMode == .menuOrder {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(.thinMaterial)
                            .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Filter and sort shortcuts")
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            // Error state (only show when viewing shortcuts)
            if isShowingShortcuts, let error = accessibilityReader.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            // Content area - conditional based on mode
            if viewMode == .recentApps && selectedRecentApp == nil {
                // Recent Apps List
                recentAppsListView
            } else {
                // Shortcuts List (for active app or selected recent app)
                shortcutsListView
            }
        }
        .padding(12)
        .frame(width: 360, height: 500)
    }

    // MARK: - Computed Properties

    private var headerTitle: String {
        if viewMode == .recentApps {
            if let selectedApp = selectedRecentApp {
                return selectedApp.name
            } else {
                return "" // Hide header when showing recent apps list
            }
        } else {
            // Ensure we always return a valid app name, never nil or empty
            if let name = appWatcher.activeAppInfo?.name, !name.isEmpty {
                return name
            } else if let bundleID = appWatcher.activeAppInfo?.bundleID {
                // Fallback to bundle ID if name is not available
                return bundleID
            } else {
                return "No Active App"
            }
        }
    }

    private var headerIcon: NSImage? {
        if viewMode == .recentApps {
            return selectedRecentApp?.icon
        } else {
            return appWatcher.activeAppInfo?.app.icon
        }
    }

    // MARK: - View Components

    private var recentAppsListView: some View {
        Group {
            if recentAppsManager.recentApps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No recent apps")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(recentAppsManager.recentApps, id: \.bundleID) { recentApp in
                    HStack(spacing: 12) {
                        if let icon = recentApp.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        Text(recentApp.name)
                            .font(.body)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecentApp = recentApp
                        Task {
                            await accessibilityReader.readMenusForSpecificApp(recentApp.app)
                        }
                    }
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(Color.primary.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var shortcutsListView: some View {
        Group {
            if accessibilityReader.isReading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Reading shortcuts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredShortcuts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: searchQuery.isEmpty ? "keyboard" : "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(searchQuery.isEmpty ? "No shortcuts available" : "No shortcuts found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        ForEach(groupedShortcuts, id: \.menuGroup) { group in
                            VStack(alignment: .leading, spacing: 0) {
                                // Section header
                                Text(group.menuGroup)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)

                                // Divider below header
                                Divider()
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 4)

                                // Shortcuts in this group
                                ForEach(group.shortcuts) { item in
                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .foregroundColor(item.isEnabled ? .primary : .secondary)

                                            // Show submenu path if it exists (everything after the first menu)
                                            if item.menuPath.count > 1 {
                                                Text(item.menuPath.dropFirst().joined(separator: " > "))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        // Display each key in its own box
                                        if let shortcut = item.shortcut {
                                            HStack(spacing: 4) {
                                                ForEach(parseShortcutKeys(shortcut), id: \.self) { key in
                                                    Text(key)
                                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                        .foregroundColor(item.isEnabled ? .primary : .secondary)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.primary.opacity(0.08))
                                                        .cornerRadius(6)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .opacity(item.isEnabled ? 1.0 : 0.6)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    /// Toggles the visibility of a shortcut group
    private func toggleGroupVisibility(_ group: String) {
        if hiddenGroups.contains(group) {
            hiddenGroups.remove(group)
        } else {
            hiddenGroups.insert(group)
        }
    }

    /// Exports the current shortcuts to a Markdown file
    private func exportShortcuts() {
        let shortcuts = filteredShortcuts
        let appName = headerTitle

        guard !shortcuts.isEmpty else {
            NSLog("⚠️ ContentView: No shortcuts to export")
            return
        }

        MarkdownExporter.shared.exportToMarkdown(shortcuts: shortcuts, appName: appName)
    }
}

#Preview {
    ContentView()
}

