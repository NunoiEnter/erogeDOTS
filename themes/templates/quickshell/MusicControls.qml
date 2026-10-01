import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: music
    required property var state
    property bool compact: false
    spacing: 16
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        MediaArtwork {
            Layout.preferredWidth: music.compact ? 76 : 140
            Layout.preferredHeight: music.compact ? 76 : 140
            source: music.state.player?.trackArtUrl || ""
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            VnText { Layout.fillWidth: true; text: music.state.player?.trackTitle || "No music playing"; font.family: Theme.titleFont; font.pixelSize: music.compact ? 18 : 23; wrapMode: music.compact ? Text.NoWrap : Text.WordWrap; elide: music.compact ? Text.ElideRight : Text.ElideNone }
            VnText { Layout.fillWidth: true; text: music.state.player?.trackArtist || "Open your music player to begin."; color: Theme.muted; wrapMode: music.compact ? Text.NoWrap : Text.WordWrap; elide: music.compact ? Text.ElideRight : Text.ElideNone }
            VnText { Layout.fillWidth: true; text: music.state.player?.trackAlbum || music.state.player?.identity || ""; color: Theme.muted; font.pixelSize: 11 }
            RowLayout {
                VnButton { compact: music.compact; text: "Prev"; enabled: music.state.player?.canGoPrevious ?? false; onClicked: music.state.player.previous() }
                VnButton { compact: music.compact; text: music.state.player?.isPlaying ? "Pause" : "Play"; enabled: music.state.player?.canTogglePlaying ?? false; onClicked: music.state.player.togglePlaying() }
                VnButton { compact: music.compact; text: "Next"; enabled: music.state.player?.canGoNext ?? false; onClicked: music.state.player.next() }
            }
        }
    }
    VnSlider {
        Layout.fillWidth: true
        visible: !music.compact && (music.state.player?.positionSupported ?? false) && (music.state.player?.lengthSupported ?? false)
        label: "Track progress"
        enabled: music.state.player?.canSeek ?? false
        value: music.state.player?.length > 0 ? music.state.player.position / music.state.player.length : 0
        onMoved: value => { if (music.state.player?.canSeek) music.state.player.position = value * music.state.player.length; }
    }
    AudioSpectrum {
        Layout.fillWidth: true
        visible: !music.compact
        state: music.state
    }
    Timer {
        interval: 1000; repeat: true
        running: music.visible && !music.compact && (music.state.shown || music.state.drawer.shown) && (music.state.player?.isPlaying ?? false)
        onTriggered: music.state.player.positionChanged()
    }
}
