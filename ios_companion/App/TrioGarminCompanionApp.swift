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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("Trio Garmin Companion")
                .font(.title2.bold())
            Text("Running in the background.\nKeep this app open to sync\nglucose data to your Garmin watch.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
