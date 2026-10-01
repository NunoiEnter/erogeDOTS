import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: title
    required property var state
    visible: state.shown && !Theme.retro
    screen: state.menuScreen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.paper
    WlrLayershell.namespace: "eroge-title-screen"
    WlrLayershell.layer: state.titleTerminalVisible ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible && !(state.titleTerminalVisible && state.titleTerminalInput) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    function focusSelection() {
        state.titleTerminalInput = false;
        const choices = {characters: characterChoice, workspaces: workspaceChoice, music: musicChoice, extras: extraChoice, connections: configChoice, workshop: configChoice};
        (choices[state.titlePage] || firstChoice).forceActiveFocus();
    }
    onVisibleChanged: if (visible) Qt.callLater(focusSelection)
    Connections { target: title.state; function onTitlePageChanged() { if (title.visible) Qt.callLater(title.focusSelection); } }
    Image {
        anchors.fill: parent; source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: title.screen ? title.screen.width * 2 : 1920
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.paper }
            GradientStop { position: 0.30; color: Theme.translucent(Theme.paper, 0.97) }
            GradientStop { position: 0.53; color: Theme.translucent(Theme.paper, 0.60) }
            GradientStop { position: 0.76; color: Theme.translucent(Theme.paper, 0.06) }
        }
    }
    FocusScope {
        anchors.fill: parent; focus: true
        Keys.onEscapePressed: { if (title.state.titlePage !== "") title.state.titlePage = ""; else title.state.shown = false; }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.max(32, title.width * 0.055)
            anchors.rightMargin: Math.max(32, title.width * 0.045)
            anchors.topMargin: 48; anchors.bottomMargin: 32
            spacing: Math.max(28, title.width * 0.035)
            ColumnLayout {
                Layout.preferredWidth: title.width > 1000 ? 320 : 260
                Layout.maximumWidth: title.width > 1000 ? 320 : 260
                Layout.fillHeight: true
                spacing: 0
                RowLayout {
                    spacing: 12
                    Ornament { Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    VnText { text: "eroge＊DOTS"; font.family: Theme.titleFont; font.pixelSize: 34; font.bold: true; color: Theme.accent }
                }
                VnText { Layout.fillWidth: true; text: Theme.game; font.family: Theme.titleFont; font.pixelSize: 12; color: Theme.muted; Layout.topMargin: 6; Layout.bottomMargin: 28 }
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: choices.implicitHeight
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: choices; width: parent.width; spacing: 2
                        TitleChoice { id: firstChoice; Layout.fillWidth: true; text: "New Game"; japanese: "はじめから"; description: "Launch an application"; onClicked: title.state.launch(["fuzzel"]) }
                        TitleChoice { id: characterChoice; Layout.fillWidth: true; text: "Load"; japanese: "ロード"; description: "Choose your character and wallpaper"; selected: title.state.titlePage === "characters"; onClicked: title.state.titlePage = "characters" }
                        TitleChoice { Layout.fillWidth: true; text: "Continue"; japanese: "つづきから"; description: "Return to your desktop"; onClicked: title.state.shown = false }
                        TitleChoice { id: workspaceChoice; Layout.fillWidth: true; text: "Flowchart"; japanese: "フローチャート"; description: "Your workspaces and open windows"; selected: title.state.titlePage === "workspaces"; onClicked: title.state.titlePage = "workspaces" }
                        TitleChoice { id: musicChoice; Layout.fillWidth: true; text: "Music Room"; japanese: "音楽室"; description: "Now playing and sound controls"; selected: title.state.titlePage === "music"; onClicked: title.state.titlePage = "music" }
                        TitleChoice { id: extraChoice; Layout.fillWidth: true; text: "Extra Mode"; japanese: "エクストラ"; description: "Desktop tools and notification log"; selected: title.state.titlePage === "extras"; onClicked: title.state.titlePage = "extras" }
                        TitleChoice { id: configChoice; Layout.fillWidth: true; text: "System Config"; japanese: "システム設定"; description: "Connections, NixOS and desktop settings"; selected: title.state.titlePage === "connections" || title.state.titlePage === "workshop"; onClicked: title.state.titlePage = "connections" }
                        TitleChoice { Layout.fillWidth: true; text: "Exit"; japanese: "終了"; description: "Lock, sleep or end the session"; onClicked: title.state.session() }
                    }
                }
                VnButton { text: "Terminal"; Layout.topMargin: 12; onClicked: title.state.openTitleTerminal() }
                VnButton { text: "Menu focus"; visible: title.state.titleTerminalVisible; onClicked: title.focusSelection() }
                VnText { text: "↑ ↓ choose · Enter select · Esc return"; color: Theme.muted; font.pixelSize: 11; Layout.topMargin: 10 }
            }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                VnFrame {
                    anchors.fill: parent
                    anchors.topMargin: 54; anchors.bottomMargin: 26
                    visible: title.state.titlePage !== ""
                    opacity: visible ? 1 : 0
                    DesktopPages { anchors.fill: parent; anchors.margins: 24; state: title.state; page: title.state.titlePage; screen: title.screen }
                }
                Column {
                    visible: title.state.titlePage === ""
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    spacing: 8
                    Rectangle {
                        width: characterName.implicitWidth + 48; height: 58
                        color: Theme.translucent(Theme.paper, 0.96); border.color: Theme.line
                        VnText { id: characterName; anchors.centerIn: parent; text: Theme.character; font.family: Theme.titleFont; font.pixelSize: 25; color: Theme.accent; font.bold: true }
                    }
                    VnText { anchors.right: parent.right; text: Theme.fullName; font.family: Theme.titleFont; font.pixelSize: 16; color: Theme.ink }
                }
            }
        }
    }
}
