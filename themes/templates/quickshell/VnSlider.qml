import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string label: ""
    property real value: 0
    signal moved(real value)
    spacing: 6
    RowLayout {
        Layout.fillWidth: true
        VnText { text: root.label; Layout.fillWidth: true }
        VnText { text: root.enabled ? Math.round(root.value * 100) + "%" : "Unavailable"; color: Theme.muted }
    }
    Slider {
        id: slider
        Layout.fillWidth: true
        from: 0
        to: 1
        stepSize: 0.01
        value: root.value
        implicitHeight: 24
        onMoved: root.moved(value)
        Accessible.name: root.label
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 8
            radius: 2
            color: Theme.tint
            border.color: Theme.line
            Rectangle {
                width: parent.width * slider.visualPosition
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 13
            height: 20
            radius: 2
            color: Theme.paper
            border.color: Theme.accent
            border.width: slider.visualFocus ? 2 : 1
            Rectangle { anchors.centerIn: parent; width: 1; height: 9; color: Theme.line }
        }
        opacity: enabled ? 1 : 0.5
    }
}
