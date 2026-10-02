import QtQuick
import QtQuick.Window
import Quickshell

ShellRoot {
    id: test
    property int step: 0
    property bool populated: false
    QtObject {
        id: fake
        property var niri: ({workspaces: []})
        property string menuSection: "connections"
        property bool shown: true
        property string titlePage: Quickshell.env("TEST_PAGE") || "workshop"
        property string workshopSection: Quickshell.env("TEST_SECTION") || "packages"
        property bool themeBusy: false
        property string error: ""
        function setAppearance(kind, value) { console.log("appearance", kind, value); }
        function launch(command) { console.log("launch", command); }
        function openTitleTerminal(command) { console.log("terminal", command); }
    }
    Window {
        id: window
        visible: true; width: Number(Quickshell.env("TEST_WIDTH")) || 780; height: 980
        Rectangle { anchors.fill: parent; color: Theme.paper }
        DesktopPages { id: pages; anchors.fill: parent; anchors.margins: 28; state: fake; page: fake.titlePage; keyboardEnabled: true }
    }
    function all(item) { let result = [item]; for (const child of item.children || []) result = result.concat(all(child)); return result; }
    function expect(value, message) { if (!value) { console.error("FAIL:", message); Qt.quit(); throw new Error(message); } }
    Timer {
        interval: 300; repeat: true; running: true
        onTriggered: {
            test.step++;
            const items = test.all(pages);
            const studio = items.find(i => i.catalog !== undefined);
            const workshop = items.find(i => i.system !== undefined);
            if ((workshop && workshop.busy) || (studio && studio.busy)) return;
            if (test.step < 3) return;
            if (studio) {
                test.expect(studio.catalog.palettes.length === 6, "Rust palette catalog loaded");
                if (!test.populated) {
                // Populate an actual preview using a shipped character; no changes are saved.
                const fields = items.filter(i => i.placeholderText !== undefined);
                fields.find(i => i.placeholderText.startsWith("my-character")).text = "new-character";
                fields.find(i => i.placeholderText === "Full name").text = "Harumi Ena";
                fields.find(i => i.placeholderText.startsWith("Japanese,")).text = "陽見恵凪";
                fields.find(i => i.placeholderText.startsWith("Where your")).text = "LimeLight Lemonade Jam";
                fields.find(i => i.placeholderText.startsWith("Full image")).text = Theme.wallpaper;
                test.expect(items.some(i => i.text === "Create theme" && i.enabled), "Complete form allows creation");
                studio.choose(3); test.populated = true; return;
                }
                if (!studio.wallpaperReady) return;
            }
            if (workshop) {
                test.expect(workshop.system.niri !== null, "Real layout settings loaded");
                if (Quickshell.env("TEST_SEARCH") && !workshop.searched && !workshop.failed) { workshop.request({operation: "search", query: Quickshell.env("TEST_SEARCH")}); return; }
                test.expect(!workshop.failed, workshop.message);
                if (fake.workshopSection === "packages" && Quickshell.env("TEST_SEARCH")) test.expect(workshop.results.length > 0, "Real Nixpkgs results loaded");
            }
            const destination = Quickshell.env("TEST_SCREENSHOT");
            if (destination) {
                window.contentItem.grabToImage(result => { result.saveToFile(destination); console.log("PASS: workshop UI", window.width, fake.titlePage, fake.workshopSection); Qt.quit(); });
            } else { console.log("PASS: workshop UI"); Qt.quit(); }
            stop();
        }
    }
}
