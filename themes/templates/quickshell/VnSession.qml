import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: session
    required property var state
    visible: state.sessionShown
    screen: state.menuScreen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "eroge-session-choice"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: if (visible) { state.playSessionSound("greeting"); Qt.callLater(() => choices.reset(state.sessionAction)); }
    Connections { target: session.state; function onSessionActionChanged() { if (session.visible) Qt.callLater(() => choices.reset(session.state.sessionAction)); } }
    Connections { target: choices.Window.window; function onActiveChanged() { if (session.visible && choices.Window.window.active) Qt.callLater(choices.focusCurrent); } }
    Image {
        anchors.fill: parent; visible: !Theme.retro
        source: Theme.wallpaper; fillMode: Image.PreserveAspectCrop
        sourceSize.width: session.screen ? session.screen.width * 2 : 1920
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Theme.retro ? Theme.translucent(Theme.ink, 0.55) : "#44000000" }
    SessionDialog {
        id: choices; anchors.fill: parent; state: session.state
        opacity: session.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutExpo } }
    }
}
