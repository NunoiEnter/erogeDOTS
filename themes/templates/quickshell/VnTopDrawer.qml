import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window
    required property var state
    readonly property var drawer: state.drawer
    property real progress: drawer.shown ? 1 : 0
    readonly property real panelWidth: drawer.page === "characters" ? 820 : drawer.page === "dashboard" ? 740 : drawer.page === "connections" ? 480 : 620
    readonly property real panelHeight: drawer.page === "characters" ? 620 : drawer.page === "dashboard" ? 520 : 500
    visible: !Theme.retro && (drawer.shown || progress > 0)
    screen: drawer.screen
    anchors { top: true; left: true; right: true }
    margins.top: 40
    implicitHeight: Math.min(panelHeight, (screen ? screen.height : 864) - 64)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "eroge-top-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: drawer.pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { x: card.x; y: 0; width: card.width; height: Math.max(0, card.height * window.progress) }
    Behavior on progress { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
    onVisibleChanged: if (visible && drawer.pinned) Qt.callLater(() => focusScope.forceActiveFocus())
    Connections { target: window.drawer; function onPinnedChanged() { if (window.drawer.pinned) Qt.callLater(() => focusScope.forceActiveFocus()); } }
    Item {
        anchors.fill: parent; clip: true
        FocusScope {
            id: focusScope; anchors.fill: parent
            Keys.onEscapePressed: window.drawer.close()
            VnFrame {
                id: card
                width: Math.min(window.panelWidth, window.width - 32)
                height: window.height - 8
                x: Math.max(16, Math.min(window.width - width - 16, window.drawer.center - width / 2))
                y: -height * (1 - window.progress)
                opacity: 0.4 + 0.6 * window.progress
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                HoverHandler { onHoveredChanged: { if (hovered) window.drawer.hold(); else window.drawer.leave(); } }
                DesktopPages {
                    anchors.fill: parent; anchors.margins: 24
                    state: window.state; page: window.drawer.page; screen: window.screen
                }
            }
        }
    }
}
