import QtQuick
import QtQuick.Window
import Quickshell

// Offscreen integration proof: all commands are captured by a fake state.
ShellRoot {
    id: test
    property int step: 0
    property var visits: []
    QtObject {
        id: niriState
        property var windows: ({})
        property var workspaces: []
    }
    QtObject {
        id: fake
        property var niri: niriState
        property bool shown: true
        property string titlePage: "extras"
        property string error: ""
        property bool wifiEnabled: true
        property string wifiText: "Connected"
        property bool bluetoothAvailable: false
        property bool bluetoothEnabled: false
        property bool brightnessAvailable: true
        property real brightness: 0.6
        property bool dnd: false
        property bool themeBusy: false
        property var sink: null
        property real volume: 0
        property bool muted: true
        function launch(command) { test.visits.push(command); }
        function openTitleTerminal() { test.visits.push(["title-terminal"]); }
        function session(action) { test.visits.push(["confirm", action]); }
        function hasApp(name) { return true; }
        function toggleWifi() { wifiEnabled = !wifiEnabled; }
        function toggleBluetooth() {}
        function switchStyle() { test.visits.push(["style"]); }
        function setVolume(value) {}
        function setBrightness(value) {}
    }
    Window {
        id: window
        visible: true; width: 780; height: 940
        Rectangle { anchors.fill: parent; color: Theme.paper }
        DesktopPages { id: pages; anchors.fill: parent; anchors.margins: 28; state: fake; page: fake.titlePage; keyboardEnabled: true }
    }
    function controls(item) {
        let result = [];
        for (const child of item.children || []) {
            if (child.symbol !== undefined && child.description !== undefined && child.text !== undefined && child.clicked !== undefined) result.push(child);
            result = result.concat(controls(child));
        }
        return result;
    }
    function find(name) { const item = controls(pages).find(item => item.text === name); if (!item) throw new Error("Missing action: " + name); return item; }
    function expect(value, message) { if (!value) throw new Error(message); }
    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: {
            test.step++;
            if (test.step === 1) {
                test.expect(test.controls(pages).length === 6, "All six Extra Mode tools remain");
                test.find("Clipboard history").click();
                test.find("Lock screen").click();
                test.find("Open terminal").click();
                test.expect(JSON.stringify(test.visits) === JSON.stringify([["cliphist-pick"], ["confirm", "lock"], ["title-terminal"]]), "Tools retain their real routes and lock confirmation");
                fake.titlePage = "connections";
            }
            if (test.step === 2) {
                test.expect(!test.find("Bluetooth").enabled && !test.find("Bluetooth devices").enabled, "Unavailable Bluetooth stays disabled");
                test.expect(test.find("Wi-Fi").selected, "Wi-Fi shows current status");
                test.find("Wi-Fi").click(); test.expect(!fake.wifiEnabled, "Wi-Fi still toggles");
                test.find("Network").click(); test.expect(test.visits[test.visits.length - 1][0] === "nm-connection-editor", "Private profiles use NetworkManager");
                pages.page = "connections";
                test.find("NixOS & Niri").click(); test.expect(fake.titlePage === "workshop", "Existing configuration workshop remains available");
                // Keep the backend out of the fixture by overriding the selected page.
                window.width = 390;
            }
            if (test.step === 3) {
                const action = test.find("Desktop style");
                test.expect(action.width > 0 && action.implicitHeight >= 64, "Narrow actions remain usable");
                fake.themeBusy = true; test.expect(!action.enabled, "Busy style changes are disabled");
                console.log("PASS: Extra Mode and System Config routes"); Qt.quit();
            }
        }
    }
}
