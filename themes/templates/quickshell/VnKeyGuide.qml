import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

// Romance VN key guide. Niri's built-in hotkey overlay is unstyled CSD, so the
// guide renders the same titled binds as cream stationery cards instead.
PanelWindow {
    id: guide
    required property var state
    visible: state.keyGuideShown
    screen: state.keyGuideScreen
    anchors { top: true; bottom: true; left: true; right: true }
    implicitWidth: 1080
    implicitHeight: 700
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "eroge-key-guide"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    readonly property var binds: state.keyGuideBinds
    // The search field is the single source of truth for the filter, so the two
    // can never drift apart.
    readonly property string filter: searchField.text
    readonly property var shownBinds: filter.trim() === ""
        ? binds
        : binds.filter(bind => (bind.keys + " " + bind.title).toLowerCase().indexOf(filter.trim().toLowerCase()) !== -1)
    readonly property int columns: guide.width > 1500 ? 3 : (guide.width > 1020 ? 2 : 1)
    readonly property int rowsPerColumn: Math.max(1, Math.ceil(shownBinds.length / columns))
    onVisibleChanged: if (visible) { searchField.text = ""; Qt.callLater(() => searchField.forceActiveFocus(Qt.TabFocusReason)); }
    Connections { target: guide.contentItem.Window.window; function onActiveChanged() { if (guide.visible && guide.contentItem.Window.window.active) Qt.callLater(() => searchField.forceActiveFocus(Qt.TabFocusReason)); } }
    Image {
        anchors.fill: parent; visible: !Theme.retro
        source: Theme.wallpaper; fillMode: Image.PreserveAspectCrop
        sourceSize.width: guide.screen ? guide.screen.width * 2 : 1920
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Theme.translucent(Theme.ink, Theme.retro ? 0.55 : 0.42) }
    FocusScope {
        id: scope; anchors.fill: parent; focus: true
        Keys.onEscapePressed: guide.state.closeKeyGuide()
        Keys.onReturnPressed: { guide.state.closeKeyGuide(); event.accepted = true; }
        VnFrame {
            anchors.centerIn: parent
            width: Math.min(guide.columns === 1 ? 560 : 1080, guide.width - 64)
            height: Math.min(700, guide.height - 72)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Ornament { Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        VnText { text: "Key Guide"; font.family: Theme.titleFont; font.pixelSize: 26; font.bold: true; color: Theme.accent }
                        VnText { text: Theme.character; font.family: Theme.titleFont; font.pixelSize: 11; color: Theme.muted }
                    }
                    VnField {
                        id: searchField
                        Layout.preferredWidth: 220
                        placeholderText: "Search shortcuts"
                        onAccepted: guide.state.closeKeyGuide()
                    }
                    VnButton { compact: true; text: "Close"; onClicked: guide.state.closeKeyGuide() }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                VnText {
                    Layout.fillWidth: true
                    text: guide.binds.length === 0 && guide.state.keyGuideError === ""
                        ? "No bindings found in the niri config."
                        : (guide.state.keyGuideError !== "" ? guide.state.keyGuideError : guide.shownBinds.length + " of " + guide.binds.length + " shortcuts")
                    color: guide.state.keyGuideError !== "" ? Theme.accent : Theme.muted
                    font.pixelSize: 11
                }
                Flickable {
                    id: list
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    readonly property real columnWidth: (width - 28 * (guide.columns - 1)) / guide.columns
                    readonly property real gridHeight: guide.rowsPerColumn * 26
                    contentWidth: width
                    contentHeight: Math.max(height, gridHeight)
                    Item {
                        x: 0
                        y: Math.max(0, (list.height - list.gridHeight) / 2)
                        width: list.width
                        height: list.gridHeight
                        Repeater {
                            model: guide.shownBinds
                            delegate: KeyGuideRow {
                                owner: guide
                                slot: index
                                x: (index % guide.columns) * (list.columnWidth + 28)
                                y: Math.floor(index / guide.columns) * 26
                                width: list.columnWidth
                                height: 26
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                VnText { text: "Super+Shift+/ opens this guide · Esc closes"; color: Theme.muted; font.pixelSize: 11 }
            }
        }
    }
}