// erogeDOTS Senren Banka bar + quick-settings — Yuzusoft visual-novel style.
// Template: theme-switch substitutes color vars into ~/.config/quickshell/shell.qml.
// Bar: top kamidana strip, parchment translucent, gold + vermillion borders,
//   torii launcher, hanko workspace seals, scenario-title, VN clock, ema status.
// Popover: dialogue-box card, name-plate header, chapter sections.
// Trigger: Mod+S or bar status click -> `quickshell ipc -n call quick-settings toggle`.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool shown: false

    // ── wifi state (nmcli poll) ──
    property bool wifiEnabled: false
    property string wifiSsid: ""

    // ── brightness state (brightnessctl poll) ──
    property real brightness: 0.5
    property real pendingBri: -1

    // ── niri state (polled, 1s) ──
    property var wsList: []
    property string focusedTitle: ""

    // ── live services ──
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property var bat: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery
    readonly property MprisPlayer player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    function refresh(): void {
        netProc.running = true;
        briProc.running = true;
    }

    function refreshBar(): void {
        wsProc.running = true;
        titleProc.running = true;
    }

    function setVolume(v: real): void {
        const s = root.sink;
        if (s && s.audio) {
            s.audio.muted = false;
            s.audio.volume = Math.max(0, Math.min(1, v));
        }
    }

    function setBrightness(v: real): void {
        root.brightness = Math.max(0.05, Math.min(1, v));
        root.pendingBri = root.brightness;
        briCommit.restart();
    }

    function wifiLabel(): string {
        if (!root.wifiEnabled)
            return "Off";
        return root.wifiSsid !== "" ? root.wifiSsid : "On";
    }

    function btLabel(): string {
        const a = Bluetooth.defaultAdapter;
        if (!a || !a.enabled)
            return "Off";
        const devs = Bluetooth.devices.values;
        const con = devs.filter(d => d.connected);
        if (con.length > 0)
            return con[0].name;
        return devs.length + " paired";
    }

    function batText(): string {
        const b = root.bat;
        if (!b || !b.isLaptopBattery)
            return "AC";
        const pct = Math.round(b.percentage * 100) + "%";
        return (!root.onBattery ? " " : "") + pct;
    }

    function batIcon(): string {
        const b = root.bat;
        if (!b || !b.isLaptopBattery)
            return "";
        const p = b.percentage;
        if (p >= 0.9)
            return "";
        if (p >= 0.6)
            return "";
        if (p >= 0.3)
            return "";
        return "";
    }

    function clockText(): string {
        return Qt.formatDateTime(sysClock.date, "HH:mm");
    }

    function dateText(): string {
        return Qt.formatDateTime(sysClock.date, "M/d ddd");
    }

    function mediaText(): string {
        if (!root.player)
            return "";
        const t = root.player.trackTitle || "Unknown";
        return (t.length > 22 ? t.slice(0, 22) + "…" : t);
    }

    function focusWs(idx: int): void {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", idx.toString()]);
    }

    onShownChanged: if (root.shown)
        root.refresh()

    Component.onCompleted: root.refreshBar()

    IpcHandler {
        target: "quick-settings"

        function toggle(): void {
            root.shown = !root.shown;
        }
        function open(): void {
            root.shown = true;
        }
        function close(): void {
            root.shown = false;
        }
    }

    PwObjectTracker {
        objects: [root.sink].filter(o => o)
    }

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    Process {
        id: netProc

        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2-"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.wifiEnabled = (lines[0] || "") === "enabled";
                root.wifiSsid = lines.length > 1 ? lines.slice(1).join(" ") : "";
            }
        }
    }

    Process {
        id: briProc

        command: ["sh", "-c", "echo $(brightnessctl g) $(brightnessctl m)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/);
                const cur = parseInt(p[0], 10);
                const max = parseInt(p[1], 10);
                if (max > 0)
                    root.brightness = cur / max;
            }
        }
    }

    // ── niri workspaces poll (sorted by idx, like old eww-status) ──
    Process {
        id: wsProc

        command: ["sh", "-c", "niri msg -j workspaces 2>/dev/null | jq -c 'sort_by(.idx)'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text.trim() || "[]");
                    root.wsList = arr;
                } catch (e) {
                    root.wsList = [];
                }
            }
        }
    }

    Process {
        id: titleProc

        command: ["sh", "-c", "niri msg -j focused-window 2>/dev/null | jq -r '.title // empty' | cut -c1-40"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.focusedTitle = text.trim();
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.refreshBar()
    }

    Timer {
        running: root.shown
        repeat: true
        interval: 4000
        onTriggered: root.refresh()
    }

    Timer {
        id: repoll

        interval: 800
        onTriggered: root.refresh()
    }

    Timer {
        id: briCommit

        interval: 150
        onTriggered: {
            if (root.pendingBri >= 0) {
                Quickshell.execDetached(["brightnessctl", "s", Math.round(root.pendingBri * 100) + "%"]);
                root.pendingBri = -1;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // SENREN BANKA BAR — top kamidana strip
    // ═══════════════════════════════════════════════════════════
    PanelWindow {
        id: barWin

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 38
        exclusiveZone: 38
        color: "transparent"
        WlrLayershell.namespace: "eroge-senren-bar"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Normal
        mask: Region {
            item: barBody
        }

        Rectangle {
            id: barBody

            anchors.fill: parent
            color: "{{BG}}"
            opacity: 0.93
            border.color: "{{BAR_BORDER}}"
            border.width: 1

            // vermillion inner line under gold border (kumiki woodwork)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                color: "{{PRIMARY}}"
                opacity: 0.85
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                // ── left: torii + hanko seals + scenario title ──
                RowLayout {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: "⛩️"
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["fuzzel"])
                        }
                    }
                    Repeater {
                        model: root.wsList
                        Rectangle {
                            required property var modelData
                            required property int index
                            property bool isActive: (modelData.is_focused ?? modelData.is_active ?? false)
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 5
                            color: isActive ? "{{PRIMARY}}" : "transparent"
                            border.color: isActive ? "{{PRIMARY}}" : "{{FG_DIM}}"
                            border.width: 1
                            opacity: isActive ? 1 : 0.7
                            Text {
                                anchors.centerIn: parent
                                text: modelData.idx !== undefined ? modelData.idx.toString() : (index + 1).toString()
                                color: isActive ? "{{BG}}" : "{{FG_DIM}}"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: isActive
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.focusWs(parent.modelData.idx ?? (parent.index + 1))
                            }
                        }
                    }
                    Text {
                        text: root.focusedTitle
                        color: "{{FG_DIM}}"
                        font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.italic: true
                        elide: Text.ElideRight
                        Layout.maximumWidth: 220
                        visible: root.focusedTitle !== ""
                    }
                }

                // ── center: VN clock + now-playing line ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    spacing: 10

                    Text {
                        text: root.clockText()
                        color: "{{FG}}"
                        font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: root.dateText()
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Text {
                        text: root.player ? ("❀ " + root.mediaText()) : ""
                        color: "{{PRIMARY_LIGHT}}"
                        font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.italic: true
                        elide: Text.ElideRight
                        Layout.maximumWidth: 200
                        visible: root.player !== null
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player?.togglePlaying()
                        }
                    }
                }

                // ── right: ema status plaques ──
                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 8

                    Text {
                        text: "☀ " + Math.round(root.brightness * 100) + "%"
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shown = !root.shown
                        }
                    }
                    Text {
                        text: (root.muted ? " " : " ") + Math.round(root.volume * 100) + "%"
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shown = !root.shown
                        }
                    }
                    Text {
                        text: " " + root.wifiLabel()
                        color: root.wifiEnabled ? "{{FG_DIM}}" : "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shown = !root.shown
                        }
                    }
                    Text {
                        text: root.batIcon() + " " + root.batText()
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shown = !root.shown
                        }
                    }
                    Text {
                        text: ""
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shown = !root.shown
                        }
                    }
                    Text {
                        text: ""
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
                        }
                    }
                    Text {
                        text: ""
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["wlogout"])
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // DIALOGUE-BOX POPOVER — quick-settings control center
    // ═══════════════════════════════════════════════════════════
    PanelWindow {
        visible: root.shown
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        WlrLayershell.namespace: "eroge-quick-settings"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region {
            item: card
        }

        MouseArea {
            anchors.fill: parent
            focus: root.shown
            Keys.onEscapePressed: root.shown = false
            onClicked: root.shown = false
        }

        Rectangle {
            id: card

            anchors.top: parent.top
            anchors.topMargin: 120
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            implicitHeight: body.implicitHeight + 32
            radius: 12
            color: "{{BG}}"
            border.color: "{{BAR_BORDER}}"
            border.width: 2
            opacity: root.shown ? 1 : 0

            // vermillion name-plate stripe on top edge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                radius: 2
                color: "{{PRIMARY}}"
                opacity: 0.9
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.shown = false
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            ColumnLayout {
                id: body

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "❀ 御設定 Control Center"
                            color: "{{FG}}"
                            font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "{{CHAR_NAME}}"
                            color: "{{PRIMARY}}"
                            font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        text: root.batIcon()
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    Text {
                        text: root.batText()
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "{{BAR_BORDER}}"
                    opacity: 0.55
                }

                Text {
                    text: "CONNECTIVITY ・ 縁"
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Pill {
                        icon: ""
                        title: "Wi-Fi"
                        sub: root.wifiLabel()
                        active: root.wifiEnabled
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]);
                            repoll.restart();
                        }
                    }
                    Pill {
                        icon: ""
                        title: "Bluetooth"
                        sub: root.btLabel()
                        active: Bluetooth.defaultAdapter?.enabled ?? false
                        onClicked: {
                            const a = Bluetooth.defaultAdapter;
                            if (a)
                                a.enabled = !a.enabled;
                        }
                    }
                }

                Text {
                    text: "AUDIO & DISPLAY ・ 音"
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.muted ? "" : ""
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const s = root.sink;
                                if (s && s.audio)
                                    s.audio.muted = !s.audio.muted;
                            }
                        }
                    }
                    Bar {
                        value: root.muted ? 0 : root.volume
                        onSeek: v => root.setVolume(v)
                    }
                    Text {
                        text: Math.round((root.muted ? 0 : root.volume) * 100) + "%"
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        Layout.minimumWidth: 34
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: ""
                        color: "{{PRIMARY}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }
                    Bar {
                        value: root.brightness
                        onSeek: v => root.setBrightness(v)
                    }
                    Text {
                        text: Math.round(root.brightness * 100) + "%"
                        color: "{{FG_DIM}}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        Layout.minimumWidth: 34
                    }
                }

                Text {
                    text: "MEDIA ・ 唄"
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.player !== null

                    RoundBtn {
                        icon: ""
                        canPress: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }
                    RoundBtn {
                        icon: (root.player?.isPlaying ?? false) ? "" : ""
                        canPress: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                    RoundBtn {
                        icon: ""
                        canPress: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackTitle || "Unknown title"
                            color: "{{FG}}"
                            font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackArtist || ""
                            color: "{{FG_DIM}}"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.player === null
                    text: "Nothing playing — 静寂"
                    color: "{{FG_DIM}}"
                    font.family: "Noto Serif JP, JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.italic: true
                }

                Text {
                    text: "SESSION ・ 旅立"
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ActionBtn {
                        icon: ""
                        label: "Lock"
                        onClicked: {
                            Quickshell.execDetached(["qylock-lock"]);
                            root.shown = false;
                        }
                    }
                    ActionBtn {
                        icon: ""
                        label: "Leave"
                        onClicked: {
                            Quickshell.execDetached(["wlogout"]);
                            root.shown = false;
                        }
                    }
                    ActionBtn {
                        icon: ""
                        label: "Night"
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "pkill wlsunset || wlsunset -l 13.736717 -L 100.523186 &"]);
                            root.shown = false;
                        }
                    }
                    ActionBtn {
                        icon: ""
                        label: "Alerts"
                        onClicked: {
                            Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
                            root.shown = false;
                        }
                    }
                }

                Text {
                    text: "OPEN SETTINGS"
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    LinkBtn {
                        label: "Network"
                        onClicked: {
                            Quickshell.execDetached(["nm-connection-editor"]);
                            root.shown = false;
                        }
                    }
                    LinkBtn {
                        label: "Sound"
                        onClicked: {
                            Quickshell.execDetached(["pavucontrol"]);
                            root.shown = false;
                        }
                    }
                    LinkBtn {
                        label: "Bluetooth"
                        onClicked: {
                            Quickshell.execDetached(["blueman-manager"]);
                            root.shown = false;
                        }
                    }
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pill

        property string icon: ""
        property string title: ""
        property string sub: ""
        property bool active: false
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 52
        radius: 10
        color: "{{BG_LIGHT}}"
        border.color: pill.active ? "{{PRIMARY}}" : "{{BAR_BORDER}}"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 8

            Text {
                text: pill.icon
                color: "{{PRIMARY}}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: pill.title
                    color: "{{FG}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: pill.sub
                    color: "{{FG_DIM}}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                radius: 3
                color: pill.active ? "{{PRIMARY}}" : "transparent"
                border.color: "{{BAR_BORDER}}"
                border.width: pill.active ? 0 : 1
            }
        }
    }

    component Bar: Item {
        id: bar

        property real value: 0
        signal seek(real v)

        Layout.fillWidth: true
        implicitHeight: 22

        function toVal(x: real): real {
            return Math.max(0, Math.min(1, x / width));
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: "{{BG_LIGHT}}"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, bar.value))
                height: parent.height
                radius: 3
                color: "{{PRIMARY}}"
            }
            Rectangle {
                x: parent.width * Math.max(0, Math.min(1, bar.value)) - 6
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: "{{FG}}"
                border.color: "{{PRIMARY}}"
                border.width: 1
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => bar.seek(bar.toVal(mouse.x))
            onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton)
                    bar.seek(bar.toVal(mouse.x));
            }
        }
    }

    component RoundBtn: Rectangle {
        id: rbtn

        property string icon: ""
        property bool canPress: true
        signal clicked

        implicitWidth: 32
        implicitHeight: 32
        radius: 16
        color: "{{BG_LIGHT}}"
        border.color: "{{BAR_BORDER}}"
        border.width: 1
        opacity: rbtn.canPress ? 1 : 0.4

        Text {
            anchors.centerIn: parent
            text: rbtn.icon
            color: "{{FG}}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
        MouseArea {
            anchors.fill: parent
            enabled: rbtn.canPress
            cursorShape: Qt.PointingHandCursor
            onClicked: rbtn.clicked()
        }
    }

    component ActionBtn: ColumnLayout {
        id: action

        property string icon: ""
        property string label: ""
        signal clicked

        Layout.fillWidth: true
        spacing: 3

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 48
            implicitHeight: 40
            radius: 10
            color: "{{BG_LIGHT}}"
            border.color: "{{BAR_BORDER}}"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: action.icon
                color: "{{PRIMARY}}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: action.clicked()
                onEntered: parent.color = "{{PRIMARY}}"
                onExited: parent.color = "{{BG_LIGHT}}"
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: action.label
            color: "{{FG_DIM}}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
        }
    }

    component LinkBtn: Rectangle {
        id: link

        property string label: ""
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 26
        radius: 8
        color: "transparent"
        border.color: "{{BAR_BORDER}}"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: link.label
            color: "{{FG_DIM}}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: link.clicked()
            onEntered: parent.color = "{{BG_LIGHT}}"
            onExited: parent.color = "transparent"
        }
    }
}
