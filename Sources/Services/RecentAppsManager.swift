//
//  RecentAppsManager.swift
//  easyshortcut
//
//  Manages tracking of recently opened applications for quick access
//

internal import Foundation
internal import AppKit

/// Represents a recently used application with metadata
struct RecentAppInfo: Sendable {
    /// The human-readable name of the application
    let name: String
    
    /// The bundle identifier of the application
    let bundleID: String
    
    /// The application icon
    let icon: NSImage?
    
    /// When this app was last activated
    let lastActivated: Date
    
    /// The running application reference (for fetching shortcuts)
    let app: NSRunningApplication
}

/// Service class that tracks recently opened applications
@MainActor
final class RecentAppsManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared singleton instance
    static let shared = RecentAppsManager()
    
    // MARK: - Published Properties
    
    /// List of recently used applications, ordered by most recent first
    @Published private(set) var recentApps: [RecentAppInfo] = []
    
    // MARK: - Private Properties
    
    /// Maximum number of recent apps to track
    private let maxRecentApps = 10
    
    /// Notification observer for app activation
    private var observer: (any NSObjectProtocol)?
    
    /// Whether monitoring is active
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Starts monitoring application activations
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Set up notification observer for application activation
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Extract app info from notification
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            
            // Call MainActor method asynchronously
            Task { @MainActor [weak self] in
                self?.handleApplicationActivation(app: app)
            }
        }
        
        isMonitoring = true
        NSLog("📱 RecentAppsManager: Started monitoring app activations")
    }
    
    /// Stops monitoring application activations
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        
        isMonitoring = false
        NSLog("📱 RecentAppsManager: Stopped monitoring app activations")
    }
    
    /// Clears all recent apps history
    func clearRecentApps() {
        recentApps.removeAll()
        NSLog("🗑️ RecentAppsManager: Cleared recent apps history")
    }
    
    // MARK: - Private Methods
    
    /// Handles application activation and updates recent apps list
    private func handleApplicationActivation(app: NSRunningApplication) {
        // Skip our own app
        if app.bundleIdentifier == Bundle.main.bundleIdentifier {
            return
        }
        
        // Skip apps without bundle identifiers
        guard let bundleID = app.bundleIdentifier else {
            return
        }
        
        // Skip system apps and background processes
        guard app.activationPolicy == .regular else {
            return
        }
        
        // Remove existing entry for this app if present
        recentApps.removeAll { $0.bundleID == bundleID }
        
        // Create new recent app info
        let recentApp = RecentAppInfo(
            name: app.localizedName ?? "Unknown",
            bundleID: bundleID,
            icon: app.icon,
            lastActivated: Date(),
            app: app
        )
        
        // Insert at the beginning (most recent)
        recentApps.insert(recentApp, at: 0)
        
        // Trim to max size
        if recentApps.count > maxRecentApps {
            recentApps = Array(recentApps.prefix(maxRecentApps))
        }
        
        NSLog("📱 RecentAppsManager: Added \(recentApp.name) to recent apps (total: \(recentApps.count))")
    }
    
    // MARK: - Cleanup
    
    deinit {
        MainActor.assumeIsolated {
            stopMonitoring()
        }
    }
}

