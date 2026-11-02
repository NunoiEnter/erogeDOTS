import QtQuick

// One shortcut line: the key combination in accent stationery, then its title.
// The row resolves its own entry from the guide by slot number instead of
// taking delegate model data, which Quickshell's Repeater does not inject for
// plain JS array models.
Item {
    id: row
    property var owner: null
    property int slot: -1
    readonly property var entry: {
        if (!owner) return null;
        const list = owner.shownBinds;
        return list && slot >= 0 && slot < list.length ? list[slot] : null;
    }
    readonly property real keyWidth: Math.max(78, keyText.implicitWidth + 18)
    implicitHeight: 26
    HoverHandler { id: hover }
    Rectangle {
        id: keycap
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: row.keyWidth
        height: 20
        color: hover.hovered ? Theme.tint : Theme.translucent(Theme.tint, 0.55)
        border.color: hover.hovered ? Theme.accent : Theme.line
        border.width: 1
        radius: Theme.retro ? 0 : 3
        VnText {
            id: keyText
            anchors.centerIn: parent
            text: row.entry ? row.entry.keys : ""
            font.family: Theme.titleFont
            font.pixelSize: 12
            font.bold: true
            color: hover.hovered ? Theme.accent : Theme.ink
        }
    }
    VnText {
        anchors.left: keycap.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: row.entry ? row.entry.title : ""
        color: hover.hovered ? Theme.ink : Theme.muted
        font.pixelSize: 12
    }
}