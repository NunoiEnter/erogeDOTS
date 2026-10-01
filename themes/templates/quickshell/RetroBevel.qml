import QtQuick

Item {
    property bool sunken: false
    readonly property color light: sunken ? "#404040" : "#ffffff"
    readonly property color dark: sunken ? "#ffffff" : "#404040"
    Rectangle { anchors.top: parent.top; width: parent.width; height: 2; color: parent.light }
    Rectangle { anchors.left: parent.left; width: 2; height: parent.height; color: parent.light }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: parent.dark }
    Rectangle { anchors.right: parent.right; width: 2; height: parent.height; color: parent.dark }
}
