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
    property bool sessionShown: false
    property string sessionAction: ""
    property bool themeBusy: false
    property bool themeEntering: false
    property bool themeSceneReady: false
    property string themeError: ""
    property var menuScreen: null
    property string menuSection: "connections"
    property string titlePage: ""
    property string workshopSection: "packages"
    property var audioLevels: Array(48).fill(0)
    property string audioError: ""
    property bool titleTerminalInput: false
    property var titleTerminalOrigin: null
    readonly property var titleTerminalWindow: Object.values(niri.windows).find(window => window.app_id === "org.erogedots.TitleTerminal") || null
    readonly property bool titleTerminalVisible: !!titleTerminalWindow && niri.workspaces.some(workspace => workspace.is_focused && workspace.id === titleTerminalWindow.workspace_id)
    readonly property var drawer: drawerState
    property bool calendarShown: false
    property var calendarScreen: null
    property bool dnd: false
    property int notificationCount: 0
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
    DrawerState { id: drawerState; allowed: !Theme.retro && !state.shown && !state.calendarShown && !state.sessionShown }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: [state.sink].filter(o => o) }
    onShownChanged: {
        if (shown) { refresh(); error = ""; }
        else if (titleTerminalOrigin !== null && titleTerminalVisible) returnFromTerminal();
    }
    Component.onCompleted: refresh()

    function refresh() { network.running = true; if (pendingBrightness < 0) backlight.running = true; }
    function toggle(screen) { calendarShown = false; menuScreen = screen; titlePage = ""; shown = !shown; }
    function openSection(screen, section) {
        if (section.startsWith("workshop/")) {
            const tab = section.split("/")[1];
            if (["packages", "niri", "files"].includes(tab)) workshopSection = tab;
            section = "workshop";
        }
        calendarShown = false; menuScreen = screen; menuSection = section; titlePage = section; shown = true;
    }
    function changeCharacter(id) {
        if (themeBusy || !Theme.characters.some(character => character.id === id) || id === Theme.characterId) return;
        drawer.close();
        themeBusy = true; themeError = "";
        Quickshell.execDetached(["theme-switch", id, "--show-menu"]);
    }
    function focusWorkspace(index) { drawer.close(); shown = false; Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", index.toString()]); }
    function focusWindow(id) { drawer.close(); shown = false; Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", id.toString()]); }
    function toggleCalendar(screen) { shown = false; calendarScreen = screen; calendarShown = !calendarShown; }
    function switchStyle() {
        if (themeBusy) return;
        themeBusy = true; themeError = "";
        Quickshell.execDetached(["theme-switch", "style", Theme.retro ? "vn" : "win98", "--show-menu"]);
    }
    function setAppearance(kind, value) {
        if (themeBusy || !["appearance", "system"].includes(kind) || !["light", "dark"].includes(value)) return;
        themeBusy = true; themeError = "";
        Quickshell.execDetached(["theme-switch", kind, value, "--show-menu"]);
    }
    function session(action) {
        drawer.close(); calendarShown = false;
        menuScreen = Quickshell.screens.find(screen => screen.name === niri.output) || Quickshell.screens[0];
        sessionAction = ["sleep", "lock", "restart", "shutdown"].includes(action) ? action : "";
        sessionShown = true;
    }
    function playSessionSound(kind) { Quickshell.execDetached(["vn-sound", kind]); }
    function performSession(action) {
        const commands = {sleep: ["systemctl", "suspend"], lock: ["qylock-lock"], restart: ["systemctl", "reboot"], shutdown: ["systemctl", "poweroff"]};
        if (!commands[action]) return;
        sessionShown = false;
        launch(commands[action]);
    }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function scrollWorkspace(screen, delta) {
        const workspaces = niri.workspaces.filter(w => w.output === screen.name);
        const current = workspaces.findIndex(w => w.is_active);
        const next = workspaces[current + (delta < 0 ? 1 : -1)];
        if (next) Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", next.idx.toString()]);
    }
    function receiveNotifications(line) {
        try {
            const event = JSON.parse(line);
            dnd = event.dnd === true;
            notificationCount = Number(event.count) || 0;
        } catch (_) {}
    }
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
    function launch(command) { drawer.close(); Quickshell.execDetached(command); shown = false; }
    function toggleWifi() {
        wifiToggle.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        wifiToggle.running = true;
    }
    function toggleBluetooth() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter) adapter.enabled = !adapter.enabled;
    }
    function hasApp(name) { return availableApps.indexOf(name) !== -1; }
    function receiveSpectrum(line) {
        const values = line.trim().split(";").filter(value => value !== "");
        if (values.length !== 48) return;
        const next = values.map(value => Number(value));
        if (next.some(value => !Number.isFinite(value) || value < 0 || value > 1000)) return;
        audioLevels = next.map(value => value / 1000);
    }
    Process {
        id: audioSpectrum
        running: !Theme.retro && ((state.shown && state.titlePage === "music") || (drawerState.shown && drawerState.page === "music"))
        command: ["cava", "-p", Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") + "/cava/quickshell.conf" : Quickshell.env("HOME") + "/.config/cava/quickshell.conf"]
        onStarted: state.audioError = ""
        stdout: SplitParser { onRead: data => state.receiveSpectrum(data) }
        stderr: StdioCollector { id: audioLog }
        onExited: code => { state.audioLevels = Array(48).fill(0); if (code !== 0) state.audioError = audioLog.text.trim() || "Audio capture could not start."; }
    }
    function returnFromTerminal() {
        const origin = niri.workspaces.find(workspace => workspace.id === titleTerminalOrigin);
        if (origin) Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", origin.idx.toString()]);
    }
    function openTitleTerminal(command = []) {
        if (titleTerminal.running) {
            if (command.length) { error = "Close the current title terminal before starting another task."; return; }
            if (titleTerminalWindow) Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", titleTerminalWindow.id.toString()]);
            titleTerminalInput = true;
            return;
        }
        drawer.close();
        if (!shown) {
            menuScreen = Quickshell.screens.find(screen => screen.name === niri.output) || Quickshell.screens[0];
            shown = true;
        }
        titleTerminalInput = true;
        titleTerminal.command = ["vn-terminal"].concat(command);
        titleTerminal.running = true;
    }
    Process {
        id: titleTerminal
        stdout: SplitParser {
            onRead: data => {
                try { const event = JSON.parse(data); if (event.origin !== undefined) state.titleTerminalOrigin = event.origin; if (event.error) state.error = event.error; } catch (_) {}
            }
        }
        stderr: StdioCollector { id: terminalLog }
        onExited: code => { state.titleTerminalInput = false; state.titleTerminalOrigin = null; if (code !== 0 && terminalLog.text.trim()) state.error = terminalLog.text.trim().slice(-300); }
    }

    Process {
        id: notifications
        running: true
        command: ["swaync-client", "--subscribe"]
        stdout: SplitParser { onRead: data => state.receiveNotifications(data) }
        onExited: notificationReconnect.restart()
    }
    Timer { id: notificationReconnect; interval: 5000; onTriggered: notifications.running = true }
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
