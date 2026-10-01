import QtQuick
import QtQuick.Controls

Button {
    id: tab
    required property var state
    required property var barWindow
    property string page: "dashboard"
    signal scrolled(real delta)
    signal secondaryClicked()
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: 40
    implicitWidth: contentItem.implicitWidth + 28
    leftPadding: 14; rightPadding: 14
    Accessible.name: text
    WheelHandler { onWheel: event => { if (event.angleDelta.y !== 0) tab.scrolled(event.angleDelta.y); event.accepted = true; } }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: tab.secondaryClicked() }
    onHoveredChanged: {
        if (hovered) state.drawer.hover(barWindow.screen, page, mapToItem(barWindow.contentItem, width / 2, 0).x);
        else state.drawer.leave();
    }
    onClicked: state.drawer.pin(barWindow.screen, page, mapToItem(barWindow.contentItem, width / 2, 0).x)
    contentItem: VnText { text: tab.text; font.family: Theme.titleFont; font.pixelSize: 14; color: tab.hovered || tab.visualFocus ? Theme.accent : Theme.ink; horizontalAlignment: Text.AlignHCenter }
    background: Item {
        Rectangle {
            anchors.fill: parent; color: Theme.tint
            opacity: tab.hovered || tab.visualFocus ? 0.65 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            width: tab.hovered || tab.visualFocus || (tab.state.drawer.shown && tab.state.drawer.page === tab.page && tab.state.drawer.screen === tab.barWindow.screen) ? parent.width - 24 : 0
            height: tab.visualFocus ? 2 : 1; color: Theme.accent
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }
}
