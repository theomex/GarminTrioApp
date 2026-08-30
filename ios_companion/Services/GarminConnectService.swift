// GarminConnectService.swift
// Bridges Trio HealthKit data to the Garmin watch via the
// Connect IQ Companion App SDK (github.com/garmin/connectiq-companion-app-sdk-ios)
//
// Device discovery: the watch app initiates contact by sending a "hello" or
// "request_update" message. We capture the IQDevice from that first message
// and register for app messages on it. No showDeviceSelection() required.

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
    private(set) var connectedDevices: [IQDevice] = []

    private override init() { super.init() }

    func setup() {
        ConnectIQ.sharedInstance()?.initialize(
            withUrlScheme: "trio-garmin",
            uiOverrideDelegate: nil
        )
    }

    // Called from AppDelegate — handles URL callbacks from Garmin Connect
    func handleOpenURL(_ url: URL) -> Bool {
        guard let devices = ConnectIQ.sharedInstance()?
            .parseDeviceSelectionResponse(from: url) as? [IQDevice],
              !devices.isEmpty else {
            return false
        }
        registerDevices(devices)
        return true
    }

    // Called when the watch sends us its first message — we learn the device from it
    func registerDevice(_ device: IQDevice) {
        guard !connectedDevices.contains(where: { $0.uuid == device.uuid }) else { return }
        registerDevices(connectedDevices + [device])
    }

    private func registerDevices(_ devices: [IQDevice]) {
        connectedDevices = devices
        delegate?.deviceStatusChanged(connected: !devices.isEmpty)
        if !devices.isEmpty {
            NotificationCenter.default.post(name: .garminDeviceConnected, object: nil)
        }
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
        // Learn the device from the first message the watch sends
        registerDevice(app.device)

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
