// THESIS: The top bar carries a pocket-sized Music Room: artwork, track and
// transport, one click from anywhere.
// OWN-WORLD: Everything routes through the shell MprisPlayer like every other
// music surface; the title click opens the fullscreen Music Room and the
// right click opens the quick-settings music section, matching the tabs.
// FINISH: Scroll seeks the track the same way the Sound tab scrolls volume.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: widget
    required property var state
    required property var barWindow
    spacing: 8

    readonly property var player: state.player
    readonly property bool playing: widget.player?.isPlaying ?? false
    readonly property bool seekable: !!widget.player && widget.player.canSeek && widget.player.lengthSupported && widget.player.positionSupported && widget.player.length > 0
    readonly property real infoSpan: barWindow.screen && barWindow.screen.width > 1500 ? 190 : 120

    function nudge(seconds) {
        if (!widget.seekable) return;
        widget.player.position = Math.max(0, Math.min(widget.player.length, widget.player.position + seconds));
    }

    function openRoom() { widget.state.openSection(widget.barWindow.screen, "music"); }
    function openDrawer() {
        const anchorX = widget.barWindow.contentItem ? info.mapToItem(widget.barWindow.contentItem, info.width, 0).x : 0;
        widget.state.drawer.pin(widget.barWindow.screen, "music", anchorX);
    }

    MediaArtwork {
        Layout.preferredWidth: 22; Layout.preferredHeight: 22
        radius: 6
        source: widget.player?.trackArtUrl || ""
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: widget.openRoom()
        }
    }

    Item {
        id: info
        Layout.fillHeight: true
        Layout.preferredWidth: widget.infoSpan
        WheelHandler { onWheel: event => { widget.nudge(event.angleDelta.y > 0 ? 5 : -5); event.accepted = true; } }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse && mouse.button === Qt.RightButton) widget.openDrawer();
                else widget.openRoom();
            }
        }
        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 1
            VnText {
                Layout.fillWidth: true
                text: widget.player?.trackTitle || "Music"
                color: Theme.ink
                font.family: Theme.titleFont
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            VnText {
                Layout.fillWidth: true
                text: widget.player?.trackArtist || "Music Room"
                color: Theme.muted
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    MusicButton {
        glyph: widget.playing ? "pause" : "play"
        diameter: 30
        enabled: !!widget.player?.canTogglePlaying
        onClicked: widget.player?.togglePlaying()
    }
    MusicButton {
        glyph: "next"
        diameter: 30
        enabled: !!widget.player?.canGoNext
        onClicked: widget.player?.next()
    }
}
