import QtQuick
import Quickshell

Scope {
    id: drawer
    property bool allowed: true
    property bool shown: false
    property bool pinned: false
    property string page: "dashboard"
    property var screen: null
    property real center: 0
    property string pendingPage: ""
    property var pendingScreen: null
    property real pendingCenter: 0
    function hover(screen, page, center) {
        if (!allowed || pinned) return;
        closeDelay.stop();
        pendingScreen = screen; pendingPage = page; pendingCenter = center;
        if (shown && drawer.screen === screen) commit();
        else openDelay.restart();
    }
    function commit() {
        if (!allowed) return;
        drawer.screen = pendingScreen; page = pendingPage; center = pendingCenter; shown = true;
    }
    function hold() { closeDelay.stop(); }
    function leave() { openDelay.stop(); if (!pinned) closeDelay.restart(); }
    function pin(screen, page, center) {
        if (!allowed) return;
        if (shown && pinned && drawer.screen === screen && drawer.page === page) { close(); return; }
        openDelay.stop(); closeDelay.stop();
        drawer.screen = screen; drawer.page = page; drawer.center = center;
        pinned = true; shown = true;
    }
    function close() { openDelay.stop(); closeDelay.stop(); shown = false; pinned = false; }
    onAllowedChanged: if (!allowed) close()
    Timer { id: openDelay; interval: 160; onTriggered: drawer.commit() }
    Timer { id: closeDelay; interval: 320; onTriggered: drawer.close() }
}
