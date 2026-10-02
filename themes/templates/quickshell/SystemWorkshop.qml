import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Keyboard.js" as Keyboard

ColumnLayout {
    id: workshop
    required property var state
    property string section: "packages"
    property var system: ({packages: [], niri: null, hostAvailable: false, hostname: ""})
    property var results: []
    property int resultCount: 0
    property bool searched: false
    property string resultQuery: ""
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
        pending = value; failed = false; message = value.operation === "search" ? "Searching locked Nixpkgs… First search may take a moment." : "Working…";
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
                    if (result.results) { workshop.results = result.results; workshop.resultCount = result.total; workshop.searched = true; workshop.resultQuery = workshop.pending.query; }
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
        VnButton { text: "Advanced files"; selected: workshop.section === "files"; enabled: !workshop.busy; onClicked: { workshop.choose("files"); if (!workshop.editorVersion) workshop.edit("nixos"); } }
    }
    ColumnLayout {
        Layout.fillWidth: true; visible: workshop.section === "packages"; spacing: 12
        RowLayout {
            Layout.fillWidth: true; spacing: 12
            Image { Layout.preferredWidth: 38; Layout.preferredHeight: 38; source: Qt.resolvedUrl("NixLogo.svg"); fillMode: Image.PreserveAspectFit }
            ColumnLayout {
                Layout.fillWidth: true
                VnText { Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone; text: "Find software in Nixpkgs"; font.family: Theme.titleFont; font.pixelSize: 18 }
                VnText { Layout.fillWidth: true; text: "Search apps and tools, add them to your list, then install with Apply NixOS."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            VnField { id: packageName; Layout.fillWidth: true; placeholderText: "Firefox, music player, ripgrep…"; enabled: !workshop.busy; onAccepted: { if (text.trim().length >= 2) workshop.request({operation: "search", query: text.trim()}); } }
            VnButton { text: "Search"; enabled: !workshop.busy && packageName.text.trim().length >= 2; onClicked: workshop.request({operation: "search", query: packageName.text.trim()}) }
        }
        VnText { Layout.fillWidth: true; text: "Source: your locked Nixpkgs" + (workshop.system.revision ? " · " + workshop.system.revision.slice(0, 12) : ""); color: Theme.muted; font.pixelSize: 10 }
        VnText { visible: workshop.searched; Layout.fillWidth: true; text: workshop.resultCount === 0 ? "No results for “" + workshop.resultQuery + "”. Try an app name or a shorter description." : workshop.resultCount + " matches for “" + workshop.resultQuery + "”" + (workshop.resultCount > 60 ? " · showing the first 60; narrow your search for more" : ""); color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        ScrollView {
            id: resultScroll
            Layout.fillWidth: true; Layout.preferredHeight: Math.min(360, resultList.implicitHeight)
            visible: workshop.results.length > 0; clip: true
            ColumnLayout {
                id: resultList; width: resultScroll.availableWidth; spacing: 12
                Repeater {
            model: workshop.results
            ColumnLayout {
                id: packageResult
                required property var modelData
                Layout.fillWidth: true; spacing: 8
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Image {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; fillMode: Image.PreserveAspectFit
                        source: packageResult.modelData.icon ? (packageResult.modelData.icon.startsWith("/") ? "file://" + packageResult.modelData.icon : (Quickshell.iconPath(packageResult.modelData.icon, true) || Qt.resolvedUrl("NixLogo.svg"))) : Qt.resolvedUrl("NixLogo.svg")
                        onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("NixLogo.svg")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        VnText { Layout.fillWidth: true; text: packageResult.modelData.name + "  " + (packageResult.modelData.version || ""); font.bold: true }
                        VnText { Layout.fillWidth: true; text: packageResult.modelData.attribute; color: Theme.muted; font.pixelSize: 10 }
                        VnText { Layout.fillWidth: true; text: packageResult.modelData.description || "No description supplied by Nixpkgs."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
                    }
                    VnButton { compact: true; text: workshop.system.packages.includes(packageResult.modelData.attribute) ? "Added" : "Add"; enabled: !workshop.busy && !workshop.system.packages.includes(packageResult.modelData.attribute); onClicked: workshop.request({operation: "add", package: packageResult.modelData.attribute}) }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
            }
        }

            }
        }
        VnText { text: "Your extra packages"; font.family: Theme.titleFont; font.pixelSize: 18; Layout.topMargin: 12 }
        Repeater {
            model: workshop.system.packages
            RowLayout {
                required property string modelData
                Layout.fillWidth: true
                VnText { Layout.fillWidth: true; text: parent.modelData }
                VnButton { compact: true; text: "Remove"; enabled: !workshop.busy; onClicked: workshop.request({operation: "remove", package: parent.modelData}) }
            }
        }
        VnText { visible: workshop.system.packages.length === 0; text: "Search above to add your first package. Existing Home Manager packages are managed in Advanced files."; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        VnButton { quiet: true; text: "Add exact package name"; enabled: !workshop.busy && /^[A-Za-z_][A-Za-z0-9_-]*(\.[A-Za-z_][A-Za-z0-9_-]*)*$/.test(packageName.text.trim()); onClicked: workshop.request({operation: "add", package: packageName.text.trim()}) }
    }

    ColumnLayout {
        Layout.fillWidth: true; visible: workshop.section === "niri"; spacing: 12
        VnText { Layout.fillWidth: true; text: "Preview the spacing and default window size below. Save layout, then Apply Niri to update your desktop."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 140; color: Theme.tint; radius: Theme.retro ? 0 : 3; clip: true
            Row {
                anchors.fill: parent; anchors.margins: 10 + gaps.value / 2; spacing: gaps.value / 2
                Rectangle { width: Math.max(20, (parent.width - parent.spacing) * columnWidth.value / 100); height: parent.height; color: Theme.paper; border.color: Theme.accent; border.width: focusWidth.value; radius: Theme.retro ? 0 : 3
                    VnText { anchors.centerIn: parent; text: columnWidth.value + "%"; color: Theme.accent; font.pixelSize: 18 }
                }
                Rectangle { width: Math.max(20, (parent.width - parent.spacing) * (1 - columnWidth.value / 100)); height: parent.height; color: Theme.paper; border.color: Theme.line; radius: Theme.retro ? 0 : 3 }
            }
        }
        VnText { Layout.fillWidth: true; text: "Layout preview · focused window on the left"; color: Theme.muted; font.pixelSize: 10 }
        GridLayout {
            Layout.fillWidth: true; columns: width < 410 ? 1 : 2; columnSpacing: 16; rowSpacing: 12
            VnText { text: "Space between windows (px)" }
            VnSpinBox { id: gaps; from: 0; to: 64; enabled: !workshop.busy && !!workshop.system.niri }
            VnText { text: "Focused window outline (px)" }
            VnSpinBox { id: focusWidth; from: 0; to: 12; enabled: gaps.enabled }
            VnText { text: "New window width (%)" }
            VnSpinBox { id: columnWidth; from: 20; to: 100; enabled: gaps.enabled }
        }
        VnButton { text: "Save layout"; enabled: gaps.enabled; onClicked: workshop.request({operation: "niri-settings", gaps: gaps.value, focusWidth: focusWidth.value, columnWidth: columnWidth.value}) }
        VnText { visible: !workshop.system.niri; Layout.fillWidth: true; text: "Use Advanced files to edit this custom layout."; color: Theme.muted }
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
                Keys.onTabPressed: event => {
                    if (event.modifiers & Qt.ControlModifier) insert(cursorPosition, "\t");
                    else Keyboard.move(editor, !(event.modifiers & Qt.ShiftModifier));
                    event.accepted = true;
                }
                Keys.onBacktabPressed: event => { Keyboard.move(editor, false); event.accepted = true; }
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
    VnText { Layout.fillWidth: true; text: workshop.section === "niri" ? "Saved layout → Apply Niri" : "Saved packages or files → Check NixOS → Apply NixOS"; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    Flow {
        Layout.fillWidth: true; spacing: 8
        VnButton { text: "Apply Niri"; enabled: !workshop.busy; onClicked: Quickshell.execDetached(["desktop-config", "apply-niri"]) }
        VnButton { text: "Check NixOS"; enabled: !workshop.busy && workshop.system.hostAvailable; onClicked: workshop.state.openTitleTerminal(["desktop-config", "check"]) }
        VnButton { text: "Apply NixOS"; enabled: !workshop.busy && workshop.system.hostAvailable; onClicked: workshop.state.openTitleTerminal(["desktop-config", "rebuild"]) }
    }
    VnText { Layout.fillWidth: true; text: workshop.system.hostAvailable ? "NixOS changes apply to " + workshop.system.hostname + ". The terminal shows progress and asks for your password." : "This computer has no matching host configuration in hosts/."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    VnText { Layout.fillWidth: true; visible: workshop.state.error !== ""; text: workshop.state.error; color: Theme.accent; wrapMode: Text.WordWrap; elide: Text.ElideNone }
}
