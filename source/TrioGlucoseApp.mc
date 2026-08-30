// TrioGlucoseApp.mc — Main application entry point
// Connects to Trio via iOS companion app using the Connect IQ Companion SDK

import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class TrioGlucoseApp extends Application.AppBase {

    var _view as GlucoseView;
    var _delegate as GlucoseDelegate;
    var _dataStore as GlucoseDataStore;

    function initialize() {
        AppBase.initialize();
        _dataStore = new GlucoseDataStore();
    }

    function onStart(state as Dictionary?) as Void {
        // Register for messages from the iOS companion app
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    function onStop(state as Dictionary?) as Void {
        // Request a final glucose update before closing
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        _view = new GlucoseView(_dataStore);
        _delegate = new GlucoseDelegate(_dataStore, _view);
        return [_view, _delegate];
    }

    // Handle messages arriving from the Trio iOS companion app
    function onPhoneMessage(msg as Communications.Message) as Void {
        var data = msg.data;
        if (data instanceof Dictionary) {
            var msgType = data.get("type") as String?;
            if (msgType != null) {
                if (msgType.equals("glucose_update")) {
                    _dataStore.updateGlucose(data);
                    WatchUi.requestUpdate();
                } else if (msgType.equals("bolus_response")) {
                    _dataStore.handleBolusResponse(data);
                    WatchUi.requestUpdate();
                } else if (msgType.equals("pump_status")) {
                    _dataStore.updatePumpStatus(data);
                    WatchUi.requestUpdate();
                }
            }
        }
    }

}

function getApp() as TrioGlucoseApp {
    return Application.getApp() as TrioGlucoseApp;
}
