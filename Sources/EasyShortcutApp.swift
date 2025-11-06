//
//  EasyShortcutApp.swift
//  easyshortcut
//
//  Modern SwiftUI App structure using MenuBarExtra
//

internal import SwiftUI

@main
struct EasyShortcutApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("easyshortcut", systemImage: "keyboard") {
            ContentView()
                .frame(width: 360, height: 500)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Color.clear
                    .onAppear {
                        // Start monitoring active app changes
                        AppWatcher.shared.startMonitoring()

                        // Check permissions on app launch
                        if !PermissionsManager.shared.checkPermissions() {
                            // Request permissions which will show system dialog
                            PermissionsManager.shared.requestPermissions()
                            // Open onboarding window
                            openWindow(id: "onboarding")
                        }
                    }
            }
        }

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


