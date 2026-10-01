import QtQuick
import QtQuick.Layouts

Rectangle {
    id: ribbon
    required property var state
    required property var barWindow
    color: Theme.paper
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 16
        spacing: 10
        RibbonTab {
            state: ribbon.state; barWindow: ribbon.barWindow
            text: "eroge＊DOTS"
            contentItem: VnText { text: "eroge＊DOTS"; font.family: Theme.titleFont; font.pixelSize: ribbon.width > 960 ? 21 : 16; font.bold: true; color: Theme.accent }
            onClicked: ribbon.state.toggle(ribbon.barWindow.screen)
        }
        Item { Layout.fillWidth: true }
        RibbonTab { state: ribbon.state; barWindow: ribbon.barWindow; text: ribbon.width > 960 ? "Dashboard" : "Home"; page: "dashboard" }
        RibbonTab { state: ribbon.state; barWindow: ribbon.barWindow; text: ribbon.width > 960 ? "Music Room" : "Music"; page: "music" }
        RibbonTab { state: ribbon.state; barWindow: ribbon.barWindow; text: "Chapters"; page: "workspaces"; onScrolled: delta => ribbon.state.scrollWorkspace(ribbon.barWindow.screen, delta) }
        RibbonTab { state: ribbon.state; barWindow: ribbon.barWindow; text: ribbon.width > 960 ? "Characters" : "Cast"; page: "characters" }
        Item { Layout.fillWidth: true }
        TrayItems { barWindow: ribbon.barWindow; visible: ribbon.width > 1180 }
        RibbonTab {
            state: ribbon.state; barWindow: ribbon.barWindow; page: "connections"
            text: "Sound " + Math.round(ribbon.state.volume * 100) + "%"
            visible: ribbon.width > 1120
            onScrolled: delta => ribbon.state.setVolume(ribbon.state.volume + (delta > 0 ? 0.05 : -0.05))
            onSecondaryClicked: ribbon.state.toggleMute()
        }
        VnButton {
            compact: true; quiet: true
            text: ribbon.state.dnd ? "DND" : "Log " + ribbon.state.notificationCount
            hint: "Notification log · Right-click for Do Not Disturb"
            onClicked: ribbon.state.launch(["swaync-client", "-t", "-sw"])
            onSecondaryClicked: ribbon.state.launch(["swaync-client", "--toggle-dnd"])
        }
        RibbonTab {
            state: ribbon.state; barWindow: ribbon.barWindow; page: "dashboard"
            text: ribbon.state.timeText
            onClicked: ribbon.state.toggleCalendar(ribbon.barWindow.screen)
        }
    }
}
