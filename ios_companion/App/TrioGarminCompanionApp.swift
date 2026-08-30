// TrioGarminCompanionApp.swift
// Minimal iOS app that keeps TrioBridgeService running in the background,
// forwarding Trio CGM data to the Garmin watch.

import SwiftUI

@main
struct TrioGarminCompanionApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            CompanionRootView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        TrioBridgeService.shared.start()
        return true
    }

    // Required: pass SDK callbacks back to ConnectIQ
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GarminConnectService.shared.handleOpenURL(url)
    }
}

// MARK: - Simple status UI
struct CompanionRootView: View {
    @State private var isConnected = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("Trio Garmin Companion")
                .font(.title2.bold())

            if isConnected {
                Label("Watch connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Text("Open **Trio Glucose** on your Garmin watch to connect.\nThen keep this app running in the background.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .garminDeviceConnected)) { _ in
            isConnected = true
        }
    }
}

extension Notification.Name {
    static let garminDeviceConnected = Notification.Name("garminDeviceConnected")
}
