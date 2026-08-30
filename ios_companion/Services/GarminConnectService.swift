// GarminConnectService.swift
// Bridges Trio HealthKit data to the Garmin watch via the
// Connect IQ Companion App SDK (github.com/garmin/connectiq-companion-app-sdk-ios)

import Foundation
import ConnectIQ
import HealthKit

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
        refreshDevices()
    }

    func handleOpenURL(_ url: URL) -> Bool {
        // URL callbacks handled automatically by the SDK in v2+
        return true
    }

    func refreshDevices() {
        let devices = ConnectIQ.sharedInstance()?.connectedDevices() as? [IQDevice] ?? []
        connectedDevices = devices
        delegate?.deviceStatusChanged(connected: !devices.isEmpty)

        // Register for messages on each device's app instance
        for device in devices {
            if let app = IQApp(uuid: watchAppID, store: UUID(), device: device) {
                ConnectIQ.sharedInstance()?.register(forAppMessages: app, delegate: self)
            }
        }
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
