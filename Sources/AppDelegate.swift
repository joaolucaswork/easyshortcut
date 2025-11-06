//
//  AppDelegate.swift
//  easyshortcut
//
//  Main entry point for the AppKit-based application lifecycle.
//  This approach is necessary because menu bar apps require AppKit's NSApplication
//  lifecycle, not SwiftUI's App protocol which doesn't provide direct access to NSStatusBar.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // StatusBarController will be instantiated here in the next phase
    // var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the StatusBarController here in the next phase
        // statusBarController = StatusBarController()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Cleanup code will be added here in future phases
        // - Remove status bar item
        // - Stop monitoring active applications
        // - Release resources
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

