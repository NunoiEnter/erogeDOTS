import QtQuick
import QtQuick.Layouts

// Real workspace spine; each open window is a branch, not a fictional story route.
ColumnLayout {
    id: graph
    required property var state
    required property var chapters
    spacing: 0
    function windowsFor(id) { return Object.values(state.niri.windows).filter(window => window.workspace_id === id); }
    VnText {
        Layout.fillWidth: true; Layout.bottomMargin: 18
        text: "Chapters connect down the spine. Choose a branch to return to its window."
        color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone
    }
    Repeater {
        model: graph.chapters
        Item {
            id: route
            required property var modelData
            required property int index
            readonly property var windows: graph.windowsFor(modelData.id)
            readonly property real nodeWidth: Math.min(180, width * 0.42)
            readonly property real branchX: nodeWidth + 28
            readonly property real firstY: 38
            Layout.fillWidth: true
            implicitHeight: Math.max(76, windows.length * 76) + 28
            Canvas {
                id: paths
                anchors.fill: parent
                property color stroke: Theme.line
                property int count: route.windows.length
                onStrokeChanged: requestPaint()
                onCountChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"); ctx.reset();
                    ctx.strokeStyle = stroke; ctx.fillStyle = stroke; ctx.lineWidth = 1.5;
                    const spine = route.nodeWidth / 2;
                    function line(x1, y1, x2, y2) { ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); }
                    function arrow(x, y, down) {
                        ctx.moveTo(x, y);
                        ctx.lineTo(x - 4, y - (down ? 5 : 4));
                        ctx.moveTo(x, y);
                        ctx.lineTo(x + (down ? 4 : -4), y + (down ? -5 : 4));
                    }
                    ctx.beginPath();
                    if (route.index > 0) line(spine, 0, spine, 8);
                    if (route.index < graph.chapters.length - 1) {
                        line(spine, 68, spine, height); arrow(spine, height - 4, true);
                    }
                    const junction = route.nodeWidth + 14;
                    line(route.nodeWidth, route.firstY, junction, route.firstY);
                    line(junction, route.firstY, junction, route.firstY + Math.max(0, count - 1) * 76);
                    for (let i = 0; i < Math.max(1, count); i++) {
                        const y = route.firstY + i * 76;
                        line(junction, y, route.branchX - 4, y); arrow(route.branchX - 4, y, false);
                    }
                    ctx.stroke();
                }
            }
            VnButton {
                id: chapter
                objectName: "chapter-" + route.modelData.id
                x: 0; y: 8; width: route.nodeWidth; height: 60
                selected: route.modelData.is_active
                text: "Chapter " + route.modelData.idx.toString().padStart(2, "0")
                hint: route.modelData.name || text
                contentItem: Column {
                    spacing: 3
                    VnText { width: parent.width; text: chapter.text; font.family: Theme.titleFont; font.pixelSize: 16; font.bold: true; color: chapter.selected ? Theme.paper : Theme.ink }
                    VnText { width: parent.width; text: route.modelData.name || (route.modelData.is_active ? "Current chapter" : "Workspace"); font.pixelSize: 10; color: chapter.selected ? Theme.paper : Theme.muted }
                }
                onClicked: graph.state.focusWorkspace(route.modelData.idx)
            }
            Repeater {
                model: route.windows
                VnButton {
                    id: leaf
                    required property var modelData
                    required property int index
                    objectName: "window-" + modelData.id
                    x: route.branchX; y: 8 + index * 76
                    width: Math.max(1, route.width - x); height: 60
                    selected: graph.state.niri.focusedId === modelData.id
                    text: modelData.title || modelData.app_id || "Untitled window"
                    hint: text
                    contentItem: Column {
                        spacing: 3
                        VnText { width: parent.width; text: leaf.modelData.app_id || "Window"; font.pixelSize: 10; color: leaf.selected ? Theme.paper : Theme.muted }
                        VnText { width: parent.width; text: leaf.text; font.pixelSize: 12; color: leaf.selected ? Theme.paper : Theme.ink }
                    }
                    onClicked: graph.state.focusWindow(modelData.id)
                }
            }
            VnText {
                visible: route.windows.length === 0
                x: route.branchX; y: 28; width: Math.max(1, route.width - x)
                text: "An empty chapter"; color: Theme.muted; font.italic: true
            }
        }
    }
    VnText { visible: graph.chapters.length === 0; text: "No chapters on this display yet."; color: Theme.muted }
    VnButton { Layout.topMargin: 8; text: "Open workspace overview"; onClicked: graph.state.launch(["niri", "msg", "action", "toggle-overview"]) }
}
