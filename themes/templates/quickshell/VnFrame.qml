import QtQuick

Rectangle {
    color: Theme.paper
    border.color: Theme.accent
    border.width: 1
    radius: 5
    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        color: "transparent"
        border.color: Theme.line
        radius: 2
    }
    Ornament { x: -6; y: -6 }
    Ornament { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: -6 }
}
