import QtQuick
import QtQuick.Layouts

// Shared tool row, retaining VnButton's focus, activation and retro behavior.
VnButton {
    id: action
    property string symbol: "settings"
    property string description: ""
    property string status: ""
    property bool external: true
    objectName: text
    quiet: true
    implicitWidth: 300
    implicitHeight: Math.max(64, contentItem.implicitHeight + 24)
    hint: description
    Accessible.description: description + (status ? ". " + status : "")
    contentItem: RowLayout {
        spacing: 14
        ActionIcon {
            Layout.preferredWidth: 26; Layout.preferredHeight: 26
            symbol: action.symbol
            color: !action.enabled ? Theme.muted : action.selected ? Theme.paper : Theme.accent
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 3
            VnText {
                Layout.fillWidth: true; text: action.text
                font.family: Theme.retro ? Theme.bodyFont : Theme.titleFont
                font.pixelSize: 16; font.bold: true
                color: action.selected ? Theme.paper : action.enabled ? Theme.ink : Theme.muted
            }
            VnText {
                Layout.fillWidth: true; visible: action.description !== ""
                text: action.description; font.pixelSize: 11
                color: action.selected ? Theme.paper : Theme.muted
                wrapMode: Text.WordWrap; elide: Text.ElideNone
            }
            VnText {
                Layout.fillWidth: true; visible: action.status !== "" && action.width < 360
                text: action.status; font.pixelSize: 10
                color: action.selected ? Theme.paper : Theme.muted
            }
        }
        VnText {
            visible: action.status !== "" && action.width >= 360; text: action.status
            font.pixelSize: 10
            color: action.selected ? Theme.paper : Theme.muted
        }
        ActionIcon {
            visible: action.external
            Layout.preferredWidth: 14; Layout.preferredHeight: 14
            symbol: "launch"; color: action.selected ? Theme.paper : Theme.muted
        }
    }
}
