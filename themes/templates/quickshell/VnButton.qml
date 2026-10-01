import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool selected: false
    property bool quiet: false
    property bool compact: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: compact ? 30 : 38
    implicitWidth: Math.max(compact ? 32 : 72, contentItem.implicitWidth + 24)
    leftPadding: compact ? 6 : 12
    rightPadding: compact ? 6 : 12
    Accessible.name: text
    contentItem: VnText {
        text: control.text
        color: control.enabled ? (control.selected ? Theme.paper : Theme.ink) : Theme.muted
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: control.compact ? 11 : 12
        font.bold: control.selected
        opacity: control.enabled ? 1 : 0.65
    }
    background: Rectangle {
        radius: 3
        color: control.selected ? Theme.accent : (control.down || control.hovered ? Theme.tint : Theme.paper)
        border.color: control.visualFocus ? Theme.accent : (control.quiet && !control.hovered ? "transparent" : Theme.line)
        border.width: control.visualFocus ? 2 : 1
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 1
            color: "transparent"
            border.color: control.selected ? Theme.tint : Theme.paper
            visible: !control.quiet || control.hovered
        }
    }
}
