import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state
    property var workspaces: []
    property var windows: ({})
    property var focusedId: null
    readonly property string title: windows[focusedId]?.title || "Desktop"
    readonly property string output: workspaces.find(w => w.is_focused)?.output || ""

    // niri sends the initial snapshot followed by changes on this one connection.
    function receive(line) {
        let event;
        try { event = JSON.parse(line); } catch (_) { return; }
        if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces.sort((a, b) => a.idx - b.idx);
        } else if (event.WorkspaceActivated) {
            const e = event.WorkspaceActivated;
            const output = workspaces.find(w => w.id === e.id)?.output;
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === output ? w.id === e.id : w.is_active,
                is_focused: e.focused ? w.id === e.id : w.is_focused
            }));
        } else if (event.WorkspaceUrgencyChanged) {
            const e = event.WorkspaceUrgencyChanged;
            workspaces = workspaces.map(w => w.id === e.id ? Object.assign({}, w, { is_urgent: e.urgent }) : w);
        } else if (event.WindowsChanged) {
            const next = {};
            focusedId = null;
            for (const w of event.WindowsChanged.windows) {
                next[w.id] = w;
                if (w.is_focused) focusedId = w.id;
            }
            windows = next;
        } else if (event.WindowOpenedOrChanged) {
            const w = event.WindowOpenedOrChanged.window;
            windows = Object.assign({}, windows, { [w.id]: w });
            if (w.is_focused) focusedId = w.id;
        } else if (event.WindowFocusChanged) {
            focusedId = event.WindowFocusChanged.id;
        } else if (event.WindowClosed) {
            const next = Object.assign({}, windows);
            delete next[event.WindowClosed.id];
            windows = next;
        }
    }
    Process {
        id: events
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser { onRead: data => state.receive(data) }
        onExited: {
            state.workspaces = [];
            state.windows = ({});
            reconnect.restart();
        }
    }
    Timer { id: reconnect; interval: 2000; onTriggered: events.running = true }
}
