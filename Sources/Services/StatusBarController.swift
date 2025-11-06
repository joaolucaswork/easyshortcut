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
    
    @objc private func refreshCurrentApp() {
        AccessibilityReader.shared.refresh()
    }
    
    @objc private func clearAllCache() {
        AccessibilityReader.shared.clearCache()
    }
}

