// BolusMenuView.mc — Bolus dose picker (UP/DOWN to adjust, SELECT to confirm)

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BolusMenuView extends WatchUi.View {

    var _store as GlucoseDataStore;
    var _units as Float;
    var _step as Float = 0.05f;
    var _confirmed as Boolean = false;

    function initialize(store as GlucoseDataStore) {
        View.initialize();
        _store = store;
        _units = 1.0f; // start at 1u
    }

    function getUnits() as Float { return _units; }

    function increment() as Void {
        _units += _step;
        if (_units > 25.0f) { _units = 25.0f; }
    }

    function decrement() as Void {
        _units -= _step;
        if (_units < 0.05f) { _units = 0.05f; }
    }

    function confirmBolus() as Void {
        _confirmed = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_confirmed) {
            _drawConfirmedScreen(dc, cx, h);
            return;
        }

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 10, Graphics.FONT_SMALL, "Bolus Dose", Graphics.TEXT_JUSTIFY_CENTER);

        // Big unit display
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 - 40, Graphics.FONT_NUMBER_HOT, _units.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 + 20, Graphics.FONT_MEDIUM, "units", Graphics.TEXT_JUSTIFY_CENTER);

        // Current glucose context
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var glcText = "BG: " + _store.glucoseMgdl.toString() + " mg/dL  IOB: " + _store.iobUnits.format("%.2f") + "u";
        dc.drawText(cx, h - 50, Graphics.FONT_XTINY, glcText, Graphics.TEXT_JUSTIFY_CENTER);

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h - 32, Graphics.FONT_XTINY, "▲ +0.05  ▼ -0.05  ● confirm", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function _drawConfirmedScreen(dc as Graphics.Dc, cx as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 - 30, Graphics.FONT_MEDIUM, "Sending bolus", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h / 2 + 5, Graphics.FONT_LARGE, _units.format("%.2f") + " u", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 + 40, Graphics.FONT_TINY, "Awaiting pump...", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class BolusMenuDelegate extends WatchUi.BehaviorDelegate {

    var _store as GlucoseDataStore;
    var _view as BolusMenuView?;

    function initialize(store as GlucoseDataStore) {
        BehaviorDelegate.initialize();
        _store = store;
    }

    // The view is injected once pushed
    function setView(v as BolusMenuView) as Void { _view = v; }

    function onPreviousPage() as Boolean {
        if (_view != null) { (_view as BolusMenuView).increment(); }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        if (_view != null) { (_view as BolusMenuView).decrement(); }
        WatchUi.requestUpdate();
        return true;
    }

    // SELECT — first press shows confirm screen, second press sends
    var _awaitingConfirm as Boolean = false;
    function onSelect() as Boolean {
        if (_view == null) { return true; }
        var v = _view as BolusMenuView;
        if (!_awaitingConfirm) {
            _awaitingConfirm = true;
            v.confirmBolus();
        } else {
            // Send bolus
            _store.requestBolus(v.getUnits());
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
