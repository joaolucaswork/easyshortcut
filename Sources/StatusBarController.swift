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
    private var statusItem: NSStatusItem?
    
    // The popover window that displays the shortcuts list
    private var popover: NSPopover?
    
    init() {
        // Next phase: Initialize NSStatusItem
        // statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Next phase: Configure the status item button
        // if let button = statusItem?.button {
        //     button.image = NSImage(named: "StatusIcon")
        //     button.image?.isTemplate = true  // Allows automatic light/dark mode adaptation
        //     button.action = #selector(togglePopover)
        //     button.target = self
        // }
        
        // Next phase: Initialize NSPopover
        // popover = NSPopover()
        // popover?.contentSize = NSSize(width: 360, height: 500)
        // popover?.behavior = .transient  // Auto-closes when clicking outside
        // popover?.contentViewController = NSHostingController(rootView: ContentView())
    }
    
    // Next phase: Implement popover toggle functionality
    // @objc func togglePopover() {
    //     if let button = statusItem?.button {
    //         if popover?.isShown == true {
    //             hidePopover()
    //         } else {
    //             showPopover()
    //         }
    //     }
    // }
    
    func showPopover() {
        // Next phase: Show the popover relative to the status bar button
        // if let button = statusItem?.button {
        //     popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // }
    }
    
    func hidePopover() {
        // Next phase: Hide the popover
        // popover?.performClose(nil)
    }
}

