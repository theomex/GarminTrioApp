// GlucoseDelegate.mc — Button/touch input handling for the main view

import Toybox.Lang;
import Toybox.WatchUi;

class GlucoseDelegate extends WatchUi.BehaviorDelegate {

    var _store as GlucoseDataStore;
    var _view as GlucoseView;

    function initialize(store as GlucoseDataStore, view as GlucoseView) {
        BehaviorDelegate.initialize();
        _store = store;
        _view = view;
    }

    // UP button — open bolus entry menu
    function onPreviousPage() as Boolean {
        WatchUi.pushView(
            new BolusMenuView(_store),
            new BolusMenuDelegate(_store),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    // DOWN button — show detail / history
    function onNextPage() as Boolean {
        WatchUi.pushView(
            new DetailView(_store),
            new WatchUi.BehaviorDelegate(),
            WatchUi.SLIDE_DOWN
        );
        return true;
    }

    // SELECT (middle button on most Fenix / Forerunner) — request refresh
    function onSelect() as Boolean {
        _store.requestRefresh();
        return true;
    }

    // BACK / LAP — exit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
