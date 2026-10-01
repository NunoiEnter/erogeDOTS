import QtQuick

Rectangle {
    color: Theme.paper
    border.color: Theme.accent
    border.width: 1
    radius: Theme.retro ? 0 : 5
    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        color: "transparent"
        border.color: Theme.line
        radius: Theme.retro ? 0 : 2
        visible: !Theme.retro
    }
    RetroBevel { anchors.fill: parent; visible: Theme.retro }
    Ornament { x: -6; y: -6; visible: !Theme.retro }
    Ornament { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: -6; visible: !Theme.retro }
}
