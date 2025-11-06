//
//  OnboardingWindow.swift
//  easyshortcut
//
//  Native macOS onboarding window for Accessibility permissions.
//

internal import SwiftUI
internal import AppKit

/// SwiftUI view for the onboarding content
struct OnboardingView: View {
    @Bindable var permissionsManager = PermissionsManager.shared
    @State private var showingSuccess = false
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)
            
            // Title
            Text("Welcome to easyshortcut")
                .font(.system(size: 24, weight: .bold))
            
            // Description
            VStack(spacing: 12) {
                Text("To show keyboard shortcuts from other apps, easyshortcut needs Accessibility permissions.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("This allows the app to read menu structures and display shortcuts for the active application.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 400)
            
            // Permission Status
            HStack(spacing: 8) {
                Image(systemName: permissionsManager.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(permissionsManager.isAccessibilityGranted ? .green : .orange)
                    .font(.system(size: 16))
                    .symbolEffect(.bounce, value: permissionsManager.isAccessibilityGranted)

                Text(permissionsManager.isAccessibilityGranted ? "Accessibility permissions granted ✓" : "Accessibility permissions required")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(permissionsManager.isAccessibilityGranted ? .green : .primary)
            }
            .padding(.vertical, 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: permissionsManager.isAccessibilityGranted)
            
            // Action Button
            if !permissionsManager.isAccessibilityGranted {
                Button(action: {
                    permissionsManager.openAccessibilitySettings()
                    permissionsManager.startMonitoring()
                }) {
                    Text("Open System Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .frame(width: 250)
                
                Text("Click the button above to open System Settings, then enable easyshortcut in the Accessibility list.")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 350)
            } else {
                Button(action: {
                    onComplete()
                }) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .frame(width: 250)
            }
        }
        .padding(40)
        .frame(width: 500, height: 450)
        .onChange(of: permissionsManager.isAccessibilityGranted) { _, isGranted in
            if isGranted {
                print("✅ OnboardingView: Accessibility permission detected! Auto-closing in 1 second...")
                showingSuccess = true

                // Auto-close after a short delay when permission is granted
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    permissionsManager.stopMonitoring()
                    onComplete()
                }
            }
        }
        .onAppear {
            // Start monitoring when view appears
            if !permissionsManager.isAccessibilityGranted {
                print("ℹ️ OnboardingView: Starting permission monitoring...")
                permissionsManager.startMonitoring()
            }
        }
        .onDisappear {
            // Stop monitoring when view disappears
            permissionsManager.stopMonitoring()
        }
    }
}



