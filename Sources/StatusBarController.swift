//
//  StatusBarController.swift
//  easyshortcut
//
//  Manages the menu bar icon (NSStatusItem) and popover window (NSPopover).
//  Reference: /Users/lucas/Documents/GitHub/easyshortcut/keyscope_spec.md
//
//  This class will be responsible for:
//  - Creating and configuring the NSStatusItem in the system menu bar
//  - Managing the NSPopover that displays the SwiftUI content view
//  - Handling user interactions (clicks on menu bar icon)
//  - Showing/hiding the popover window
//

import Cocoa
import SwiftUI

class StatusBarController {

    // The menu bar item that appears in the system status bar
    private let statusItem: NSStatusItem

    // The popover window that displays the shortcuts list
    private let popover: NSPopover

    init() {
        // Initialize NSStatusItem with local variable
        let statusItemLocal = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Guard against missing button
        guard let button = statusItemLocal.button else {
            fatalError("Failed to create status item button")
        }

        // Configure the status item button
        button.image = NSImage(named: "StatusIcon")
        button.image?.isTemplate = true  // Allows automatic light/dark mode adaptation
        button.action = #selector(togglePopover(_:))
        button.target = self

        // Initialize NSPopover with local variable
        let popoverLocal = NSPopover()
        popoverLocal.contentSize = NSSize(width: 360, height: 500)
        popoverLocal.behavior = .transient  // Auto-closes when clicking outside
        popoverLocal.contentViewController = NSHostingController(rootView: ContentView())

        // Assign to non-optional properties after successful initialization
        self.statusItem = statusItemLocal
        self.popover = popoverLocal
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func hidePopover() {
        popover.performClose(nil)
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

