import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: workshop
    required property var state
    property string section: "packages"
    property var system: ({packages: [], niri: null, hostAvailable: false, hostname: ""})
    property string message: ""
    property bool failed: false
    property string editorTarget: "nixos"
    property string editorPath: ""
    property string editorVersion: ""
    property string savedText: ""
    property var pending: ({})
    readonly property bool busy: backend.running
    spacing: 16
    function request(value) {
        if (busy) return;
        pending = value; failed = false; message = "Working…";
        backend.running = true;
    }
    function edit(name) {
        if (editor.text !== savedText) { failed = true; message = "Save your edits or use Reload before opening another file."; return; }
        editorTarget = name;
        request({operation: "read", target: name});
    }
    function choose(section) { workshop.section = section; state.workshopSection = section; }
    Connections {
        target: workshop.state
        function onWorkshopSectionChanged() {
            workshop.section = workshop.state.workshopSection;
            if (workshop.section === "files" && !workshop.editorVersion && !workshop.busy) workshop.edit("nixos");
        }
    }
    Component.onCompleted: { section = state.workshopSection; request({operation: "status"}); }
    Process {
        id: backend
        command: ["desktop-config"]
        stdinEnabled: true
        onStarted: write(JSON.stringify(workshop.pending) + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    workshop.failed = !result.ok;
                    workshop.message = result.ok ? (result.message || "") : result.error;
                    if (result.status) {
                        workshop.system = result.status;
                        if (result.status.niri) {
                            gaps.value = result.status.niri.gaps;
                            focusWidth.value = result.status.niri.focusWidth;
                            columnWidth.value = result.status.niri.columnWidth;
                        }
                    }
                    if (result.target) {
                        workshop.editorTarget = result.target;
                        workshop.editorPath = result.path;
                        workshop.savedText = result.text;
                        editor.text = result.text;
                    }
                    if (result.version) {
                        workshop.editorVersion = result.version;
                        if (workshop.pending.operation === "save") workshop.savedText = editor.text;
                    }
                    if (result.ok && workshop.pending.operation === "add") packageName.text = "";
                } catch (_) { workshop.failed = true; workshop.message = "Could not read the configuration response. Try again."; }
            }
        }
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) { workshop.failed = true; workshop.message = text.trim().slice(-500); } } }
        onExited: { if (workshop.pending.operation === "status" && workshop.section === "files" && !workshop.editorVersion) Qt.callLater(() => workshop.edit("nixos")); }
    }
    Flow {
        Layout.fillWidth: true; spacing: 8
        VnButton { text: "Packages"; selected: workshop.section === "packages"; enabled: !workshop.busy; onClicked: workshop.choose("packages") }
        VnButton { text: "Niri layout"; selected: workshop.section === "niri"; enabled: !workshop.busy; onClicked: workshop.choose("niri") }
        VnButton { text: "Config files"; selected: workshop.section === "files"; enabled: !workshop.busy; onClicked: { workshop.choose("files"); if (!workshop.editorVersion) workshop.edit("nixos"); } }
    }
    ColumnLayout {
        Layout.fillWidth: true; visible: workshop.section === "packages"; spacing: 12
        VnText { Layout.fillWidth: true; text: "Extra packages for your NixOS configuration. Add a package, then Apply NixOS to install it."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        RowLayout {
            Layout.fillWidth: true
            VnField { id: packageName; Layout.fillWidth: true; placeholderText: "ripgrep or kdePackages.kate"; enabled: !workshop.busy; onAccepted: { if (text.trim()) workshop.request({operation: "add", package: text.trim()}); } }
            VnButton { text: "Add"; enabled: !workshop.busy && packageName.text.trim() !== ""; onClicked: workshop.request({operation: "add", package: packageName.text.trim()}) }
        }
        Repeater {
            model: workshop.system.packages
            RowLayout {
                required property string modelData
                Layout.fillWidth: true
                VnText { Layout.fillWidth: true; text: parent.modelData }
                VnButton { compact: true; text: "Remove"; enabled: !workshop.busy; onClicked: workshop.request({operation: "remove", package: parent.modelData}) }
            }
        }
        VnText { visible: workshop.system.packages.length === 0; text: "No extra packages yet. Your existing packages stay in Home Manager."; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        VnButton { quiet: true; text: "Browse package names"; onClicked: workshop.state.launch(["xdg-open", "https://search.nixos.org/packages"]) }
    }
    ColumnLayout {
        Layout.fillWidth: true; visible: workshop.section === "niri"; spacing: 12
        VnText { Layout.fillWidth: true; text: "Adjust the workspace layout. Save changes, then Apply Niri. Your keybindings and window rules stay in the source template."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        GridLayout {
            Layout.fillWidth: true; columns: 2; columnSpacing: 16; rowSpacing: 12
            VnText { text: "Window gaps (px)" }
            SpinBox { id: gaps; from: 0; to: 64; editable: true; enabled: !workshop.busy && !!workshop.system.niri; palette.button: Theme.paper; palette.buttonText: Theme.ink; palette.text: Theme.ink; palette.base: Theme.paper; palette.highlight: Theme.accent }
            VnText { text: "Focus outline (px)" }
            SpinBox { id: focusWidth; from: 0; to: 12; editable: true; enabled: gaps.enabled; palette.button: Theme.paper; palette.buttonText: Theme.ink; palette.text: Theme.ink; palette.base: Theme.paper; palette.highlight: Theme.accent }
            VnText { text: "Default column width (%)" }
            SpinBox { id: columnWidth; from: 20; to: 100; editable: true; enabled: gaps.enabled; palette.button: Theme.paper; palette.buttonText: Theme.ink; palette.text: Theme.ink; palette.base: Theme.paper; palette.highlight: Theme.accent }
        }
        VnButton { text: "Save layout"; enabled: gaps.enabled; onClicked: workshop.request({operation: "niri-settings", gaps: gaps.value, focusWidth: focusWidth.value, columnWidth: columnWidth.value}) }
        VnText { visible: !workshop.system.niri; Layout.fillWidth: true; text: "Use Config files to edit this custom layout."; color: Theme.muted }
    }
    ColumnLayout {
        Layout.fillWidth: true; visible: workshop.section === "files"; spacing: 12
        Flow {
            Layout.fillWidth: true; spacing: 8
            VnButton { compact: true; text: "NixOS"; selected: workshop.editorTarget === "nixos"; enabled: !workshop.busy; onClicked: workshop.edit("nixos") }
            VnButton { compact: true; text: "Home Manager"; selected: workshop.editorTarget === "home"; enabled: !workshop.busy; onClicked: workshop.edit("home") }
            VnButton { compact: true; text: "Niri"; selected: workshop.editorTarget === "niri"; enabled: !workshop.busy; onClicked: workshop.edit("niri") }
        }
        VnText { Layout.fillWidth: true; text: workshop.editorPath; font.pixelSize: 10; color: Theme.muted }
        ScrollView {
            Layout.fillWidth: true; Layout.preferredHeight: 280; clip: true
            TextArea {
                id: editor
                width: parent.width
                enabled: !workshop.busy
                font.family: "JetBrains Mono"; font.pixelSize: 11
                color: Theme.ink; selectionColor: Theme.accent; selectedTextColor: Theme.paper
                wrapMode: TextEdit.NoWrap
                selectByMouse: true
                padding: 12
                background: Rectangle { color: Theme.paper; border.color: editor.activeFocus ? Theme.accent : Theme.line; border.width: editor.activeFocus ? 2 : 1; radius: Theme.retro ? 0 : 3 }
            }
        }
        RowLayout {
            VnButton { text: "Save & validate"; enabled: !workshop.busy && workshop.editorVersion !== "" && editor.text !== workshop.savedText; onClicked: workshop.request({operation: "save", target: workshop.editorTarget, version: workshop.editorVersion, text: editor.text}) }
            VnButton { text: "Reload"; enabled: !workshop.busy; onClicked: workshop.request({operation: "read", target: workshop.editorTarget}) }
        }
        VnText { Layout.fillWidth: true; text: "Saves a backup and checks syntax. Check NixOS validates the complete system before applying."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    }
    VnText { Layout.fillWidth: true; visible: workshop.message !== ""; text: workshop.message; color: workshop.failed ? Theme.accent : Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
    Flow {
        Layout.fillWidth: true; spacing: 8
        VnButton { text: "Apply Niri"; enabled: !workshop.busy; onClicked: Quickshell.execDetached(["desktop-config", "apply-niri"]) }
        VnButton { text: "Check NixOS"; enabled: !workshop.busy && workshop.system.hostAvailable; onClicked: workshop.state.openTitleTerminal(["desktop-config", "check"]) }
        VnButton { text: "Apply NixOS"; enabled: !workshop.busy && workshop.system.hostAvailable; onClicked: workshop.state.openTitleTerminal(["desktop-config", "rebuild"]) }
    }
    VnText { Layout.fillWidth: true; text: workshop.system.hostAvailable ? "NixOS changes apply to " + workshop.system.hostname + ". The terminal shows progress and asks for your password." : "This computer has no matching host configuration in hosts/."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    VnText { Layout.fillWidth: true; visible: workshop.state.error !== ""; text: workshop.state.error; color: Theme.accent; wrapMode: Text.WordWrap; elide: Text.ElideNone }
}
