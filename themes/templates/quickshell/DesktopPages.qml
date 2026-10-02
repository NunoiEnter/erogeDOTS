import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import QtQuick.Window
import "Keyboard.js" as Keyboard

ColumnLayout {
    id: pages
    required property var state
    property string page: "dashboard"
    property bool keyboardBoundary: true
    property bool keyboardEnabled: false
    property var screen: null
    readonly property var chapters: state.niri.workspaces.filter(w => !pages.screen || w.output === pages.screen.name)
    readonly property var titles: ({dashboard: "A little interlude", music: "Music Room", workspaces: "Flowchart", characters: "Load", themeStudio: "Add a theme", connections: "System Config", workshop: "NixOS & Niri", extras: "Extra Mode"})
    spacing: 16
    function showPage(page) { if (state.shown) { state.titlePage = page; if (Theme.retro) state.menuSection = page; } else state.drawer.page = page; }
    function focusFirst() { if (body.item) Keyboard.first(body.item); }
    Keys.onTabPressed: event => { Keyboard.move(Window.window.activeFocusItem, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(Window.window.activeFocusItem, false); event.accepted = true; }
    Connections {
        target: pages.Window.window
        function onActiveFocusItemChanged() {
            const item = pages.Window.window.activeFocusItem;
            if (!item || !body.item || !Keyboard.inside(item, body.item)) return;
            const pos = item.mapToItem(scroll.contentItem, 0, 0);
            if (pos.y < scroll.contentY) scroll.contentY = Math.max(0, pos.y - 8);
            else if (pos.y + item.height > scroll.contentY + scroll.height)
                scroll.contentY = Math.min(Math.max(0, scroll.contentHeight - scroll.height), pos.y + item.height - scroll.height + 8);
        }
    }
    RowLayout {
        Layout.fillWidth: true
        VnText { Layout.fillWidth: true; text: pages.titles[pages.page] || "System Config"; font.family: Theme.titleFont; font.pixelSize: 25; font.bold: true; color: Theme.accent }
        VnButton { compact: true; quiet: true; text: "Return"; onClicked: { if (pages.state.shown) pages.state.titlePage = ""; else pages.state.drawer.close(); } }
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
    VnText { Layout.fillWidth: true; text: "↑ ↓ choices · Tab next · ← → adjust · Esc return"; font.pixelSize: 10; color: Theme.muted }
    Flickable {
        id: scroll
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: width; contentHeight: body.item ? body.item.implicitHeight : 0
        clip: true; boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { implicitWidth: 5; radius: 2; color: Theme.accent }
            background: Rectangle { implicitWidth: 5; radius: 2; color: Theme.tint }
        }
        onVisibleChanged: contentY = 0
        Loader {
            id: body; width: scroll.width - 10
            sourceComponent: pages.page === "themeStudio" ? themeStudio : pages.page === "characters" ? characters : pages.page === "workspaces" ? workspaces : pages.page === "music" ? music : pages.page === "connections" ? connections : pages.page === "workshop" ? workshop : pages.page === "extras" ? extras : dashboard
            onSourceComponentChanged: scroll.contentY = 0
            onLoaded: if (pages.keyboardEnabled) Qt.callLater(pages.focusFirst)
        }
    }
    Component {
        id: dashboard
        ColumnLayout {
            spacing: 20
            RowLayout {
                Layout.fillWidth: true; spacing: 16
                MediaArtwork { Layout.preferredWidth: 72; Layout.preferredHeight: 72; source: Theme.wallpaper }
                ColumnLayout {
                    Layout.fillWidth: true
                    VnText { text: pages.state.timeText; font.family: Theme.titleFont; font.pixelSize: 32 }
                    VnText { text: pages.state.dateText + " · " + Theme.fullName; color: Theme.muted }
                }
                ColumnLayout {
                    VnButton { compact: true; text: "Characters"; onClicked: pages.showPage("characters") }
                    VnButton { compact: true; text: "System Config"; onClicked: pages.showPage("connections") }
                }
            }
            MusicControls { Layout.fillWidth: true; state: pages.state; compact: true }
            VnText { text: "Your chapters"; font.family: Theme.titleFont; font.pixelSize: 18; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: pages.chapters
                    VnButton {
                        required property var modelData
                        text: "Chapter " + modelData.idx.toString().padStart(2, "0")
                        selected: modelData.is_active
                        onClicked: pages.state.focusWorkspace(modelData.idx)
                    }
                }
            }
            VnText { Layout.fillWidth: true; text: pages.state.wifiText + " · Battery " + pages.state.batteryText + " · " + pages.state.notificationCount + " notifications"; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        }
    }
    Component {
        id: music
        ColumnLayout {
            spacing: 20
            MusicControls { Layout.fillWidth: true; state: pages.state }
            VnSlider { Layout.fillWidth: true; label: "Volume"; enabled: pages.state.sink?.audio !== null && pages.state.sink?.audio !== undefined; value: pages.state.muted ? 0 : pages.state.volume; onMoved: value => pages.state.setVolume(value) }
            RowLayout {
                VnButton { text: pages.state.muted ? "Unmute" : "Mute"; enabled: !!pages.state.sink?.audio; onClicked: pages.state.toggleMute() }
                VnButton { text: "Sound settings"; enabled: pages.state.hasApp("pavucontrol"); onClicked: pages.state.launch(["pavucontrol"]) }
            }
        }
    }
    Component {
        id: characters
        ColumnLayout {
            spacing: 16
            VnText { Layout.fillWidth: true; text: "Choose a character. Their wallpaper and palette follow you back to the desktop."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
            AppearanceSettings { Layout.fillWidth: true; state: pages.state }
            GridLayout {
                Layout.fillWidth: true; columns: width > 660 ? 3 : 2
                columnSpacing: 12; rowSpacing: 12
                Repeater {
                    model: Theme.characters
                    VnButton {
                        id: slot
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 180
                        implicitHeight: 188
                        selected: modelData.id === Theme.characterId
                        text: modelData.name
                        hint: "Load " + modelData.name
                        contentItem: ColumnLayout {
                            spacing: 5
                            Image { Layout.fillWidth: true; Layout.preferredHeight: 116; source: slot.modelData.image; sourceSize.width: 400; fillMode: Image.PreserveAspectCrop; clip: true; asynchronous: true }
                            VnText { Layout.fillWidth: true; text: slot.modelData.name; font.family: Theme.titleFont; font.pixelSize: 15; font.bold: true; color: slot.selected ? Theme.paper : Theme.ink }
                            VnText { Layout.fillWidth: true; text: slot.selected ? "Currently selected" : slot.modelData.game; font.pixelSize: 10; color: slot.selected ? Theme.paper : Theme.muted }
                        }
                        onClicked: pages.state.changeCharacter(modelData.id)
                    }
                }
            }
            RowLayout {
                VnButton { text: "Add a character"; onClicked: pages.showPage("themeStudio") }
                VnButton { text: "Open theme picker"; onClicked: pages.state.launch(["ghostty", "--title=theme-tools", "-e", "theme-switch", "picker"]) }
            }
        }
    }
    Component {
        id: themeStudio
        ThemeStudio { state: pages.state }
    }
    Component {
        id: workspaces
        WorkspaceFlowchart { state: pages.state; chapters: pages.chapters }
    }
    Component {
        id: connections
        ColumnLayout {
            spacing: 20
            RowLayout {
                Layout.fillWidth: true
                VnAction { Layout.fillWidth: true; symbol: "wifi"; text: "Wi-Fi"; status: pages.state.wifiEnabled ? "On" : "Off"; external: false; selected: pages.state.wifiEnabled; onClicked: pages.state.toggleWifi() }
                VnAction { Layout.fillWidth: true; symbol: "bluetooth"; text: "Bluetooth"; status: pages.state.bluetoothAvailable ? (pages.state.bluetoothEnabled ? "On" : "Off") : "Unavailable"; external: false; enabled: pages.state.bluetoothAvailable; selected: pages.state.bluetoothEnabled; onClicked: pages.state.toggleBluetooth() }
            }
            VnText { Layout.fillWidth: true; text: pages.state.wifiText; color: Theme.muted }
            VnSlider { Layout.fillWidth: true; label: "Volume"; enabled: !!pages.state.sink?.audio; value: pages.state.muted ? 0 : pages.state.volume; onMoved: value => pages.state.setVolume(value) }
            VnSlider { Layout.fillWidth: true; label: "Brightness"; enabled: pages.state.brightnessAvailable; value: pages.state.brightness; onMoved: value => pages.state.setBrightness(value) }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                VnText { text: "Connections & sound"; font.family: Theme.titleFont; font.pixelSize: 18; color: Theme.accent; Layout.topMargin: 4; Layout.bottomMargin: 6 }
                VnAction { Layout.fillWidth: true; symbol: "wifi"; text: "Network"; description: "Wi-Fi and VPN profiles. Passwords and keys stay on this device."; enabled: pages.state.hasApp("nm-connection-editor"); onClicked: pages.state.launch(["nm-connection-editor"]) }
                VnAction { Layout.fillWidth: true; symbol: "sound"; text: "Sound"; description: "Choose your output, microphone and per-app volume."; enabled: pages.state.hasApp("pavucontrol"); onClicked: pages.state.launch(["pavucontrol"]) }
                VnAction { Layout.fillWidth: true; symbol: "bluetooth"; text: "Bluetooth devices"; description: pages.state.bluetoothAvailable ? "Pair headphones, controllers and other devices." : "No Bluetooth adapter is available."; enabled: pages.state.bluetoothAvailable && pages.state.hasApp("blueman-manager"); onClicked: pages.state.launch(["blueman-manager"]) }
                VnAction { Layout.fillWidth: true; symbol: "bell"; text: "Do Not Disturb"; description: "Pause notification pop-ups without clearing your history."; status: pages.state.dnd ? "On" : "Off"; external: false; selected: pages.state.dnd; onClicked: Quickshell.execDetached(["swaync-client", "--toggle-dnd"]) }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line; Layout.topMargin: 12; Layout.bottomMargin: 12 }
                VnText { text: "Your next scene"; font.family: Theme.titleFont; font.pixelSize: 18; color: Theme.accent; Layout.bottomMargin: 6 }
                VnAction { Layout.fillWidth: true; symbol: "theme"; text: "Character theme"; description: "Choose a wallpaper and character palette."; external: false; onClicked: pages.showPage("characters") }
                VnAction { Layout.fillWidth: true; symbol: "style"; text: "Desktop style"; description: "Switch the interface; keep your current character."; status: Theme.styleName; external: false; enabled: !pages.state.themeBusy; onClicked: pages.state.switchStyle() }
                VnAction { Layout.fillWidth: true; symbol: "settings"; text: "NixOS & Niri"; description: "Packages, window layout and config files. Saving and applying stay separate."; external: false; onClicked: pages.showPage("workshop") }
            }
            VnText { Layout.fillWidth: true; visible: text !== ""; text: pages.state.error; color: Theme.accent; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        }
    }
    Component {
        id: workshop
        SystemWorkshop { state: pages.state }
    }
    Component {
        id: extras
        ColumnLayout {
            spacing: 4
            VnText { Layout.fillWidth: true; text: "Small tools for the chapter you are in."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone; Layout.bottomMargin: 12 }
            Repeater {
                model: [
                    {name: "Notification log", symbol: "bell", description: "Read earlier notifications and manage the notification center.", command: ["swaync-client", "-t", "-sw"]},
                    {name: "Clipboard history", symbol: "clipboard", description: "Find something you copied and put it back on the clipboard.", command: ["cliphist-pick"]},
                    {name: "Open terminal", symbol: "terminal", description: "A floating terminal over your character scene.", command: ["title-terminal"]},
                    {name: "Dropdown terminal", symbol: "dropdown", description: "Show or hide your pull-down command line.", command: ["dropterm"]},
                    {name: "Four-panel terminal wall", symbol: "grid", description: "Open your four-terminal workspace.", command: ["larp"]},
                    {name: "Lock screen", symbol: "lock", description: "Keep your session running. Ask for confirmation before locking.", command: ["qylock-lock"]}
                ]
                VnAction { required property var modelData; Layout.fillWidth: true; text: modelData.name; symbol: modelData.symbol; description: modelData.description; external: modelData.command[0] !== "qylock-lock"; onClicked: { if (modelData.command[0] === "title-terminal") pages.state.openTitleTerminal(); else if (modelData.command[0] === "qylock-lock") pages.state.session("lock"); else pages.state.launch(modelData.command); } }
            }
        }
    }
}
