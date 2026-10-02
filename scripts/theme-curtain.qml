import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Separate from the restarted shell: black stays on every display until ready.
ShellRoot {
    id: curtain
    property real shade: 0
    property bool releasing: false
    Behavior on shade { NumberAnimation { duration: curtain.releasing ? 450 : 280; easing.type: Easing.InOutQuad } }
    Timer { interval: 16; running: true; onTriggered: curtain.shade = 1 }
    // A crashed caller must never leave the desktop permanently covered.
    Timer { interval: 30000; running: true; onTriggered: curtain.release() }
    Timer { id: quitAfterFade; interval: 500; onTriggered: Qt.quit() }
    function release() { releasing = true; shade = 0; quitAfterFade.restart(); }
    IpcHandler {
        target: "theme-curtain"
        function covered(): bool { return curtain.shade >= 0.999; }
        function release(): void { curtain.release(); }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "eroge-theme-curtain"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            Rectangle { anchors.fill: parent; color: "black"; opacity: curtain.shade }
            MouseArea { anchors.fill: parent }
        }
    }
}
