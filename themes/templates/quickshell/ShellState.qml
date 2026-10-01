import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: state
    property bool shown: false
    property var menuScreen: null
    property bool wifiEnabled: false
    property string wifiSsid: ""
    property bool brightnessAvailable: false
    property real brightness: 0
    property real pendingBrightness: -1
    property string error: ""
    property var availableApps: []
    readonly property var niri: niriState
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property bool bluetoothAvailable: Bluetooth.defaultAdapter !== null
    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property string batteryText: hasBattery ? Math.round(battery.percentage * 100) + "%" : "AC"
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values[0] || null
    readonly property string wifiText: wifiEnabled ? (wifiSsid || "Not connected") : "Wi-Fi off"
    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string dateText: Qt.formatDateTime(clock.date, "ddd, d MMM")

    NiriState { id: niriState }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: [state.sink].filter(o => o) }
    onShownChanged: if (shown) { refresh(); error = ""; }
    Component.onCompleted: refresh()

    function refresh() { network.running = true; if (pendingBrightness < 0) backlight.running = true; }
    function toggle(screen) { menuScreen = screen; shown = !shown; }
    function setVolume(value) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }
    function setBrightness(value) {
        brightness = Math.max(0.05, Math.min(1, value));
        pendingBrightness = brightness;
        brightnessCommit.restart();
    }
    function launch(command) { Quickshell.execDetached(command); shown = false; }
    function toggleWifi() {
        wifiToggle.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        wifiToggle.running = true;
    }
    function toggleBluetooth() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter) adapter.enabled = !adapter.enabled;
    }
    function hasApp(name) { return availableApps.indexOf(name) !== -1; }

    Process {
        id: appProbe
        running: true
        command: ["sh", "-c", "for app in nm-connection-editor pavucontrol blueman-manager; do command -v \"$app\" >/dev/null && echo \"$app\"; done"]
        stdout: StdioCollector { onStreamFinished: state.availableApps = text.trim().split("\n") }
    }
    Process {
        id: network
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t --escape no -f ACTIVE,SSID device wifi list --rescan no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                state.wifiEnabled = lines[0] === "enabled";
                const active = lines.slice(1).find(line => line.startsWith("yes:"));
                state.wifiSsid = active ? active.slice(4) : "";
            }
        }
    }
    Process {
        id: networkMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: networkRefresh.restart() }
        onExited: networkReconnect.restart()
    }
    Timer { id: networkRefresh; interval: 250; onTriggered: network.running = true }
    Timer { id: networkReconnect; interval: 5000; onTriggered: networkMonitor.running = true }
    Process {
        id: wifiToggle
        onExited: (code, status) => {
            if (code !== 0) state.error = "Wi-Fi could not be changed. Check Network settings.";
            network.running = true;
        }
    }
    Process {
        id: backlight
        command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                const current = Number(fields[2]);
                const maximum = Number(fields[4]);
                state.brightnessAvailable = fields.length >= 5 && maximum > 0;
                if (state.brightnessAvailable && state.pendingBrightness < 0) state.brightness = current / maximum;
            }
        }
    }
    Timer { running: true; repeat: true; interval: 5000; onTriggered: { if (state.pendingBrightness < 0) backlight.running = true; } }
    Timer {
        id: brightnessCommit
        interval: 120
        onTriggered: {
            if (brightnessSet.running) { restart(); return; }
            brightnessSet.command = ["brightnessctl", "--class=backlight", "set", Math.round(state.pendingBrightness * 100) + "%"];
            state.pendingBrightness = -1;
            brightnessSet.running = true;
        }
    }
    Process {
        id: brightnessSet
        onExited: (code, status) => {
            if (code !== 0) state.error = "Brightness could not be changed. Check backlight permissions.";
            if (state.pendingBrightness < 0) backlight.running = true;
        }
    }
}
