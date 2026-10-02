import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: appearance
    required property var state
    spacing: 10
    VnText { text: "Appearance"; font.family: Theme.titleFont; font.pixelSize: 18; color: Theme.accent }
    VnText { Layout.fillWidth: true; text: "Choose panel brightness and the preference sent to your apps separately."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    Flow {
        Layout.fillWidth: true; spacing: 8
        VnText { height: 38; verticalAlignment: Text.AlignVCenter; text: "VN panels  "; width: 110 }
        VnButton { text: "Light"; selected: Theme.appearance === "light"; enabled: !appearance.state.themeBusy && !Theme.retro; onClicked: appearance.state.setAppearance("appearance", "light") }
        VnButton { text: "Dark"; selected: Theme.appearance === "dark"; enabled: !appearance.state.themeBusy && !Theme.retro; onClicked: appearance.state.setAppearance("appearance", "dark") }
    }
    Flow {
        Layout.fillWidth: true; spacing: 8
        VnText { height: 38; verticalAlignment: Text.AlignVCenter; text: "System apps  "; width: 110 }
        VnButton { text: "Light"; selected: Theme.systemAppearance === "light"; enabled: !appearance.state.themeBusy; onClicked: appearance.state.setAppearance("system", "light") }
        VnButton { text: "Dark"; selected: Theme.systemAppearance === "dark"; enabled: !appearance.state.themeBusy; onClicked: appearance.state.setAppearance("system", "dark") }
    }
    VnText { visible: Theme.retro; Layout.fillWidth: true; text: "Windows 98 uses its classic grey panels. Your VN preference is kept for when you return."; color: Theme.muted; wrapMode: Text.WordWrap; elide: Text.ElideNone }
}
