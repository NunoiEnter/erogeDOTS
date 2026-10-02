import QtQuick
import QtTest

Item {
    id: fixture
    width: 620; height: 680
    property bool keyboardBoundary: true
    QtObject {
        id: niri
        property var windows: ({})
        property var focusedId: 10
    }
    QtObject {
        id: state
        property var niri: fixture.niriObject
        property var chosen: null
        function focusWorkspace(id) { chosen = ["workspace", id]; }
        function focusWindow(id) { chosen = ["window", id]; }
        function launch(command) { chosen = command; }
    }
    property var niriObject: niri
    WorkspaceFlowchart { id: graph; width: fixture.width; state: state; chapters: [] }
    TestCase {
        name: "WorkspaceFlowchart"
        when: windowShown
        function init() {
            fixture.width = 620;
            state.chosen = null;
            niri.windows = ({10: {id: 10, workspace_id: 1, app_id: "firefox", title: "A very long window title"}, 11: {id: 11, workspace_id: 1, app_id: "kitty", title: "Terminal"}, 12: {id: 12, workspace_id: 9, app_id: "other display"}});
            graph.chapters = [{id: 1, idx: 1, name: "Daily", is_active: true}, {id: 2, idx: 2, name: null, is_active: false}];
            tryVerify(() => findChild(graph, "window-10") !== null);
        }
        function test_real_routes_and_other_display_filter() {
            verify(findChild(graph, "window-12") === null);
            const chapter = findChild(graph, "chapter-1");
            verify(chapter.selected);
            chapter.forceActiveFocus(); keyClick(Qt.Key_Return);
            compare(state.chosen, ["workspace", 1]);
            const leaf = findChild(graph, "window-10");
            verify(leaf.selected);
            leaf.forceActiveFocus(); keyClick(Qt.Key_Enter);
            compare(state.chosen, ["window", 10]);
        }
        function test_keyboard_moves_along_branches() {
            findChild(graph, "chapter-1").forceActiveFocus();
            keyClick(Qt.Key_Tab); verify(findChild(graph, "window-10").activeFocus);
            keyClick(Qt.Key_Down); verify(findChild(graph, "window-11").activeFocus);
            keyClick(Qt.Key_Down); verify(findChild(graph, "chapter-2").activeFocus);
        }
        function test_window_changes_update_graph() {
            niri.windows = ({13: {id: 13, workspace_id: 2, app_id: "editor", title: "Notes"}});
            tryVerify(() => findChild(graph, "window-13") !== null);
            verify(findChild(graph, "window-10") === null);
        }
        function test_small_width_keeps_nodes_inside() {
            fixture.width = 290;
            wait(50);
            const leaf = findChild(graph, "window-10");
            verify(leaf.width > 100);
            verify(leaf.x + leaf.width <= graph.width);
        }
        function test_empty_display() {
            graph.chapters = [];
            tryVerify(() => findChild(graph, "chapter-1") === null);
            verify(graph.implicitHeight > 0);
        }
    }
}
