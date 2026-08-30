// GarminConnectService.swift
// Bridges Trio HealthKit / Loop data to the Garmin watch via the
// Connect IQ Companion App SDK (github.com/garmin/connectiq-companion-app-sdk-ios)
//
// Setup:
//   1. Add ConnectIQ.xcframework from the SDK to your Xcode project.
//   2. Add URL scheme "trio-garmin" to Info.plist (CFBundleURLSchemes).
//   3. Register that scheme in Garmin Connect app settings so the SDK can callback.

import Foundation
import ConnectIQ     // ConnectIQ.xcframework from the Garmin SDK
import HealthKit

// MARK: - Delegate protocol
protocol GarminConnectServiceDelegate: AnyObject {
    func didReceiveBolusRequest(units: Double)
    func didReceiveRefreshRequest()
    func deviceStatusChanged(connected: Bool)
}

final class GarminConnectService: NSObject {

    static let shared = GarminConnectService()

    // The Garmin app UUID must match manifest.xml id= field exactly
    private let watchAppID = UUID(uuidString: "a3d8e4f2-1b5c-4d9a-8e7f-2c1b0a9d8e7f")!

    weak var delegate: GarminConnectServiceDelegate?
    private var connectedDevices: [IQDevice] = []
    private var watchApp: IQApp?

    private override init() { super.init() }

    // Call from AppDelegate.application(_:didFinishLaunchingWithOptions:)
    func setup() {
        ConnectIQ.sharedInstance()?.initialize(
            withUrlScheme: "trio-garmin",
            uiOverrideDelegate: nil
        )
        ConnectIQ.sharedInstance()?.register(forAppMessages: self, app: currentApp())
        refreshDevices()
    }

    // Call from AppDelegate.application(_:open:options:) to handle SDK callbacks
    func handleOpenURL(_ url: URL) -> Bool {
        ConnectIQ.sharedInstance()?.handleOpenURL(url)
        return true
    }

    // MARK: - Device management
    func refreshDevices() {
        ConnectIQ.sharedInstance()?.getConnectedDevices { [weak self] devices in
            guard let self, let devices = devices as? [IQDevice] else { return }
            self.connectedDevices = devices
            self.delegate?.deviceStatusChanged(connected: !devices.isEmpty)
        }
    }

    private func currentApp() -> IQApp {
        if let app = watchApp { return app }
        // Returns an IQApp targeting all paired devices for now
        let app = IQApp(uuid: watchAppID, store: UUID(), device: connectedDevices.first)
        watchApp = app
        return app!
    }

    // MARK: - Sending data to watch
    func sendGlucoseUpdate(_ msg: GlucoseUpdateMessage) {
        send(msg.toDict())
    }

    func sendPumpStatus(_ msg: PumpStatusMessage) {
        send(msg.toDict())
    }

    func sendBolusResponse(_ msg: BolusResponseMessage) {
        send(msg.toDict())
    }

    private func send(_ dict: [String: Any]) {
        guard !connectedDevices.isEmpty else { return }
        ConnectIQ.sharedInstance()?.sendMessage(
            dict,
            to: currentApp(),
            progress: nil
        ) { result in
            if result != IQSendMessageResult.SUCCESS {
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
                DispatchQueue.main.async {
                    self.delegate?.didReceiveBolusRequest(units: units)
                }
            }
        case "request_update":
            DispatchQueue.main.async {
                self.delegate?.didReceiveRefreshRequest()
            }
        default:
            break
        }
    }
}
