// THESIS: Amplitude bars for whatever the machine can actually measure.
// OWN-WORLD: Live bars come from cava. When cava is unavailable the same
// bars fall back to a slow idle drift and say so, so a decorative
// animation is never passed off as audio analysis.
import QtQuick

Item {
    id: spectrum
    required property var state
    readonly property var levels: state.audioLevels
    readonly property bool live: state.audioError === ""
    readonly property bool playing: state.player?.isPlaying ?? false
    readonly property real barCount: 48
    property real phase: 0
    implicitHeight: 90
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
    Row {
        anchors.fill: parent; spacing: 3
        Repeater {
            model: spectrum.barCount
            Rectangle {
                required property int index
                width: Math.max(1, (spectrum.width - (spectrum.barCount - 1) * 3) / spectrum.barCount)
                height: Math.max(2, (spectrum.live ? spectrum.levels[index] : spectrum.idleLevel(index)) * (spectrum.height - 8))
                y: spectrum.height - height
                color: Theme.accent
                opacity: (spectrum.live ? spectrum.levels[index] : spectrum.idleLevel(index)) > 0.01 ? 0.85 : 0.28
                radius: Theme.retro ? 0 : 1
                Behavior on height { NumberAnimation { duration: 65; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 90 } }
            }
        }
    }
    VnText {
        anchors.centerIn: parent
        visible: !spectrum.live
        text: "Idle animation · no audio data"
        color: Theme.muted
        font.pixelSize: 11
    }
    NumberAnimation {
        target: spectrum
        property: "phase"
        from: 0; to: Math.PI * 2
        duration: 2600
        loops: Animation.Infinite
        running: spectrum.visible && !spectrum.live && spectrum.playing
    }

    function idleLevel(index) {
        const amplitude = spectrum.playing ? 0.62 : 0.14;
        const wave = Math.abs(Math.sin(spectrum.phase + index * 0.55));
        const character = 0.55 + 0.45 * Math.abs(Math.sin(index * 1.7 + 0.6));
        return amplitude * (0.3 + 0.7 * wave) * character;
    }
}