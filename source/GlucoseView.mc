// GlucoseView.mc — Main watch face displaying CGM data and pump status

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;

class GlucoseView extends WatchUi.View {

    var _store as GlucoseDataStore;

    function initialize(store as GlucoseDataStore) {
        View.initialize();
        _store = store;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // No XML layout — we draw everything manually for full control
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_store.glucoseMgdl == 0) {
            _drawWaiting(dc, cx, cy);
            return;
        }

        // === GLUCOSE VALUE (large, centred, colour-coded) ===
        var glucoseColor = _store.glucoseColor();
        dc.setColor(glucoseColor, Graphics.COLOR_TRANSPARENT);

        var mgText = _store.glucoseMgdl.toString();
        dc.drawText(cx, cy - 40, Graphics.FONT_NUMBER_THAI_HOT, mgText, Graphics.TEXT_JUSTIFY_CENTER);

        // mmol/L below
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var mmolText = _store.glucoseMmol.format("%.1f") + " mmol/L";
        dc.drawText(cx, cy + 28, Graphics.FONT_SMALL, mmolText, Graphics.TEXT_JUSTIFY_CENTER);

        // === TREND ARROW ===
        dc.setColor(glucoseColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 52, cy - 45, Graphics.FONT_LARGE, _store.glucoseTrend, Graphics.TEXT_JUSTIFY_LEFT);

        // Stale indicator
        if (_store.isStale()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 70, Graphics.FONT_TINY, "STALE", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // === IOB / COB ROW ===
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var iobText = "IOB " + _store.iobUnits.format("%.2f") + "u";
        var cobText = "COB " + _store.cobGrams.toString() + "g";
        dc.drawText(cx - 10, cy + 52, Graphics.FONT_XTINY, iobText, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(cx + 10, cy + 52, Graphics.FONT_XTINY, cobText, Graphics.TEXT_JUSTIFY_LEFT);

        // === PUMP STATUS BAR (bottom) ===
        _drawPumpBar(dc, w, h);

        // === BOLUS STATUS (if pending) ===
        if (_store.bolusPending) {
            _drawBolusBanner(dc, cx, cy, w);
        }
    }

    function _drawWaiting(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM, "Waiting for", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 10, Graphics.FONT_MEDIUM, "Trio data...", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 45, Graphics.FONT_TINY, "Open Trio on iPhone", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function _drawPumpBar(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var barY = h - 28;
        if (!_store.pumpConnected) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, barY, Graphics.FONT_TINY, "PUMP DISCONNECTED", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Reservoir
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var resColor = _store.reservoirUnits < 20.0f ? Graphics.COLOR_ORANGE : Graphics.COLOR_LT_GRAY;
        dc.setColor(resColor, Graphics.COLOR_TRANSPARENT);
        var resText = _store.reservoirUnits.format("%.0f") + "u";
        dc.drawText(10, barY, Graphics.FONT_TINY, resText, Graphics.TEXT_JUSTIFY_LEFT);

        // Temp basal
        if (_store.tempBasalActive) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            var tbText = "TB " + _store.tempBasalRate.format("%.2f");
            dc.drawText(w / 2, barY, Graphics.FONT_TINY, tbText, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Battery
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var batColor = _store.batteryPct < 20 ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY;
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        var batText = _store.batteryPct.toString() + "%";
        dc.drawText(w - 10, barY, Graphics.FONT_TINY, batText, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function _drawBolusBanner(dc as Graphics.Dc, cx as Number, cy as Number, w as Number) as Void {
        // Semi-transparent banner at top
        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, 32);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var txt = "Bolus " + _store.bolusRequested.format("%.2f") + "u — " + _store.bolusStatus;
        dc.drawText(cx, 8, Graphics.FONT_TINY, txt, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
