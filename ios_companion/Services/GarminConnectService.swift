// GarminConnectService.swift
// Bridges Trio HealthKit data to the Garmin watch via the
// Connect IQ Companion App SDK (github.com/garmin/connectiq-companion-app-sdk-ios)

import Foundation
import UIKit
import ConnectIQ

// MARK: - Delegate protocol
protocol GarminConnectServiceDelegate: AnyObject {
    func didReceiveBolusRequest(units: Double)
    func didReceiveRefreshRequest()
    func deviceStatusChanged(connected: Bool)
}

final class GarminConnectService: NSObject {

    static let shared = GarminConnectService()

    private let watchAppID = UUID(uuidString: "a3d8e4f2-1b5c-4d9a-8e7f-2c1b0a9d8e7f")!

    weak var delegate: GarminConnectServiceDelegate?
    private var connectedDevices: [IQDevice] = []

    private override init() { super.init() }

    func setup() {
        ConnectIQ.sharedInstance()?.initialize(
            withUrlScheme: "trio-garmin",
            uiOverrideDelegate: nil
        )
    }

    func connectWatch() {
        // Try the SDK's device picker first; if Garmin Connect isn't detected,
        // fall back to opening the app directly so the user can launch it.
        let schemes = ["gcm", "garminconnect", "garmin-connect", "garmin"]
        let canOpen = schemes.contains { URLComponents(string: "\($0)://")
            .flatMap { $0.url }
            .map { UIApplication.shared.canOpenURL($0) } ?? false }

        if canOpen {
            ConnectIQ.sharedInstance()?.showDeviceSelection()
        } else {
            // Open Garmin Connect from the App Store as a fallback
            let appStoreURL = URL(string: "https://apps.apple.com/app/garmin-connect/id583446403")!
            UIApplication.shared.open(appStoreURL)
        }
    }

    // Called from AppDelegate.application(_:open:options:)
    func handleOpenURL(_ url: URL) -> Bool {
        guard let devices = ConnectIQ.sharedInstance()?
            .parseDeviceSelectionResponse(from: url) as? [IQDevice] else {
            return false
        }
        connectedDevices = devices
        delegate?.deviceStatusChanged(connected: !devices.isEmpty)

        for device in devices {
            if let app = IQApp(uuid: watchAppID, store: UUID(), device: device) {
                ConnectIQ.sharedInstance()?.register(forAppMessages: app, delegate: self)
            }
        }
        return true
    }

    // MARK: - Sending data to watch
    func sendGlucoseUpdate(_ msg: GlucoseUpdateMessage) { send(msg.toDict()) }
    func sendPumpStatus(_ msg: PumpStatusMessage)       { send(msg.toDict()) }
    func sendBolusResponse(_ msg: BolusResponseMessage) { send(msg.toDict()) }

    private func send(_ dict: [String: Any]) {
        guard let device = connectedDevices.first,
              let app = IQApp(uuid: watchAppID, store: UUID(), device: device) else { return }
        ConnectIQ.sharedInstance()?.sendMessage(dict, to: app, progress: nil) { result in
            if result != .success {
                print("[GarminConnectService] Send failed: \(result.rawValue)")
            }
        }
    }
}

// MARK: - Receiving messages from the watch
extension GarminConnectService: IQAppMessageDelegate {
    func receivedMessage(_ message: Any, from app: IQApp) {
        guard let dict = message as? [String: Any],
              let type = dict["type"] as? String else { return }

        switch type {
        case "bolus_request":
            if let units = dict["units"] as? Double {
                DispatchQueue.main.async { self.delegate?.didReceiveBolusRequest(units: units) }
            }
        case "request_update":
            DispatchQueue.main.async { self.delegate?.didReceiveRefreshRequest() }
        default:
            break
        }
    }
}
