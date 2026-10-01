import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: tray
    required property var barWindow
    spacing: 3
    Repeater {
        model: SystemTray.items
        VnButton {
            id: entry
            required property var modelData
            compact: true
            quiet: true
            implicitWidth: 30
            text: modelData.title || modelData.id
            hint: modelData.tooltipTitle || text
            contentItem: Image {
                source: entry.modelData.icon
                sourceSize: Qt.size(20, 20)
                fillMode: Image.PreserveAspectFit
            }
            function showMenu() {
                if (!modelData.hasMenu) return;
                const point = mapToItem(tray.barWindow.contentItem, 0, height);
                modelData.display(tray.barWindow, point.x, point.y);
            }
            onClicked: modelData.onlyMenu ? showMenu() : modelData.activate()
            onSecondaryClicked: showMenu()
            onScrolled: delta => modelData.scroll(delta, false)
        }
    }
}
