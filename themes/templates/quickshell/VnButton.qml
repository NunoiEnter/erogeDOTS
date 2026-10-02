import QtQuick
import QtQuick.Controls
import "Keyboard.js" as Keyboard

Button {
    id: control
    property bool selected: false
    property bool quiet: false
    property bool compact: false
    property string hint: ""
    signal scrolled(real delta)
    signal secondaryClicked()
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Keys.onTabPressed: event => { Keyboard.move(control, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(control, false); event.accepted = true; }
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onUpPressed: event => { Keyboard.move(control, false); event.accepted = true; }
    Keys.onDownPressed: event => { Keyboard.move(control, true); event.accepted = true; }
    Keys.onLeftPressed: event => { Keyboard.move(control, false); event.accepted = true; }
    Keys.onRightPressed: event => { Keyboard.move(control, true); event.accepted = true; }
    implicitHeight: compact ? 30 : 38
    implicitWidth: Math.max(compact ? 32 : 72, contentItem.implicitWidth + 24)
    leftPadding: compact ? 6 : 12
    rightPadding: compact ? 6 : 12
    Accessible.name: text
    ToolTip {
        visible: control.hovered && control.hint !== ""
        delay: 550
        text: control.hint
        contentItem: VnText { text: control.hint }
        background: Rectangle { color: Theme.paper; border.color: Theme.line; radius: Theme.retro ? 0 : 3 }
    }
    WheelHandler { onWheel: event => { control.scrolled(event.angleDelta.y); event.accepted = true; } }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: control.secondaryClicked() }
    contentItem: VnText {
        text: control.text
        color: control.enabled ? (control.selected ? Theme.paper : Theme.ink) : Theme.muted
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: control.compact ? 11 : 12
        font.bold: control.selected
        opacity: control.enabled ? 1 : 0.65
    }
    background: Rectangle {
        radius: Theme.retro ? 0 : 3
        color: control.selected ? Theme.accent : (control.down || control.hovered ? Theme.tint : Theme.paper)
        border.color: control.visualFocus ? Theme.accent : (control.quiet && !control.hovered ? "transparent" : Theme.line)
        border.width: control.visualFocus ? 2 : 1
        RetroBevel { anchors.fill: parent; visible: Theme.retro; sunken: control.down || control.selected }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 1
            color: "transparent"
            border.color: control.selected ? Theme.tint : Theme.paper
            visible: !Theme.retro && (!control.quiet || control.hovered)
        }
    }
}
