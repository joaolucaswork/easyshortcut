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
    var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("🚀 [DEBUG] App launched - applicationDidFinishLaunching called")

        // Show alert to confirm app is running
        let alert = NSAlert()
        alert.messageText = "easyshortcut Debug"
        alert.informativeText = "App launched successfully! Click OK to continue."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()

        // Check if permissions are granted
        let permissionsManager = PermissionsManager.shared
        let hasPermissions = permissionsManager.checkPermissions()

        NSLog("🔐 [DEBUG] Accessibility permissions granted: \(hasPermissions)")

        if hasPermissions {
            NSLog("✅ [DEBUG] Initializing app with permissions")
            // Permissions already granted, start the app normally
            initializeApp()
        } else {
            NSLog("⚠️ [DEBUG] No permissions - showing onboarding window")
            // Show onboarding window
            showOnboarding()
        }
    }

    private func initializeApp() {
        NSLog("🎯 [DEBUG] Initializing StatusBarController")
        statusBarController = StatusBarController()
        NSLog("✅ [DEBUG] StatusBarController initialized")
    }

    private func showOnboarding() {
        NSLog("📋 [DEBUG] Creating OnboardingWindowController")
        onboardingWindowController = OnboardingWindowController { [weak self] in
            NSLog("✅ [DEBUG] Onboarding completed - permissions granted")
            // Called when onboarding is complete
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
            self?.initializeApp()
        }
        NSLog("🪟 [DEBUG] Showing onboarding window")
        onboardingWindowController?.show()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        statusBarController = nil
        onboardingWindowController = nil
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

