import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: menu
    required property var state
    visible: state.shown && Theme.retro
    screen: state.menuScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "eroge-vn-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: state.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: if (visible) Qt.callLater(() => { closeButton.forceActiveFocus(); scroll.contentY = menu.state.menuSection === "music" ? Math.min(musicRoom.y, Math.max(0, scroll.contentHeight - scroll.height)) : 0; })

    // The entire visible backdrop accepts clicks; the card blocks them below.
    Rectangle { anchors.fill: parent; color: "#3d242432" }
    MouseArea { anchors.fill: parent; onClicked: menu.state.shown = false }
    Item {
        anchors.fill: parent
        Keys.onEscapePressed: menu.state.shown = false
        VnFrame {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.max(36, Math.min(120, menu.height * 0.14))
            width: Math.min(800, menu.width - 32)
            height: Math.min(610, menu.height - 110)
            // Keep taps in the dialogue frame from dismissing it.
            MouseArea { anchors.fill: parent }

            Rectangle {
                visible: !Theme.retro
                x: 24
                y: -18
                width: Math.min(nameplate.implicitWidth + 40, card.width - 48)
                height: 36
                radius: 3
                color: Theme.tint
                border.color: Theme.accent
                VnText {
                    id: nameplate
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    text: Theme.character || Theme.fullName || "erogeDOTS"
                    color: Theme.accent
                    font.family: Theme.titleFont
                    font.pixelSize: 16
                    font.bold: true
                }
            }
            Rectangle {
                visible: Theme.retro
                x: 5; y: 5; width: card.width - 10; height: 28
                color: Theme.accent
                VnText {
                    anchors.fill: parent; anchors.leftMargin: 10
                    text: "erogeDOTS — " + Theme.fullName
                    color: "#ffffff"; font.bold: true
                }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                anchors.topMargin: Theme.retro ? 44 : 30
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        VnText { Layout.fillWidth: true; text: Theme.retro ? "Control Panel" : "System menu"; font.family: Theme.titleFont; font.pixelSize: Theme.retro ? 21 : 25; font.bold: true }
                        VnText { Layout.fillWidth: true; text: Theme.retro ? "Connections, sound and your music room." : "A little pause between chapters."; color: Theme.muted; font.pixelSize: 12 }
                    }
                    VnButton { id: closeButton; text: "Return"; onClicked: menu.state.shown = false }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 24
                    ColumnLayout {
                        visible: card.width >= 680
                        Layout.minimumWidth: 220
                        Layout.preferredWidth: 220
                        Layout.maximumWidth: 220
                        Layout.fillHeight: true
                        spacing: 9
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 90
                            color: Theme.tint
                            border.color: Theme.line
                            Image {
                                anchors.fill: parent
                                anchors.margins: 5
                                source: Theme.wallpaper
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 640
                                clip: true
                            }
                        }
                        VnText { Layout.fillWidth: true; text: Theme.fullName; font.family: Theme.titleFont; font.pixelSize: 16; font.bold: true }
                        VnText { Layout.fillWidth: true; text: Theme.game; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: 11 }
                    }
                    Flickable {
                        id: scroll
                        Layout.minimumWidth: 160
                        Layout.preferredWidth: 450
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: controls.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ColumnLayout {
                            id: controls
                            width: scroll.width - 12
                            spacing: 9
                            VnText { text: "Connections"; font.family: Theme.titleFont; font.pixelSize: 16; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                VnButton {
                                    Layout.fillWidth: true
                                    text: menu.state.wifiEnabled ? "Wi-Fi · On" : "Wi-Fi · Off"
                                    selected: menu.state.wifiEnabled
                                    onClicked: menu.state.toggleWifi()
                                }
                                VnButton {
                                    Layout.fillWidth: true
                                    text: !menu.state.bluetoothAvailable ? "Bluetooth · N/A" : (menu.state.bluetoothEnabled ? "Bluetooth · On" : "Bluetooth · Off")
                                    enabled: menu.state.bluetoothAvailable
                                    selected: menu.state.bluetoothEnabled
                                    onClicked: menu.state.toggleBluetooth()
                                }
                            }
                            VnText { Layout.fillWidth: true; text: menu.state.wifiText; color: Theme.muted; font.pixelSize: 11 }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 18
                                VnSlider {
                                    Layout.fillWidth: true
                                    label: "Volume"
                                    enabled: menu.state.sink?.audio !== null && menu.state.sink?.audio !== undefined
                                    value: menu.state.muted ? 0 : menu.state.volume
                                    onMoved: value => menu.state.setVolume(value)
                                }
                                VnSlider {
                                    Layout.fillWidth: true
                                    label: "Brightness"
                                    enabled: menu.state.brightnessAvailable
                                    value: menu.state.brightness
                                    onMoved: value => menu.state.setBrightness(value)
                                }
                            }
                            VnButton {
                                text: menu.state.muted ? "Unmute sound" : "Mute sound"
                                compact: true
                                enabled: menu.state.sink?.audio !== null && menu.state.sink?.audio !== undefined
                                onClicked: { const audio = menu.state.sink?.audio; if (audio) audio.muted = !audio.muted; }
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                            RowLayout {
                                id: musicRoom
                                Layout.fillWidth: true
                                MediaArtwork {
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 64
                                    source: menu.state.player?.trackArtUrl || ""
                                    Accessible.name: "Current track artwork"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    VnText { text: "Music room"; font.family: Theme.titleFont; font.pixelSize: 16; font.bold: true }
                                    VnText {
                                        Layout.fillWidth: true
                                        text: menu.state.player?.trackTitle || "No music playing"
                                        color: Theme.muted
                                    }
                                    VnText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: menu.state.player?.trackArtist || ""
                                        color: Theme.muted
                                        font.pixelSize: 11
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                VnButton { compact: true; text: "Prev"; enabled: menu.state.player?.canGoPrevious ?? false; onClicked: menu.state.player.previous() }
                                VnButton { compact: true; text: menu.state.player?.isPlaying ? "Pause" : "Play"; enabled: menu.state.player?.canTogglePlaying ?? false; onClicked: menu.state.player.togglePlaying() }
                                VnButton { compact: true; text: "Next"; enabled: menu.state.player?.canGoNext ?? false; onClicked: menu.state.player.next() }
                                Item { Layout.fillWidth: true }
                                VnText { text: menu.state.player?.identity || ""; color: Theme.muted; font.pixelSize: 11; Layout.maximumWidth: 140 }
                            }
                            VnText {
                                Layout.fillWidth: true
                                text: menu.state.error
                                visible: text !== ""
                                wrapMode: Text.WordWrap
                                elide: Text.ElideNone
                                color: Theme.accent
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                VnButton { Layout.fillWidth: true; text: "Network"; enabled: menu.state.hasApp("nm-connection-editor"); onClicked: menu.state.launch(["nm-connection-editor"]) }
                                VnButton { Layout.fillWidth: true; text: "Sound"; enabled: menu.state.hasApp("pavucontrol"); onClicked: menu.state.launch(["pavucontrol"]) }
                                VnButton { Layout.fillWidth: true; text: "Bluetooth"; enabled: menu.state.bluetoothAvailable && menu.state.hasApp("blueman-manager"); onClicked: menu.state.launch(["blueman-manager"]) }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    VnButton {
                        Layout.fillWidth: true
                        text: card.width < 600 ? "Character" : "Character theme"
                        hint: "Choose a character palette and wallpaper"
                        onClicked: menu.state.launch(["ghostty", "--title=theme-tools", "-e", "theme-switch", "picker"])
                    }
                    VnButton {
                        Layout.fillWidth: true
                        text: "Style: " + (card.width < 600 ? (Theme.retro ? "Win98" : "VN") : Theme.styleName)
                        hint: "Switch to " + (Theme.retro ? "Romance VN" : "Windows 98")
                        onClicked: menu.state.switchStyle()
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    VnButton { compact: true; text: "Lock"; onClicked: menu.state.launch(["qylock-lock"]) }
                    VnButton { compact: true; text: "Night light"; onClicked: menu.state.launch(["sh", "-c", "pkill -x wlsunset || exec wlsunset -l 13.736717 -L 100.523186"]) }
                    VnButton { compact: true; text: "Log"; onClicked: menu.state.launch(["swaync-client", "-t", "-sw"]) }
                    Item { Layout.fillWidth: true }
                    VnText { text: "Esc to return"; color: Theme.muted; font.pixelSize: 11; visible: card.width > 620 }
                    VnButton { compact: true; text: "Session…"; onClicked: menu.state.session() }
                }
            }
        }
    }
}
