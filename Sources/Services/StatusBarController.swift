//
//  StatusBarController.swift
//  easyshortcut
//
//  Manages the menu bar icon with separate left-click and right-click actions
//

internal import AppKit
internal import SwiftUI

@MainActor
internal final class StatusBarController: NSObject {
    internal static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    var shouldShowOnboarding: (() -> Void)?

    private override init() {
        super.init()
    }

    internal func setupStatusBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Set icon
        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "easyshortcut")

        // Set action and target
        button.action = #selector(handleClick(_:))
        button.target = self

        // Enable both left and right mouse clicks
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Create popover for left-click
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
    }
    
    @objc private func handleClick(_ sender: NSButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click: Show menu
            showContextMenu()
        } else {
            // Left-click: Toggle popover
            togglePopover(sender)
        }
    }
    
    private func togglePopover(_ sender: NSButton) {
        guard let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()

        // Recent Apps submenu
        let recentAppsItem = NSMenuItem(
            title: "Recent Apps",
            action: nil,
            keyEquivalent: ""
        )
        let recentAppsSubmenu = createRecentAppsSubmenu()
        recentAppsItem.submenu = recentAppsSubmenu
        menu.addItem(recentAppsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Refresh Current App",
            action: #selector(refreshCurrentApp),
            keyEquivalent: "r"
        ))

        menu.addItem(NSMenuItem(
            title: "Clear All Cache",
            action: #selector(clearAllCache),
            keyEquivalent: "k"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // Set target for custom actions
        menu.items.forEach { item in
            if item.action == #selector(refreshCurrentApp) || item.action == #selector(clearAllCache) {
                item.target = self
            }
        }

        // Show menu
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        // Clear menu to prevent it from staying attached
        statusItem?.menu = nil
    }

    private func createRecentAppsSubmenu() -> NSMenu {
        let submenu = NSMenu()

        let recentApps = RecentAppsManager.shared.recentApps

        if recentApps.isEmpty {
            let emptyItem = NSMenuItem(
                title: "No recent apps",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            for recentApp in recentApps {
                let menuItem = NSMenuItem(
                    title: recentApp.name,
                    action: #selector(showShortcutsForRecentApp(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.image = recentApp.icon
                menuItem.image?.size = NSSize(width: 16, height: 16)
                menuItem.representedObject = recentApp.bundleID
                submenu.addItem(menuItem)
            }
        }

        return submenu
    }

    @objc private func showShortcutsForRecentApp(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }

        // Find the app in recent apps
        guard let recentApp = RecentAppsManager.shared.recentApps.first(where: { $0.bundleID == bundleID }) else {
            return
        }

        // Show popover with shortcuts for this app
        showPopoverForApp(recentApp.app)
    }

    private func showPopoverForApp(_ app: NSRunningApplication) {
        guard let button = statusItem?.button else { return }
        guard let popover = popover else { return }

        // Read menus for the specific app
        Task {
            await AccessibilityReader.shared.readMenusForSpecificApp(app)

            // Show the popover after loading shortcuts
            if !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc private func refreshCurrentApp() {
        AccessibilityReader.shared.refresh()
    }

    @objc private func clearAllCache() {
        AccessibilityReader.shared.clearCache()
    }
}

