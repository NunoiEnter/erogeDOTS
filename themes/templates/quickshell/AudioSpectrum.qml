import QtQuick

Item {
    id: spectrum
    required property var state
    readonly property var levels: state.audioLevels
    implicitHeight: 90
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
    Row {
        anchors.fill: parent; spacing: 3
        Repeater {
            model: 48
            Rectangle {
                required property int index
                width: Math.max(1, (spectrum.width - 47 * 3) / 48)
                height: Math.max(2, spectrum.levels[index] * (spectrum.height - 8))
                y: spectrum.height - height
                color: Theme.accent
                opacity: spectrum.levels[index] > 0.01 ? 0.85 : 0.28
                radius: Theme.retro ? 0 : 1
                Behavior on height { NumberAnimation { duration: 65; easing.type: Easing.OutCubic } }
            }
        }
    }
    VnText { anchors.centerIn: parent; visible: spectrum.state.audioError !== ""; text: "Audio visualizer unavailable"; color: Theme.muted }
}
