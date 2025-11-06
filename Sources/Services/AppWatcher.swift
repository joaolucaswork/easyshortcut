//
//  AppWatcher.swift
//  easyshortcut
//
//  Service for monitoring active application changes using NSWorkspace notifications.
//  Exposes active app information through Combine @Published properties for reactive updates.
//

import Foundation
import AppKit
import Combine

/// Represents the currently active application with all relevant information
struct ActiveAppInfo {
    /// The human-readable name of the active application
    let name: String?

    /// The bundle identifier of the active application (e.g., "com.apple.Safari")
    let bundleID: String?

    /// The full NSRunningApplication object for the active application
    let app: NSRunningApplication
}

/// Service class that monitors active application changes and exposes this information to subscribers.
/// Conforms to ObservableObject to enable SwiftUI views and other services to reactively respond to app switches.
@MainActor
final class AppWatcher: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance for easy access across the app
    static let shared = AppWatcher()

    // MARK: - Published Properties

    /// The currently active application information (single source of truth)
    @Published private(set) var activeAppInfo: ActiveAppInfo?

    /// The human-readable name of the currently active application
    /// - Note: Deprecated. Use `activeAppInfo.name` instead. Kept for backward compatibility.
    @Published private(set) var activeAppName: String? {
        didSet {
            // This setter is only for backward compatibility
            // The actual updates happen through activeAppInfo
        }
    }

    /// The bundle identifier of the currently active application (e.g., "com.apple.Safari")
    /// - Note: Deprecated. Use `activeAppInfo.bundleID` instead. Kept for backward compatibility.
    @Published private(set) var activeAppBundleID: String? {
        didSet {
            // This setter is only for backward compatibility
            // The actual updates happen through activeAppInfo
        }
    }

    /// The full NSRunningApplication object for the currently active application
    /// - Note: Deprecated. Use `activeAppInfo.app` instead. Kept for backward compatibility.
    @Published private(set) var activeApp: NSRunningApplication? {
        didSet {
            // This setter is only for backward compatibility
            // The actual updates happen through activeAppInfo
        }
    }

    /// Indicates whether the service is currently monitoring application changes
    @Published private(set) var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    /// Notification observer token for cleanup
    private var observer: (any NSObjectProtocol)?
    
    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern and prevent duplicate monitoring instances
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    /// Starts monitoring active application changes using NSWorkspace notifications
    func startMonitoring() {
        guard !isMonitoring else { return }

        // Set up notification observer for application activation
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Extract app info from notification in nonisolated context
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            // Call MainActor method asynchronously with extracted data
            Task { @MainActor [weak self] in
                self?.handleApplicationActivation(app: app)
            }
        }

        isMonitoring = true
        
        // Capture initial state - get the currently active application
        captureCurrentActiveApp()
    }
    
    /// Stops monitoring active application changes and cleans up observers
    /// - Parameter clearState: If true, clears all published properties. Defaults to false to preserve state for consumers.
    func stopMonitoring(clearState: Bool = false) {
        guard isMonitoring else { return }

        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }

        isMonitoring = false

        if clearState {
            // Clear the single source of truth
            activeAppInfo = nil

            // Clear backward compatibility properties
            activeAppName = nil
            activeAppBundleID = nil
            activeApp = nil
        }
    }
    
    // MARK: - Private Methods

    /// Handles application activation with the running application
    /// - Parameter app: The activated NSRunningApplication
    private func handleApplicationActivation(app: NSRunningApplication) {
        updateActiveApp(app)
    }
    
    /// Captures the currently active application on initialization
    private func captureCurrentActiveApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        updateActiveApp(app)
    }
    
    /// Updates all published properties with the new active application
    /// - Parameter app: The NSRunningApplication to set as active
    private func updateActiveApp(_ app: NSRunningApplication) {
        // Avoid redundant publishes if the incoming app matches the current one
        if let currentApp = activeAppInfo?.app {
            // Check if it's the same app by bundleIdentifier or processIdentifier
            let sameBundleID = app.bundleIdentifier == currentApp.bundleIdentifier && app.bundleIdentifier != nil
            let sameProcessID = app.processIdentifier == currentApp.processIdentifier

            if sameBundleID || sameProcessID {
                return
            }
        }

        // Update the single source of truth - this is the only property that should be updated directly
        activeAppInfo = ActiveAppInfo(
            name: app.localizedName,
            bundleID: app.bundleIdentifier,
            app: app
        )

        // Update backward compatibility properties by deriving from activeAppInfo
        activeAppName = activeAppInfo?.name
        activeAppBundleID = activeAppInfo?.bundleID
        activeApp = activeAppInfo?.app
    }
    
    // MARK: - Cleanup

    deinit {
        // Note: deinit is already isolated to MainActor since the class is @MainActor
        // We need to use assumeIsolated to safely call MainActor methods
        MainActor.assumeIsolated {
            stopMonitoring()
        }
    }
}

