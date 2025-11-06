//
//  AppDelegate.swift
//  easyshortcut
//
//  Main entry point for the AppKit-based application lifecycle.
//  This approach is necessary because menu bar apps require AppKit's NSApplication
//  lifecycle, not SwiftUI's App protocol which doesn't provide direct access to NSStatusBar.
//

internal import Cocoa
internal import SwiftUI

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarController = StatusBarController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        statusBarController = nil
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

