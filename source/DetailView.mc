// DetailView.mc — Secondary screen with pump details and recent stats

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DetailView extends WatchUi.View {

    var _store as GlucoseDataStore;

    function initialize(store as GlucoseDataStore) {
        View.initialize();
        _store = store;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 8, Graphics.FONT_SMALL, "Pump Details", Graphics.TEXT_JUSTIFY_CENTER);

        // Divider
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(10, 30, w - 10, 30);

        var rows = [
            ["BG", _store.glucoseMgdl.toString() + " mg/dL"],
            ["mmol", _store.glucoseMmol.format("%.1f")],
            ["Trend", _store.glucoseTrend],
            ["IOB", _store.iobUnits.format("%.2f") + " u"],
            ["COB", _store.cobGrams.toString() + " g"],
            ["Reservoir", _store.reservoirUnits.format("%.0f") + " u"],
            ["Pump Bat", _store.batteryPct.toString() + "%"],
        ] as Array<Array<String>>;

        var rowH = (h - 40) / rows.size();
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Array<String>;
            var y = 38 + i * rowH;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, y, Graphics.FONT_TINY, row[0] as String, Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w - 20, y, Graphics.FONT_TINY, row[1] as String, Graphics.TEXT_JUSTIFY_RIGHT);
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h - 18, Graphics.FONT_XTINY, "BACK to return", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
