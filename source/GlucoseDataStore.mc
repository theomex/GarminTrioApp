// GlucoseDataStore.mc — Holds all CGM and pump state received from Trio

import Toybox.Lang;
import Toybox.Time;
import Toybox.Communications;

class GlucoseDataStore {

    // Current glucose
    var glucoseMgdl as Number = 0;
    var glucoseMmol as Float = 0.0f;
    var glucoseTrend as String = "---";      // "↑↑" "↑" "↗" "→" "↘" "↓" "↓↓"
    var glucoseAge as Number = 0;            // seconds since last reading
    var glucoseTimestamp as Number = 0;

    // IOB / COB
    var iobUnits as Float = 0.0f;
    var cobGrams as Number = 0;

    // Pump status
    var pumpConnected as Boolean = false;
    var reservoirUnits as Float = 0.0f;
    var batteryPct as Number = 0;
    var tempBasalActive as Boolean = false;
    var tempBasalRate as Float = 0.0f;

    // Pending bolus state
    var bolusPending as Boolean = false;
    var bolusRequested as Float = 0.0f;
    var bolusConfirmed as Boolean = false;
    var bolusStatus as String = "";

    // Alert thresholds (mg/dL)
    var highThreshold as Number = 180;
    var lowThreshold as Number = 70;
    var urgentLowThreshold as Number = 55;

    function initialize() {
    }

    function updateGlucose(data as Dictionary) as Void {
        var mg = data.get("glucose_mgdl");
        if (mg instanceof Number) { glucoseMgdl = mg; }
        var mmol = data.get("glucose_mmol");
        if (mmol instanceof Float) { glucoseMmol = mmol; }
        var trend = data.get("trend");
        if (trend instanceof String) { glucoseTrend = trend; }
        var ts = data.get("timestamp");
        if (ts instanceof Number) {
            glucoseTimestamp = ts;
            glucoseAge = Time.now().value() - ts;
        }
        var iob = data.get("iob");
        if (iob instanceof Float) { iobUnits = iob; }
        var cob = data.get("cob");
        if (cob instanceof Number) { cobGrams = cob; }
    }

    function updatePumpStatus(data as Dictionary) as Void {
        var conn = data.get("connected");
        if (conn instanceof Boolean) { pumpConnected = conn; }
        var res = data.get("reservoir");
        if (res instanceof Float) { reservoirUnits = res; }
        var bat = data.get("battery");
        if (bat instanceof Number) { batteryPct = bat; }
        var tbActive = data.get("temp_basal_active");
        if (tbActive instanceof Boolean) { tempBasalActive = tbActive; }
        var tbRate = data.get("temp_basal_rate");
        if (tbRate instanceof Float) { tempBasalRate = tbRate; }
    }

    function handleBolusResponse(data as Dictionary) as Void {
        var status = data.get("status");
        if (status instanceof String) { bolusStatus = status; }
        if (bolusStatus.equals("delivered")) {
            bolusPending = false;
            bolusConfirmed = true;
        } else if (bolusStatus.equals("rejected")) {
            bolusPending = false;
            bolusConfirmed = false;
        }
    }

    function glucoseColor() as Number {
        if (glucoseMgdl <= urgentLowThreshold) { return 0xFF0000; } // red
        if (glucoseMgdl <= lowThreshold)        { return 0xFF8C00; } // orange
        if (glucoseMgdl >= highThreshold)       { return 0xFFFF00; } // yellow
        return 0x00FF00;                                              // green
    }

    function isStale() as Boolean {
        return glucoseAge > 600; // older than 10 min
    }

    // Send a bolus request to the iOS companion app
    function requestBolus(units as Float) as Void {
        bolusPending = true;
        bolusRequested = units;
        bolusStatus = "sending";
        var msg = {
            "type" => "bolus_request",
            "units" => units
        };
        Communications.transmitMessage(msg, {}, new BolusTransmitListener());
    }

    // Request a fresh glucose reading
    function requestRefresh() as Void {
        var msg = { "type" => "request_update" };
        Communications.transmitMessage(msg, {}, null);
    }
}

class BolusTransmitListener extends Communications.ConnectionListener {
    function initialize() { ConnectionListener.initialize(); }
    function onComplete() as Void {
        var store = getApp()._dataStore;
        if (store.bolusStatus.equals("sending")) {
            store.bolusStatus = "waiting";
        }
        WatchUi.requestUpdate();
    }
    function onError() as Void {
        var store = getApp()._dataStore;
        store.bolusPending = false;
        store.bolusStatus = "error";
        WatchUi.requestUpdate();
    }
}
