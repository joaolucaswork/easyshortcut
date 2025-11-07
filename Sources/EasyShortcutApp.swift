//
//  EasyShortcutApp.swift
//  easyshortcut
//
//  Modern SwiftUI App structure with AppKit-based menu bar
//

internal import SwiftUI

@main
struct EasyShortcutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No onboarding window - app runs as menu bar only
        Settings {
            EmptyView()
        }
    }
}

// AppDelegate to setup the status bar with AppKit
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status bar controller
        StatusBarController.shared.setupStatusBar()

        // Start monitoring active app changes
        AppWatcher.shared.startMonitoring()

        // Start monitoring recent apps
        RecentAppsManager.shared.startMonitoring()

        // Check permissions on app launch and request if needed
        // The system will show its own permission dialog
        if !PermissionsManager.shared.checkPermissions() {
            PermissionsManager.shared.requestPermissions()
        }
    }
}


