//
//  PermissionsManager.swift
//  easyshortcut
//
//  Manages Accessibility permissions checking and monitoring.
//

internal import Foundation
internal import AppKit
@preconcurrency import ApplicationServices
internal import Observation

@MainActor
@Observable
final class PermissionsManager {

    // MARK: - Singleton

    static let shared = PermissionsManager()

    // MARK: - Observable Properties

    /// Current permission status
    private(set) var isAccessibilityGranted: Bool = false

    /// Whether we're currently monitoring for permission changes
    private(set) var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    private var monitoringTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        checkPermissions()
    }
    
    deinit {
        MainActor.assumeIsolated {
            stopMonitoring()
        }
    }
    
    // MARK: - Permission Checking
    
    /// Check if Accessibility permissions are granted
    @discardableResult
    func checkPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        let wasGranted = isAccessibilityGranted
        isAccessibilityGranted = trusted

        if trusted {
            print("✅ PermissionsManager: Accessibility permissions granted")

            // If permissions just became granted, trigger a refresh
            if !wasGranted {
                print("🔄 PermissionsManager: Permissions newly granted, triggering AccessibilityReader refresh")
                AccessibilityReader.shared.refresh()
            }
        } else {
            print("⚠️ PermissionsManager: Accessibility permissions NOT granted")
        }

        return trusted
    }
    
    /// Request Accessibility permissions (opens System Settings)
    nonisolated func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        
        Task { @MainActor in
            checkPermissions()
        }
    }
    
    /// Open System Settings to Accessibility page
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Monitoring
    
    /// Start monitoring for permission changes
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Poll every 0.5 seconds to detect when user grants permission
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPermissions()
            }
        }
    }
    
    /// Stop monitoring for permission changes
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
    }
}

