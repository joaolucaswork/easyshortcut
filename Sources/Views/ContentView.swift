//
//  ContentView.swift
//  easyshortcut
//
//  Main SwiftUI view displayed inside the popover.
//  Contains the search field and shortcuts list.
//

internal import SwiftUI

struct ContentView: View {
    @State private var searchQuery = ""
    @ObservedObject private var accessibilityReader = AccessibilityReader.shared
    @ObservedObject private var appWatcher = AppWatcher.shared

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

    var body: some View {
        VStack(spacing: 0) {
            // Active app header
            HStack {
                if let appName = appWatcher.activeAppInfo?.name {
                    Text(appName)
                        .font(.headline)
                        .fontWeight(.bold)
                } else {
                    Text("No Active App")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Cache indicator
                if accessibilityReader.isUsingCache {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Cached")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search shortcuts...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 8)

            // Error state
            if let error = accessibilityReader.lastError {
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

            // Shortcuts list
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
                List(filteredShortcuts, id: \.fullPath) { item in
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
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                    .opacity(item.isEnabled ? 1.0 : 0.6)
                }
                .listStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 360, height: 500)
    }
}

#Preview {
    ContentView()
}

