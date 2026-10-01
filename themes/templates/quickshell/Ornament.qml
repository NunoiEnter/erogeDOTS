import QtQuick

// Four small petals and a stem, drawn as geometry rather than font glyphs.
Item {
    id: root
    implicitWidth: 26
    implicitHeight: 26
    Repeater {
        model: 4
        Rectangle {
            required property int index
            x: root.width / 2 - 3
            y: root.height / 2 - 10
            width: 6
            height: 9
            radius: 3
            color: Theme.tint
            border.color: Theme.accent
            border.width: 1
            transform: Rotation { origin.x: 3; origin.y: 10; angle: index * 90 }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 4
        height: 4
        radius: 2
        color: Theme.accent
    }
}
