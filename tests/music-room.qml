import QtQuick
import QtQuick.Window
import Quickshell

// Offscreen integration proof: the Music Room must drive the same player
// object the rest of the shell hands out, must label its fallback honestly,
// and must never paint outside the screen it is given.
//
// The fake player is a plain JS object on purpose: a QML property named
// position would auto-generate a positionChanged signal and collide with the
// MPRIS method the room polls.
ShellRoot {
    id: test
    property int step: 0
    property var calls: []

    property var player: ({
        isPlaying: true,
        trackTitle: "Bloom",
        trackArtist: "Harumi",
        trackAlbum: "NixOwOS",
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
        shuffleSupported: true,
        shuffle: false,
        togglePlaying: function() { this.isPlaying = !this.isPlaying; },
        next: function() { test.calls.push("next"); },
        previous: function() { test.calls.push("previous"); },
        positionChanged: function() {}
    })

    QtObject {
        id: fake
        property var player: test.player
        property var audioLevels: Array(48).fill(0.6)
        property string audioError: ""
        property bool shown: true
        property string titlePage: "music"
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
        visible: true; width: 1920; height: 1080
        MusicRoom { id: room; anchors.fill: parent; state: fake }
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
    function labels() { return test.all(room, item => typeof item.text === "string").map(item => item.text); }
    function glyph(name) {
        const found = test.all(room, item => item.glyph === name);
        if (!found.length) throw new Error("Missing transport control: " + name);
        return found[0];
    }
    function expect(value, message) { if (!value) throw new Error(message); }

    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: try {
            test.step++;
            if (test.step === 1) {
                const seen = test.labels();
                test.expect(seen.includes("Bloom"), "Track title is shown");
                test.expect(seen.includes("Harumi"), "Artist is shown");
                test.expect(seen.includes("21:04"), "Clock is shown");
                test.expect(seen.includes("Sunday, 19 October"), "Date sits under the clock");
                test.expect(seen.includes("0:42"), "Elapsed time is formatted from the player");
                test.expect(seen.includes("3:34"), "Duration is formatted from the player");
            }
            if (test.step === 2) {
                test.glyph("prev").clicked();
                test.glyph("next").clicked();
                test.glyph("pause").clicked();
                test.glyph("shuffle").clicked();
                test.expect(JSON.stringify(test.calls) === JSON.stringify(["previous", "next"]), "Transport routes to the player, not to a local copy");
                test.expect(test.player.isPlaying === false, "Play/pause writes through to the player");
                test.expect(test.player.shuffle === true, "Shuffle writes through to the player");
                test.bump();
            }
            if (test.step === 3) {
                test.expect(test.glyph("play").enabled, "The glyph follows the new playback state");
                room.seekTo(0.5);
                test.expect(Math.abs(test.player.position - 107) < 0.5, "Seek maps to player position");
                test.player.position = 42;
                room.nudge(-10);
                test.expect(test.player.position === 32, "Keyboard nudge rewinds the player");
                room.nudge(100000);
                test.expect(test.player.position === test.player.length, "Nudge clamps to the track length");
                test.bump();
            }
            if (test.step === 4) {
                fake.player = null;
                test.expect(test.labels().includes("No music playing"), "A missing player reads as no music playing");
                test.expect(!test.glyph("prev").enabled && !test.glyph("next").enabled, "Transport disables without a player");
                const before = test.player.position;
                room.seekTo(0.5);
                test.expect(test.player.position === before, "Seek is inert without a player");
                fake.player = test.player;
            }
            if (test.step === 5) {
                fake.audioError = "Audio capture could not start.";
            }
            if (test.step === 6) {
                test.expect(test.labels().includes("Idle animation · no audio data"), "Fallback is labelled, never passed off as audio data");
                fake.audioError = "";
                window.width = 1280; window.height = 720;
            }
            if (test.step === 7) {
                const stack = test.all(room, item => item.fit !== undefined)[0];
                test.expect(stack.width * stack.fit <= window.width + 1, "Column stays inside a 1280x720 screen");
                test.expect(stack.height * stack.fit <= window.height + 1, "Column does not overflow a short screen");
                window.width = 800; window.height = 600;
            }
            if (test.step === 8) {
                const stack = test.all(room, item => item.fit !== undefined)[0];
                test.expect(stack.width * stack.fit <= window.width + 1, "Column stays inside an 800x600 screen");
                test.expect(stack.fit < 1, "Short screens scale the column down instead of clipping");
                console.log("PASS: Music Room lock screen"); Qt.exit(0);
            }
        } catch (error) { console.log("FAIL: Music Room — " + error.message); Qt.exit(1); }
    }
}