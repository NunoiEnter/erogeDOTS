import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: studio
    required property var state
    property var catalog: ({palettes: [], roles: [], colors: []})
    property int palette: 0
    property var colors: []
    property bool advanced: false
    property string wallpaper: ""
    property string createdId: ""
    property string message: ""
    property bool failed: false
    property var pending: ({operation: "catalog"})
    readonly property bool busy: backend.running
    readonly property bool wallpaperReady: wallpaperPreview.status === Image.Ready
    spacing: 12
    function request(value) { if (busy) return; pending = value; failed = false; message = "Working…"; backend.running = true; }
    function choose(index) { palette = index; colors = catalog.colors[index].slice(); }
    Component.onCompleted: backend.running = true
    Process {
        id: backend; command: ["theme-picker", "theme-json"]; stdinEnabled: true
        onStarted: write(JSON.stringify(studio.pending) + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text); studio.failed = !result.ok;
                    studio.message = result.ok ? (result.message || "") : result.error;
                    if (result.palettes) { studio.catalog = result; studio.choose(0); }
                    if (result.id) studio.createdId = result.id;
                } catch (_) { studio.failed = true; studio.message = "Could not read the theme tool response. Reopen this page to try again."; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) { studio.failed = true; studio.message = text.trim().slice(-500); } }
    }
    FileDialog {
        id: file; title: "Choose your character wallpaper"; nameFilters: ["Wallpapers (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: { studio.wallpaper = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")); imagePath.text = studio.wallpaper; }
    }
    VnText { Layout.fillWidth: true; text: "Add your character, choose a wallpaper and make a palette. You can preview everything before saving."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    VnText { text: "Character"; font.family: Theme.titleFont; font.pixelSize: 18 }
    VnText { text: "Theme ID" }
    VnField { id: slug; Layout.fillWidth: true; placeholderText: "my-character · lowercase letters, numbers, hyphens"; enabled: !studio.busy && !studio.createdId }
    VnText { text: "Character name" }
    VnField { id: name; Layout.fillWidth: true; placeholderText: "Full name"; enabled: slug.enabled }
    VnText { text: "Display name (optional)" }
    VnField { id: displayName; Layout.fillWidth: true; placeholderText: "Japanese, Thai or another display name"; enabled: slug.enabled }
    VnText { text: "Game or source (optional)" }
    VnField { id: game; Layout.fillWidth: true; placeholderText: "Where your character is from"; enabled: slug.enabled }
    VnText { text: "Wallpaper"; font.family: Theme.titleFont; font.pixelSize: 18; Layout.topMargin: 12 }
    RowLayout {
        Layout.fillWidth: true
        VnField { id: imagePath; Layout.fillWidth: true; placeholderText: "Full image path or ~/Pictures/character.png"; enabled: slug.enabled; onTextChanged: studio.wallpaper = text }
        VnButton { text: "Browse…"; enabled: slug.enabled; onClicked: file.open() }
    }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 170; color: studio.catalog.palettes.length ? studio.catalog.palettes[studio.palette].background : Theme.tint; radius: Theme.retro ? 0 : 3; clip: true
        Image { id: wallpaperPreview; anchors.fill: parent; source: studio.wallpaper ? "file://" + (studio.wallpaper.startsWith("~/") ? Quickshell.env("HOME") + studio.wallpaper.slice(1) : studio.wallpaper) : ""; sourceSize.width: 1000; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        VnText { anchors.centerIn: parent; visible: studio.wallpaper !== "" && wallpaperPreview.status === Image.Error; text: "Image unavailable · choose another file"; color: Theme.ink }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 52; color: Theme.translucent(Theme.paper, 0.95) }
        Column {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 10; spacing: 4
            VnText { width: parent.width; text: name.text || "Your character preview"; font.family: Theme.titleFont; font.pixelSize: 16; color: Theme.accent }
            VnText { width: parent.width; text: game.text || "Choose an image to see the wallpaper here"; color: Theme.muted }
        }
    }
    VnText { text: "Palette"; font.family: Theme.titleFont; font.pixelSize: 18; Layout.topMargin: 12 }
    Flow {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: studio.catalog.palettes
            VnButton { required property var modelData; required property int index; text: modelData.name; selected: studio.palette === index; enabled: slug.enabled; onClicked: studio.choose(index) }
        }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 4
        Repeater { model: studio.colors; Rectangle { required property string modelData; Layout.fillWidth: true; height: 22; color: modelData; border.color: Theme.line; border.width: 1 } }
    }
    VnButton { quiet: true; text: studio.advanced ? "Hide individual colors" : "Edit individual colors"; enabled: slug.enabled; onClicked: studio.advanced = !studio.advanced }
    ColumnLayout {
        Layout.fillWidth: true; visible: studio.advanced
        Repeater {
            model: studio.catalog.roles
            RowLayout {
                required property var modelData; required property int index
                Layout.fillWidth: true
                Rectangle { width: 20; height: 20; color: studio.colors[parent.index] || Theme.paper; border.color: Theme.line }
                VnText { Layout.fillWidth: true; text: parent.modelData.label }
                VnField { Layout.preferredWidth: 110; text: studio.colors[parent.index] || ""; enabled: slug.enabled; onTextEdited: { let copy = studio.colors.slice(); copy[parent.index] = text; studio.colors = copy; } }
            }
        }
    }
    VnText { Layout.fillWidth: true; visible: studio.message !== ""; text: studio.message; color: studio.failed ? Theme.accent : Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    VnButton {
        text: studio.busy ? "Creating…" : "Create theme"; visible: !studio.createdId
        enabled: !studio.busy && /^[a-z0-9][a-z0-9-]*$/.test(slug.text) && name.text.trim() !== "" && studio.wallpaper !== "" && studio.colors.length > 0
        onClicked: studio.request({operation: "create", id: slug.text, name: name.text.trim(), displayName: displayName.text.trim() || name.text.trim(), game: game.text.trim(), wallpaper: studio.wallpaper, palette: studio.palette, colors: studio.colors})
    }
    VnButton { text: "Apply theme"; visible: studio.createdId !== ""; enabled: !studio.state.themeBusy; onClicked: { studio.state.themeBusy = true; Quickshell.execDetached(["theme-switch", studio.createdId, "--show-menu"]); } }
}
