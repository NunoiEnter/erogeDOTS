import QtQuick
import QtQuick.Controls
import "Keyboard.js" as Keyboard

AbstractButton {
    id: choice
    property string japanese: ""
    property string description: ""
    property bool selected: false
    property string symbol: ""
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Keys.onTabPressed: event => { Keyboard.move(choice, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(choice, false); event.accepted = true; }
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onUpPressed: event => { Keyboard.move(choice, false); event.accepted = true; }
    Keys.onDownPressed: event => { Keyboard.move(choice, true); event.accepted = true; }
    implicitHeight: 58
    implicitWidth: 300
    Accessible.name: text + ": " + description
    readonly property bool highlighted: hovered || selected || visualFocus
    contentItem: Item {
        ActionIcon {
            visible: choice.symbol !== ""
            symbol: choice.symbol
            width: 15; height: 15
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 5
            color: choice.highlighted ? Theme.accent : Theme.muted
        }
        VnText {
            anchors.left: parent.left; anchors.top: parent.top
            anchors.leftMargin: choice.highlighted ? 12 : 0
            Behavior on anchors.leftMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            text: choice.text
            font.family: Theme.titleFont
            font.pixelSize: 25
            color: choice.highlighted ? Theme.accent : Theme.ink
            font.bold: choice.highlighted
        }
        VnText {
            anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 9
            text: choice.japanese
            font.family: Theme.titleFont; font.pixelSize: 11
            color: choice.highlighted ? Theme.ink : Theme.muted
        }
        VnText {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            anchors.leftMargin: choice.symbol !== "" ? 21 : 0
            width: parent.width - anchors.leftMargin
            text: choice.description; font.pixelSize: 10; color: choice.highlighted ? Theme.ink : Theme.muted
        }
    }
    background: Item {
        Rectangle {
            anchors.fill: parent
            color: Theme.tint
            opacity: choice.highlighted ? 0.72 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: Theme.line
        }
        Rectangle {
            x: -13; y: 17; width: 7; height: 7; rotation: 45
            color: Theme.accent; visible: choice.highlighted
        }
    }
}
