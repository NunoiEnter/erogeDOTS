import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: calendar
    required property var state
    property date month: new Date()
    visible: state.calendarShown
    screen: state.calendarScreen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "eroge-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: if (visible) { month = new Date(); Qt.callLater(() => todayButton.forceActiveFocus()); }
    function shiftMonth(delta) { month = new Date(month.getFullYear(), month.getMonth() + delta, 1); }
    function dayAt(index) {
        const first = new Date(month.getFullYear(), month.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        return new Date(month.getFullYear(), month.getMonth(), index - offset + 1);
    }
    MouseArea { anchors.fill: parent; onClicked: calendar.state.calendarShown = false }
    Item {
        anchors.fill: parent
        Keys.onEscapePressed: calendar.state.calendarShown = false
        VnFrame {
            anchors.right: parent.right; anchors.top: parent.top
            anchors.rightMargin: 16; anchors.topMargin: 62
            width: Math.min(344, calendar.width - 32)
            height: 342
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    VnButton { compact: true; text: "Prev"; hint: "Previous month"; onClicked: calendar.shiftMonth(-1) }
                    VnText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDateTime(calendar.month, "MMMM yyyy"); font.family: Theme.titleFont; font.bold: true }
                    VnButton { compact: true; text: "Next"; hint: "Next month"; onClicked: calendar.shiftMonth(1) }
                }
                GridLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    columns: 7; rowSpacing: 4; columnSpacing: 4
                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        VnText {
                            required property string modelData
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData; color: Theme.muted
                        }
                    }
                    Repeater {
                        model: 42
                        Rectangle {
                            required property int index
                            readonly property date day: calendar.dayAt(index)
                            readonly property bool today: Qt.formatDateTime(day, "yyyy-MM-dd") === Qt.formatDateTime(new Date(), "yyyy-MM-dd")
                            Layout.fillWidth: true; Layout.fillHeight: true
                            color: today ? Theme.accent : "transparent"
                            radius: Theme.retro ? 0 : 3
                            VnText {
                                anchors.fill: parent; horizontalAlignment: Text.AlignHCenter
                                text: parent.day.getDate()
                                color: parent.today ? Theme.paper : Theme.ink
                                opacity: parent.day.getMonth() === calendar.month.getMonth() ? 1 : 0.45
                                font.bold: parent.today
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    VnButton { id: todayButton; compact: true; text: "Today"; onClicked: calendar.month = new Date() }
                    Item { Layout.fillWidth: true }
                    VnButton { compact: true; text: "Close"; onClicked: calendar.state.calendarShown = false }
                }
            }
        }
    }
}
