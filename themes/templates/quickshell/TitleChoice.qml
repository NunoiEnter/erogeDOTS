import QtQuick
import QtQuick.Controls

AbstractButton {
    id: choice
    property string japanese: ""
    property string description: ""
    property bool selected: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onUpPressed: event => { nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason); event.accepted = true; }
    Keys.onDownPressed: event => { nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason); event.accepted = true; }
    implicitHeight: 58
    implicitWidth: 300
    Accessible.name: text + ": " + description
    readonly property bool highlighted: hovered || selected || visualFocus
    contentItem: Item {
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
