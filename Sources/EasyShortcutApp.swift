//
//  EasyShortcutApp.swift
//  easyshortcut
//
//  Modern SwiftUI App structure using MenuBarExtra
//

internal import SwiftUI

@main
struct EasyShortcutApp: App {
    @State private var permissionsManager = PermissionsManager.shared
    @State private var showOnboarding = false
    
    var body: some Scene {
        MenuBarExtra("easyshortcut", systemImage: "keyboard") {
            ContentView()
                .frame(width: 360, height: 500)
        }
        .menuBarExtraStyle(.window)
        
        // Onboarding window
        Window("Setup", id: "onboarding") {
            OnboardingView {
                // Close onboarding when complete
                if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.close()
                }
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 450)
        .windowStyle(.hiddenTitleBar)
    }
    
    init() {
        // Check permissions on launch
        let hasPermissions = PermissionsManager.shared.checkPermissions()
        
        if !hasPermissions {
            // Show onboarding window
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}

