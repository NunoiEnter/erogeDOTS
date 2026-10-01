import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var state
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.retro ? 52 : 40
    exclusiveZone: Theme.retro ? 52 : 40
    color: "transparent"
    WlrLayershell.namespace: "eroge-vn-bar"
    WlrLayershell.layer: WlrLayer.Top
    mask: Region { item: Theme.retro ? ribbon : vnRibbon }

    VnRibbon { id: vnRibbon; visible: !Theme.retro; anchors.fill: parent; state: bar.state; barWindow: bar }
    VnFrame {
        id: ribbon
        visible: Theme.retro
        anchors.fill: parent
        anchors.leftMargin: Theme.retro ? 0 : 12
        anchors.rightMargin: Theme.retro ? 0 : 12
        anchors.topMargin: Theme.retro ? 0 : 7
        anchors.bottomMargin: Theme.retro ? 0 : 3
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.retro ? 6 : 14
            anchors.rightMargin: Theme.retro ? 6 : 14
            spacing: 6
            VnButton {
                text: Theme.retro ? "Start" : "erogeDOTS"
                compact: true
                quiet: !Theme.retro
                hint: "Open the application launcher"
                contentItem: VnText {
                    text: Theme.retro ? "Start" : "erogeDOTS"
                    font.family: Theme.titleFont
                    font.pixelSize: Theme.retro ? 13 : 16
                    font.bold: true
                    color: Theme.retro ? Theme.ink : Theme.accent
                }
                onClicked: bar.state.launch(["fuzzel"])
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.line }
            RowLayout {
                spacing: 3
                Repeater {
                    model: bar.state.niri.workspaces.filter(w => w.output === bar.screen.name)
                    VnButton {
                        required property var modelData
                        compact: true
                        implicitWidth: 30
                        text: modelData.idx.toString().padStart(2, "0")
                        selected: modelData.is_active
                        Accessible.name: "Workspace " + modelData.idx + (modelData.name ? ": " + modelData.name : "")
                        hint: Accessible.name + " · Scroll to switch"
                        onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", modelData.idx.toString()])
                        onScrolled: delta => bar.state.scrollWorkspace(bar.screen, delta)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 3
                            width: 4; height: 2
                            color: Theme.accent
                            visible: modelData.is_urgent
                        }
                    }
                }
            }
            VnText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.leftMargin: 6
                text: bar.state.niri.title
                color: Theme.muted
                visible: bar.width > 1180
            }
            Item { Layout.fillWidth: true; visible: bar.width <= 1180 }
            RowLayout {
                visible: !!bar.state.player && bar.width > 1100
                spacing: 4
                VnButton {
                    compact: true; quiet: true
                    Layout.preferredWidth: Math.min(200, bar.width * 0.14)
                    text: bar.state.player?.trackTitle || "Music room"
                    hint: (bar.state.player?.trackTitle || "Music room") + " · " + (bar.state.player?.trackArtist || "")
                    contentItem: RowLayout {
                        spacing: 6
                        MediaArtwork { Layout.preferredWidth: 24; Layout.preferredHeight: 24; source: bar.state.player?.trackArtUrl || "" }
                        VnText { Layout.fillWidth: true; text: bar.state.player?.trackTitle || "Music room"; font.pixelSize: 11 }
                    }
                    onClicked: bar.state.openSection(bar.screen, "music")
                }
                VnButton {
                    compact: true; quiet: true
                    text: bar.state.player?.isPlaying ? "Pause" : "Play"
                    enabled: bar.state.player?.canTogglePlaying ?? false
                    hint: "Play or pause the current track · Right-click for next"
                    onClicked: bar.state.player.togglePlaying()
                    onSecondaryClicked: { if (bar.state.player?.canGoNext) bar.state.player.next(); }
                }
            }
            TrayItems { barWindow: bar; visible: bar.width > 720 }
            VnButton {
                compact: true; quiet: true
                text: bar.state.wifiEnabled ? "Wi-Fi" : "Offline"
                visible: bar.width > 940
                hint: bar.state.wifiText + " · Open connections"
                onClicked: bar.state.openSection(bar.screen, "connections")
                onSecondaryClicked: if (bar.state.hasApp("nm-connection-editor")) bar.state.launch(["nm-connection-editor"])
            }
            VnButton {
                compact: true; quiet: true
                text: bar.state.muted ? "Muted" : "Vol " + Math.round(bar.state.volume * 100) + "%"
                visible: bar.width > 760
                hint: "Scroll to change volume · Right-click to mute"
                onClicked: bar.state.openSection(bar.screen, "connections")
                onScrolled: delta => bar.state.setVolume(bar.state.volume + (delta > 0 ? 0.05 : -0.05))
                onSecondaryClicked: bar.state.toggleMute()
            }
            VnButton {
                compact: true; quiet: true
                text: "Light " + Math.round(bar.state.brightness * 100) + "%"
                visible: bar.state.brightnessAvailable && bar.width > 1280
                hint: "Scroll to change brightness"
                onClicked: bar.state.openSection(bar.screen, "connections")
                onScrolled: delta => bar.state.setBrightness(bar.state.brightness + (delta > 0 ? 0.05 : -0.05))
            }
            VnButton {
                compact: true; quiet: true
                text: bar.state.batteryText
                visible: bar.state.hasBattery && bar.width > 840
                hint: "Battery " + bar.state.batteryText
                Accessible.name: hint
                onClicked: bar.state.openSection(bar.screen, "connections")
            }
            VnButton {
                compact: true; quiet: true
                text: bar.state.dnd ? "DND · " + bar.state.notificationCount : "Log · " + bar.state.notificationCount
                hint: "Notification log · Right-click to toggle Do Not Disturb"
                onClicked: bar.state.launch(["swaync-client", "-t", "-sw"])
                onSecondaryClicked: Quickshell.execDetached(["swaync-client", "--toggle-dnd"])
            }
            VnButton {
                compact: true; quiet: true
                text: (bar.width > 1440 ? bar.state.dateText + "  " : "") + bar.state.timeText
                hint: "Open calendar"
                selected: bar.state.calendarShown && bar.state.calendarScreen === bar.screen
                onClicked: bar.state.toggleCalendar(bar.screen)
            }
            VnButton {
                text: "Menu"; compact: true
                selected: bar.state.shown && bar.state.menuScreen === bar.screen
                hint: "System menu · Super+S"
                onClicked: bar.state.toggle(bar.screen)
            }
            VnButton {
                text: "Exit"; compact: true; quiet: true
                visible: bar.width > 900
                hint: "Lock, log out, sleep, reboot or shut down"
                onClicked: bar.state.session()
            }
        }
    }
}
