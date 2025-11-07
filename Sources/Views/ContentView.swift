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

    @State private var searchQuery = ""
    @State private var viewMode: ViewMode = .activeApp
    @State private var selectedRecentApp: RecentAppInfo?
    @State private var isHoveringIcon = false

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

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search shortcuts...", text: $searchQuery)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(6)
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
                List(filteredShortcuts) { item in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .foregroundColor(item.isEnabled ? .primary : .secondary)
                            Text(item.fullPath)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let shortcut = item.shortcut {
                            Text(shortcut)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isEnabled ? .primary : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                    .opacity(item.isEnabled ? 1.0 : 0.6)
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(Color.primary.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    ContentView()
}

