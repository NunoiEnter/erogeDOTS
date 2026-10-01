import QtQuick
import Quickshell

ShellRoot {
    id: test
    property int step: 0
    QtObject { id: output }
    DrawerState { id: drawer }
    function expect(condition, message) { if (!condition) throw new Error(message); }
    Component.onCompleted: drawer.hover(output, "dashboard", 400)
    Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            test.step++;
            if (test.step === 1) test.expect(!drawer.shown, "A brief crossing must not open a drawer");
            if (test.step === 2) {
                test.expect(drawer.shown && drawer.page === "dashboard", "A deliberate hover opens dashboard");
                drawer.hover(output, "music", 600);
                test.expect(drawer.page === "music", "Switch panels without closing the drawer");
                drawer.leave();
            }
            if (test.step === 4) {
                test.expect(drawer.shown, "Grace period lets the pointer cross into the panel");
                drawer.hold();
            }
            if (test.step === 7) { test.expect(drawer.shown, "Panel remains open while hovered"); drawer.leave(); }
            if (test.step === 11) {
                test.expect(!drawer.shown, "Leaving both trigger and panel closes it");
                drawer.pin(output, "workspaces", 500);
                drawer.leave();
            }
            if (test.step === 15) {
                test.expect(drawer.shown && drawer.pinned, "Clicked panel stays open for keyboard use");
                drawer.allowed = false;
                test.expect(!drawer.shown && !drawer.pinned, "Opening title menu dismisses popouts");
                drawer.hover(output, "characters", 800);
            }
            if (test.step === 18) {
                test.expect(!drawer.shown, "Disabled hover cannot steal the title screen");
                console.log("PASS: drawer hover state");
                Qt.quit();
            }
        }
    }
}
