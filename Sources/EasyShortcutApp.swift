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
    @State private var showOnboarding = false

    var body: some Scene {
        // Onboarding window
        Window("Setup", id: "onboarding") {
            OnboardingView {
                // Close onboarding when complete
                NSApplication.shared.keyWindow?.close()
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 450)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }
}

// AppDelegate to setup the status bar with AppKit
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status bar controller
        StatusBarController.shared.setupStatusBar()

        // Start monitoring active app changes
        AppWatcher.shared.startMonitoring()

        // Start monitoring recent apps
        RecentAppsManager.shared.startMonitoring()

        // Check permissions on app launch
        if !PermissionsManager.shared.checkPermissions() {
            // Request permissions which will show system dialog
            PermissionsManager.shared.requestPermissions()

            // Create and show onboarding window
            showOnboardingWindow()
        }
    }

    private func showOnboardingWindow() {
        let onboardingView = OnboardingView {
            // Close onboarding when complete
            self.onboardingWindow?.close()
            self.onboardingWindow = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Setup"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setContentSize(NSSize(width: 500, height: 450))
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.onboardingWindow = window
    }
}


