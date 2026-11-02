// THESIS: The Music Room is a lock screen that happens to play music.
// OWN-WORLD: The current cover fills the screen as a heavily blurred field of
// its own dominant colours; a lock-screen clock, the cover, the metadata and
// the transport float above it with nothing boxed.
// STORY: Artwork crossfades on every track change, the waveform runs on cava
// levels when they exist and says "Idle animation" when they do not.
// FIRST VIEWPORT: Clock, cover, title, artist, waveform, seek bar, transport.
// FORM: One centred column scaled to fit any screen instead of scrolling or
// clipping.
// FINISH: Every control routes through the same MprisPlayer the rest of the
// shell uses; nothing here holds its own playback state.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "Keyboard.js" as Keyboard

Item {
    id: music
    required property var state
    property bool keyboardBoundary: true

    readonly property var player: state.player
    readonly property string artUrl: state.player?.trackArtUrl || ""
    readonly property bool playing: state.player?.isPlaying ?? false
    readonly property bool lightSurface: !Theme.dark
    readonly property color surface: Theme.translucent(lightSurface ? Theme.paper : Theme.ink, lightSurface ? 0.62 : 0.55)
    readonly property color textColor: lightSurface ? Theme.ink : Theme.paper
    readonly property color dimColor: lightSurface ? Theme.muted : Theme.translucent(Theme.paper, 0.72)
    readonly property real margin: Math.max(24, Math.min(width, height) * 0.05)
    readonly property bool seekable: !!state.player && state.player.canSeek && state.player.lengthSupported && state.player.positionSupported && state.player.length > 0
    readonly property real fraction: seekable ? Math.max(0, Math.min(1, state.player.position / state.player.length)) : 0
    readonly property real elapsed: seek.dragging ? seek.dragFraction * player.length : (state.player?.position ?? 0)
    readonly property real columnWidth: Math.min(620, music.width - 2 * music.margin)

    function focusFirst() { Keyboard.first(music); }
    function seekTo(fraction) {
        if (!seekable || !state.player) return;
        state.player.position = Math.max(0, Math.min(1, fraction)) * state.player.length;
    }
    function nudge(seconds) {
        if (!seekable || !state.player) return;
        state.player.position = Math.max(0, Math.min(state.player.length, state.player.position + seconds));
    }
    function stamp(seconds) {
        // Quickshell reports MprisPlayer.position and .length in seconds.
        const total = Math.max(0, Math.round(seconds || 0));
        const pad = value => (value < 10 ? "0" : "") + value;
        const secs = total % 60;
        const minutes = Math.floor(total / 60) % 60;
        const hours = Math.floor(total / 3600);
        return hours > 0 ? hours + ":" + pad(minutes) + ":" + pad(secs) : minutes + ":" + pad(secs);
    }

    // Backdrop: one small buffer, blurred once, then scaled back up. The
    // buffer is a sixth of the screen, so the blur costs a fraction of a
    // full-screen pass and still resolves into something entirely soft.
    Item {
        id: backdrop
        anchors.fill: parent
        clip: true
        property bool artAOnTop: true
        property string currentUrl: ""
        function setArt(url) {
            if (url === currentUrl) return;
            currentUrl = url;
            const incoming = artAOnTop ? artB : artA;
            incoming.source = url;
            incoming.opacity = 0;
            fade.target = incoming;
            fade.to = 1;
            fade.restart();
            artAOnTop = !artAOnTop;
        }
        NumberAnimation { id: fade; property: "opacity"; to: 1; duration: 620; easing.type: Easing.InOutQuad }

        readonly property real factor: 6
        // The scale lives on the buffer itself. A wrapper Item carrying the
        // transform hides any child that is positioned inside it, anchored or
        // not, so the buffer is placed and scaled as one item.
        Item {
            id: buffer
            width: backdrop.width / backdrop.factor
            height: backdrop.height / backdrop.factor
            x: (backdrop.width - width) / 2
            y: (backdrop.height - height) / 2
            transformOrigin: Item.Center
            scale: backdrop.factor
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: Theme.tint }
                    GradientStop { position: 1; color: Theme.translucent(Theme.accent, 0.35) }
                }
            }
                Item {
                id: artStack
                anchors.fill: parent
                Image {
                    id: artA
                    anchors.fill: parent
                    source: backdrop.currentUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 256
                    asynchronous: true
                    smooth: true
                }
                Image {
                    id: artB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 256
                    asynchronous: true
                    smooth: true
                    opacity: 0
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: artStack
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 1.15
            }
        }
        Rectangle { anchors.fill: parent; color: music.surface }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: Theme.translucent(music.surface, 0.35) }
                GradientStop { position: 0.42; color: Theme.translucent(music.surface, 0.10) }
                GradientStop { position: 1; color: Theme.translucent(music.surface, 0.45) }
            }
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: { if (music.state.titlePage !== "") music.state.titlePage = ""; else music.state.shown = false; }
        Keys.onTabPressed: event => { Keyboard.move(music, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
        Keys.onBacktabPressed: event => { Keyboard.move(music, false); event.accepted = true; }

        Item {
            anchors.fill: parent
            ColumnLayout {
                id: stack
                anchors.centerIn: parent
                width: music.columnWidth
                spacing: 12
                readonly property real fit: Math.min(1, (parent.height - 2 * music.margin) / Math.max(1, implicitHeight))
                transformOrigin: Item.Center
                scale: fit

                RowLayout {
                    Layout.fillWidth: true
                    VnText {
                        text: music.state.dateText
                        color: music.dimColor
                        font.pixelSize: 13
                        font.letterSpacing: 0.8
                    }
                    Item { Layout.fillWidth: true }
                    VnText {
                        visible: text !== ""
                        text: music.state.wifiEnabled ? (music.state.wifiSsid || "Wi-Fi on") : "Wi-Fi off"
                        color: music.dimColor
                        font.pixelSize: 12
                        font.letterSpacing: 0.6
                    }
                    VnText {
                        visible: text !== ""
                        Layout.leftMargin: 16
                        text: music.state.hasBattery ? music.state.batteryText : ""
                        color: music.dimColor
                        font.pixelSize: 12
                        font.letterSpacing: 0.6
                    }
                }

                VnText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 26
                    text: music.state.timeText
                    color: music.textColor
                    font.pixelSize: 132
                    font.weight: Font.Light
                    font.letterSpacing: -2
                }
                VnText {
                    Layout.alignment: Qt.AlignHCenter
                    text: music.state.longDateText
                    color: music.dimColor
                    font.pixelSize: 15
                    font.letterSpacing: 1.4
                }

                Rectangle {
                    id: cover
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 22
                    Layout.bottomMargin: 16
                    width: Math.round(Math.min(stack.width * 0.42, music.height * 0.34, 330))
                    height: width
                    radius: width * 0.07
                    color: Theme.translucent(music.textColor, 0.08)
                    border.width: 1
                    border.color: Theme.translucent(music.textColor, 0.12)
                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: music.artUrl
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: Math.ceil(cover.width * 2)
                        asynchronous: true
                        smooth: true
                        clip: true
                        visible: status === Image.Ready
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                    }
                }

                VnText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: stack.width * 0.9
                    horizontalAlignment: Text.AlignHCenter
                    text: music.player?.trackTitle || "No music playing"
                    color: music.textColor
                    font.pixelSize: 21
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                VnText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: stack.width * 0.9
                    horizontalAlignment: Text.AlignHCenter
                    text: music.player?.trackArtist || (music.player ? music.player.identity : "Open your music player to begin.")
                    color: music.dimColor
                    font.pixelSize: 14
                    font.letterSpacing: 1.1
                    elide: Text.ElideRight
                }

                AudioSpectrum {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 520
                    Layout.topMargin: 18
                    Layout.preferredHeight: 76
                    state: music.state
                }

                FocusScope {
                    id: seek
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 520
                    Layout.preferredHeight: 26
                    Layout.topMargin: 6
                    focus: true
                    activeFocusOnTab: true
                    property bool dragging: false
                    readonly property real dragFraction: fractionAt(area.mouseX, area.x, area.width)
                    readonly property real shownFraction: dragging ? dragFraction : music.fraction
                    function fractionAt(mouseX, originX, span) { return Math.max(0, Math.min(1, (mouseX - originX) / Math.max(1, span))); }
                    Keys.onLeftPressed: event => { music.nudge(-5); event.accepted = true; }
                    Keys.onRightPressed: event => { music.nudge(5); event.accepted = true; }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Home) { music.seekTo(0); event.accepted = true; }
                        else if (event.key === Qt.Key_End) { music.seekTo(1); event.accepted = true; }
                        else if (event.key === Qt.Key_Space && !event.isAutoRepeat) { music.player?.togglePlaying(); event.accepted = true; }
                    }
                    Keys.onReturnPressed: event => { if (dragging) music.seekTo(dragFraction); event.accepted = true; }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 3; radius: 2
                        color: Theme.translucent(music.textColor, 0.18)
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * seek.shownFraction; height: 3; radius: 2
                        color: Theme.accent
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * seek.shownFraction - width / 2))
                        width: 11; height: 11; radius: 6
                        color: Theme.accent
                        visible: seek.activeFocus || seek.dragging || area.containsMouse
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: music.seekable
                        hoverEnabled: true
                        cursorShape: music.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onPressed: { seek.dragging = true; seek.forceActiveFocus(Qt.MouseFocusReason); }
                        onReleased: { if (seek.dragging) { music.seekTo(seek.dragFraction); seek.dragging = false; } }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 520
                    VnText {
                        text: music.stamp(music.elapsed)
                        color: music.dimColor
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    VnText {
                        text: music.player && music.player.length > 0 ? music.stamp(music.player.length) : "--:--"
                        color: music.dimColor
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    spacing: 22
                    MusicButton {
                        glyph: "shuffle"
                        diameter: 34
                        tint: music.textColor
                        enabled: !!music.player?.shuffleSupported
                        opacity: music.player?.shuffle === true ? 1 : 0.45
                        onClicked: { if (music.player?.shuffleSupported) music.player.shuffle = !music.player.shuffle; }
                    }
                    MusicButton {
                        glyph: "prev"
                        diameter: 44
                        tint: music.textColor
                        enabled: !!music.player?.canGoPrevious
                        onClicked: music.player?.previous()
                    }
                    MusicButton {
                        glyph: music.playing ? "pause" : "play"
                        diameter: 58
                        tint: music.textColor
                        enabled: !!music.player?.canTogglePlaying
                        onClicked: music.player?.togglePlaying()
                    }
                    MusicButton {
                        glyph: "next"
                        diameter: 44
                        tint: music.textColor
                        enabled: !!music.player?.canGoNext
                        onClicked: music.player?.next()
                    }
                }

                VnText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    text: "Esc return · Space play/pause · ← → seek"
                    color: music.dimColor
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                }
            }
        }
    }

    onArtUrlChanged: backdrop.setArt(artUrl)
    Component.onCompleted: backdrop.setArt(artUrl)
    Timer {
        interval: 1000
        repeat: true
        running: music.visible && music.playing && !!music.player
        onTriggered: music.player.positionChanged()
    }
}