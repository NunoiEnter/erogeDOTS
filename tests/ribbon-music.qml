import QtQuick
import QtQuick.Window
import Quickshell

// Offscreen proof for the top-bar pocket Music Room: the mini player routes
// playback through the shell player, the title opens the fullscreen Music
// Room, right click opens the quick-settings music section, and scrolling
// seeks the track when the player allows it.
ShellRoot {
    id: test
    property int step: 0
    property var calls: []

    property var player: ({
        isPlaying: true,
        trackTitle: "Bloom",
        trackArtist: "Harumi",
        trackArtUrl: "file:///nonexistent-cover.png",
        identity: "youtube-music",
        length: 214,
        position: 42,
        lengthSupported: true,
        positionSupported: true,
        canSeek: true,
        canGoNext: true,
        canGoPrevious: true,
        canTogglePlaying: true,
        togglePlaying: function() { this.isPlaying = !this.isPlaying; },
        next: function() { test.calls.push("next"); },
        previous: function() { test.calls.push("previous"); },
        positionChanged: function() {}
    })

    QtObject {
        id: fake
        property var player: test.player
        property string titlePage: ""
        property string menuSection: ""
        function openSection(screen, section) { test.calls.push("openSection:" + section); }
        property var drawer: QtObject {
            property bool shown: false
            property string page: ""
            function pin() { test.calls.push("drawer:pin"); }
            function leave() {}
        }
        property string timeText: "21:04"
        property string dateText: "Sun, 19 Oct"
        property string longDateText: "Sunday, 19 October"
        property bool wifiEnabled: true
        property string wifiSsid: "Harumi-5G"
        property bool hasBattery: true
        property string batteryText: "36%"
    }

    Window {
        id: window
        visible: true; width: 1400; height: 80
        Item {
            anchors.fill: parent
            RibbonMusic { id: widget; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; state: fake; barWindow: window.contentItem }
        }
    }

    function bump() { player = Object.assign({}, player); fake.player = player; }
    function all(item, predicate) {
        let result = [];
        for (const child of item.children || []) {
            if (predicate(child)) result.push(child);
            result = result.concat(all(child, predicate));
        }
        return result;
    }
    function labels() { return test.all(widget, item => typeof item.text === "string").map(item => item.text); }
    function glyph(name) {
        const found = test.all(widget, item => item.glyph === name);
        if (!found.length) throw new Error("Missing mini transport control: " + name);
        return found[0];
    }
    function expect(value, message) { if (!value) throw new Error(message); }

    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: try {
            test.step++;
            if (test.step === 1) {
                const seen = test.labels();
                test.expect(seen.includes("Bloom"), "Track title is shown in the bar");
                test.expect(seen.includes("Harumi"), "Artist is shown in the bar");
            }
            if (test.step === 2) {
                test.glyph("pause").clicked();
                test.glyph("next").clicked();
                test.expect(test.calls.includes("next"), "Next routes to the player");
                test.expect(test.player.isPlaying === false, "Play/pause writes through to the player");
                test.bump();
            }
            if (test.step === 3) {
                test.expect(test.glyph("play").enabled, "The glyph follows the new playback state");
                widget.nudge(-10);
                test.expect(test.player.position === 32, "Scroll seek rewinds the player");
                widget.nudge(100000);
                test.expect(test.player.position === test.player.length, "Scroll seek clamps to the track length");
                test.bump();
            }
            if (test.step === 4) {
                widget.openRoom();
                widget.openDrawer();
                test.expect(test.calls.includes("openSection:music"), "Left click opens the fullscreen Music Room");
                test.expect(test.calls.includes("drawer:pin"), "Right click opens the quick-settings music section");
            }
            if (test.step === 5) {
                fake.player = null;
                test.expect(test.labels().includes("No music playing") || test.labels().includes("Music"), "A missing player reads as no music");
                test.expect(!test.glyph("play").enabled && !test.glyph("next").enabled, "Mini transport disables without a player");
                console.log("PASS: Top-bar music widget"); Qt.exit(0);
            }
        } catch (error) { console.log("FAIL: Top-bar music widget — " + error.message); Qt.exit(1); }
    }
}
