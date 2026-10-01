import QtQuick
import Quickshell

ShellRoot {
    NiriState { id: state }
    function expect(condition, message) { if (!condition) throw new Error(message); }
    function send(event) { state.receive(JSON.stringify(event)); }
    Component.onCompleted: {
        send({ WorkspacesChanged: { workspaces: [
            { id: 2, idx: 2, output: "A", is_active: false, is_focused: false },
            { id: 1, idx: 1, output: "A", is_active: true, is_focused: true },
            { id: 3, idx: 3, output: "B", is_active: true, is_focused: false }
        ] } });
        expect(state.workspaces[0].id === 1, "Sort workspace snapshot");
        send({ WorkspaceActivated: { id: 2, focused: true } });
        expect(!state.workspaces[0].is_active && state.workspaces[1].is_focused, "Switch active workspace");
        expect(state.workspaces[2].is_active, "Preserve other output's active workspace");
        expect(state.output === "A", "Identify focused output");
        send({ WindowsChanged: { windows: [{ id: 10, title: "Editor", is_focused: true }] } });
        expect(state.title === "Editor", "Initial title");
        send({ WindowOpenedOrChanged: { window: { id: 10, title: "Changed", is_focused: true } } });
        expect(state.title === "Changed", "Update existing title");
        send({ WindowOpenedOrChanged: { window: { id: 11, title: "Other", is_focused: false } } });
        send({ WindowFocusChanged: { id: 11 } });
        expect(state.title === "Other", "Focus another window");
        send({ WindowClosed: { id: 11 } });
        expect(state.title === "Desktop", "Handle closed window");
        send({ WindowFocusChanged: { id: null } });
        state.receive("not JSON");
        expect(state.title === "Desktop", "Ignore malformed input");
        console.log("PASS: niri event state");
    }
    Timer { running: true; interval: 1; onTriggered: Qt.quit() }
}
