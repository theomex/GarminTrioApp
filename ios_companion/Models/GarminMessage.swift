// GarminMessage.swift — Typed messages sent to/from the Garmin watch

import Foundation

enum GarminMessageType: String {
    case glucoseUpdate = "glucose_update"
    case bolusRequest  = "bolus_request"
    case bolusResponse = "bolus_response"
    case pumpStatus    = "pump_status"
    case requestUpdate = "request_update"
}

struct GlucoseUpdateMessage: Codable {
    let type: String
    let glucoseMgdl: Int
    let glucoseMmol: Double
    let trend: String          // e.g. "↗"
    let timestamp: Int         // unix epoch seconds
    let iob: Double
    let cob: Int

    enum CodingKeys: String, CodingKey {
        case type
        case glucoseMgdl  = "glucose_mgdl"
        case glucoseMmol  = "glucose_mmol"
        case trend, timestamp, iob, cob
    }

    func toDict() -> [String: Any] {
        [
            "type":         type,
            "glucose_mgdl": glucoseMgdl,
            "glucose_mmol": glucoseMmol,
            "trend":        trend,
            "timestamp":    timestamp,
            "iob":          iob,
            "cob":          cob
        ]
    }
}

struct PumpStatusMessage {
    let connected: Bool
    let reservoirUnits: Double
    let batteryPct: Int
    let tempBasalActive: Bool
    let tempBasalRate: Double

    func toDict() -> [String: Any] {
        [
            "type":              "pump_status",
            "connected":         connected,
            "reservoir":         reservoirUnits,
            "battery":           batteryPct,
            "temp_basal_active": tempBasalActive,
            "temp_basal_rate":   tempBasalRate
        ]
    }
}

struct BolusResponseMessage {
    let status: String  // "delivered" | "rejected" | "error"

    func toDict() -> [String: Any] {
        ["type": "bolus_response", "status": status]
    }
}
