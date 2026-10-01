import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var state
    anchors { top: true; left: true; right: true }
    implicitHeight: 52
    exclusiveZone: 52
    color: "transparent"
    WlrLayershell.namespace: "eroge-vn-bar"
    WlrLayershell.layer: WlrLayer.Top
    mask: Region { item: ribbon }

    VnFrame {
        id: ribbon
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 7
        anchors.bottomMargin: 3
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8
            VnButton {
                text: "erogeDOTS"
                compact: true
                quiet: true
                contentItem: VnText {
                    text: "erogeDOTS"
                    font.family: Theme.titleFont
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.accent
                }
                onClicked: bar.state.launch(["fuzzel"])
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.line }
            RowLayout {
                spacing: 4
                Repeater {
                    model: bar.state.niri.workspaces.filter(w => w.output === bar.screen.name)
                    VnButton {
                        required property var modelData
                        compact: true
                        implicitWidth: 30
                        text: modelData.idx.toString().padStart(2, "0")
                        selected: modelData.is_active
                        Accessible.name: "Workspace " + modelData.idx + (modelData.name ? ": " + modelData.name : "")
                        onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", "--", modelData.idx.toString()])
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            width: 4
                            height: 2
                            color: Theme.accent
                            visible: modelData.is_urgent
                        }
                    }
                }
            }
            VnText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.leftMargin: 8
                text: bar.state.niri.title
                color: Theme.muted
                visible: bar.width > 860
            }
            Item { Layout.fillWidth: true; visible: bar.width <= 860 }
            VnText {
                text: bar.state.dateText
                font.family: Theme.titleFont
                color: Theme.muted
                visible: bar.width > 1050
            }
            VnText {
                text: bar.state.timeText
                font.pixelSize: 15
                font.bold: true
                Layout.rightMargin: 8
            }
            VnButton {
                compact: true
                quiet: true
                text: bar.state.muted ? "Sound off" : "Sound " + Math.round(bar.state.volume * 100) + "%"
                visible: bar.width > 760
                onClicked: bar.state.toggle(bar.screen)
            }
            VnButton {
                compact: true
                quiet: true
                text: bar.state.batteryText
                visible: bar.state.hasBattery
                Accessible.name: "Battery " + bar.state.batteryText
                onClicked: bar.state.toggle(bar.screen)
            }
            VnButton {
                text: "Log"
                compact: true
                quiet: true
                Accessible.name: "Notification log"
                onClicked: bar.state.launch(["swaync-client", "-t", "-sw"])
            }
            VnButton {
                text: "Menu"
                compact: true
                selected: bar.state.shown
                onClicked: bar.state.toggle(bar.screen)
            }
        }
    }
}
