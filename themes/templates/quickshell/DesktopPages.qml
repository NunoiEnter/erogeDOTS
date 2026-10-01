import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: pages
    required property var state
    property string page: "dashboard"
    property var screen: null
    readonly property var chapters: state.niri.workspaces.filter(w => !pages.screen || w.output === pages.screen.name)
    readonly property var titles: ({dashboard: "A little interlude", music: "Music Room", workspaces: "Flowchart", characters: "Load", connections: "System Config", workshop: "NixOS & Niri", extras: "Extra Mode"})
    spacing: 16
    function showPage(page) { if (state.shown) state.titlePage = page; else state.drawer.page = page; }
    function windowsFor(id) { return Object.values(state.niri.windows).filter(window => window.workspace_id === id); }
    RowLayout {
        Layout.fillWidth: true
        VnText { Layout.fillWidth: true; text: pages.titles[pages.page] || "System Config"; font.family: Theme.titleFont; font.pixelSize: 25; font.bold: true; color: Theme.accent }
        VnButton { compact: true; quiet: true; text: "Return"; onClicked: { if (pages.state.shown) pages.state.titlePage = ""; else pages.state.drawer.close(); } }
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
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
            sourceComponent: pages.page === "characters" ? characters : pages.page === "workspaces" ? workspaces : pages.page === "music" ? music : pages.page === "connections" ? connections : pages.page === "workshop" ? workshop : pages.page === "extras" ? extras : dashboard
            onSourceComponentChanged: scroll.contentY = 0
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
                VnButton { text: "Add a character"; onClicked: pages.state.launch(["ghostty", "--title=theme-tools", "-e", "theme-switch", "add"]) }
                VnButton { text: "Open theme picker"; onClicked: pages.state.launch(["ghostty", "--title=theme-tools", "-e", "theme-switch", "picker"]) }
            }
        }
    }
    Component {
        id: workspaces
        ColumnLayout {
            spacing: 16
            VnButton { text: "Open workspace overview"; onClicked: pages.state.launch(["niri", "msg", "action", "toggle-overview"]) }
            Repeater {
                model: pages.chapters
                ColumnLayout {
                    id: chapter
                    required property var modelData
                    Layout.fillWidth: true; spacing: 6
                    VnButton { Layout.fillWidth: true; selected: chapter.modelData.is_active; text: "Chapter " + chapter.modelData.idx.toString().padStart(2, "0") + (chapter.modelData.name ? " · " + chapter.modelData.name : ""); onClicked: pages.state.focusWorkspace(chapter.modelData.idx) }
                    Repeater {
                        model: pages.windowsFor(chapter.modelData.id)
                        VnButton {
                            required property var modelData
                            Layout.fillWidth: true; Layout.leftMargin: 16
                            quiet: true; compact: true; text: modelData.title || modelData.app_id
                            onClicked: pages.state.focusWindow(modelData.id)
                        }
                    }
                    VnText { visible: pages.windowsFor(chapter.modelData.id).length === 0; text: "An empty chapter"; color: Theme.muted; Layout.leftMargin: 16 }
                }
            }
        }
    }
    Component {
        id: connections
        ColumnLayout {
            spacing: 20
            RowLayout {
                Layout.fillWidth: true
                VnButton { Layout.fillWidth: true; text: pages.state.wifiEnabled ? "Wi-Fi · On" : "Wi-Fi · Off"; selected: pages.state.wifiEnabled; onClicked: pages.state.toggleWifi() }
                VnButton { Layout.fillWidth: true; text: pages.state.bluetoothAvailable ? (pages.state.bluetoothEnabled ? "Bluetooth · On" : "Bluetooth · Off") : "Bluetooth · N/A"; enabled: pages.state.bluetoothAvailable; selected: pages.state.bluetoothEnabled; onClicked: pages.state.toggleBluetooth() }
            }
            VnText { Layout.fillWidth: true; text: pages.state.wifiText; color: Theme.muted }
            VnSlider { Layout.fillWidth: true; label: "Volume"; enabled: !!pages.state.sink?.audio; value: pages.state.muted ? 0 : pages.state.volume; onMoved: value => pages.state.setVolume(value) }
            VnSlider { Layout.fillWidth: true; label: "Brightness"; enabled: pages.state.brightnessAvailable; value: pages.state.brightness; onMoved: value => pages.state.setBrightness(value) }
            Flow {
                Layout.fillWidth: true; spacing: 8
                VnButton { text: "Network"; enabled: pages.state.hasApp("nm-connection-editor"); onClicked: pages.state.launch(["nm-connection-editor"]) }
                VnButton { text: "Sound"; enabled: pages.state.hasApp("pavucontrol"); onClicked: pages.state.launch(["pavucontrol"]) }
                VnButton { text: "Bluetooth"; enabled: pages.state.bluetoothAvailable && pages.state.hasApp("blueman-manager"); onClicked: pages.state.launch(["blueman-manager"]) }
                VnButton { text: pages.state.dnd ? "DND · On" : "DND · Off"; selected: pages.state.dnd; onClicked: Quickshell.execDetached(["swaync-client", "--toggle-dnd"]) }
                VnButton { text: "Character theme"; onClicked: pages.showPage("characters") }
                VnButton { text: "Style: " + Theme.styleName; onClicked: pages.state.switchStyle() }
                VnButton { text: "NixOS & Niri"; onClicked: pages.showPage("workshop") }
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
            spacing: 14
            VnText { text: "A few things for your next scene."; color: Theme.muted }
            Repeater {
                model: [
                    {name: "Notification log", command: ["swaync-client", "-t", "-sw"]},
                    {name: "Clipboard history", command: ["cliphist-pick"]},
                    {name: "Open terminal", command: ["title-terminal"]},
                    {name: "Dropdown terminal", command: ["dropterm"]},
                    {name: "Four-panel terminal wall", command: ["larp"]},
                    {name: "Lock screen", command: ["qylock-lock"]}
                ]
                VnButton { required property var modelData; Layout.fillWidth: true; text: modelData.name; onClicked: { if (modelData.command[0] === "title-terminal") pages.state.openTitleTerminal(); else pages.state.launch(modelData.command); } }
            }
        }
    }
}
