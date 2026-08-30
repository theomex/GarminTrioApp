// TrioBridgeService.swift
// Reads live glucose + IOB/COB from HealthKit (where Trio writes it)
// and forwards it to the Garmin watch at a regular cadence.
// Also handles bolus requests coming back from the watch.

import Foundation
import HealthKit

final class TrioBridgeService: GarminConnectServiceDelegate {

    static let shared = TrioBridgeService()
    private let healthKit = HKHealthStore()
    private var refreshTimer: Timer?
    private let garmin = GarminConnectService.shared

    // Trio writes glucose to HK as blood glucose samples
    private let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
    private let iobType     = HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!

    private init() {}

    func start() {
        garmin.delegate = self
        garmin.setup()
        requestHealthKitPermissions()
        scheduleRefresh()
    }

    // MARK: - HealthKit
    private func requestHealthKitPermissions() {
        let readTypes: Set<HKObjectType> = [glucoseType, iobType]
        healthKit.requestAuthorization(toShare: nil, read: readTypes) { _, _ in
            self.fetchAndSend()
        }
    }

    private func scheduleRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchAndSend()
        }
    }

    func fetchAndSend() {
        fetchLatestGlucose { [weak self] glucose, trend in
            guard let self, let glucose else { return }
            self.fetchIOBandCOB { iob, cob in
                let mgdl = Int(glucose.doubleValue(for: .count()) * 18.0)
                let mmol = glucose.doubleValue(for: HKUnit(from: "mmol/L"))
                let msg = GlucoseUpdateMessage(
                    type:        "glucose_update",
                    glucoseMgdl: mgdl,
                    glucoseMmol: mmol,
                    trend:       trend,
                    timestamp:   Int(Date().timeIntervalSince1970),
                    iob:         iob,
                    cob:         cob
                )
                self.garmin.sendGlucoseUpdate(msg)
            }
        }
    }

    private func fetchLatestGlucose(completion: @escaping (HKQuantity?, String) -> Void) {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: glucoseType,
            predicate: HKQuery.predicateForSamples(
                withStart: Date(timeIntervalSinceNow: -600),
                end: Date()
            ),
            limit: 3,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], samples.count > 0 else {
                completion(nil, "---")
                return
            }
            let latest = samples[0].quantity
            let trend  = samples.count > 1 ? self.trendArrow(samples) : "→"
            completion(latest, trend)
        }
        healthKit.execute(query)
    }

    private func trendArrow(_ samples: [HKQuantitySample]) -> String {
        let unit = HKUnit(from: "mg/dL")
        let v0 = samples[0].quantity.doubleValue(for: unit)
        let v1 = samples[1].quantity.doubleValue(for: unit)
        let delta = v0 - v1
        switch delta {
        case let d where d > 3:  return "↑↑"
        case let d where d > 1:  return "↑"
        case let d where d > 0:  return "↗"
        case let d where d < -3: return "↓↓"
        case let d where d < -1: return "↓"
        case let d where d < 0:  return "↘"
        default:                  return "→"
        }
    }

    private func fetchIOBandCOB(completion: @escaping (Double, Int) -> Void) {
        // Trio writes IOB as an HKQuantitySample with metadata key "com.trio.iob"
        // If that isn't available, sum recent insulin delivery samples.
        // For COB, Trio writes it similarly. Fallback to 0.
        completion(0.0, 0) // TODO: integrate Trio's HealthKit metadata
    }

    // MARK: - GarminConnectServiceDelegate
    func didReceiveBolusRequest(units: Double) {
        // Bolus confirmed on the watch (two-step: dose picker + confirm screen).
        // Deliver immediately without a second prompt on the phone.
        sendBolusToTrio(units: units)
    }

    func didReceiveRefreshRequest() {
        fetchAndSend()
    }

    func deviceStatusChanged(connected: Bool) {
        if connected { fetchAndSend() }
    }

    private func sendBolusToTrio(units: Double) {
        // In a real integration this would call Trio's local API or write an HK insulin dose.
        // Trio listens on localhost:1979 (OpenAPS/Trio REST) when the Trio app is running.
        guard let url = URL(string: "http://127.0.0.1:1979/api/v1/treatments.json") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "eventType": "Bolus",
            "insulin":   units,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ])
        URLSession.shared.dataTask(with: req) { [weak self] _, resp, err in
            let ok = (resp as? HTTPURLResponse)?.statusCode == 200 && err == nil
            self?.garmin.sendBolusResponse(BolusResponseMessage(status: ok ? "delivered" : "error"))
        }.resume()
    }
}
