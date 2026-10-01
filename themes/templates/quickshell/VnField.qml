import QtQuick
import QtQuick.Controls

TextField {
    color: Theme.ink
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.paper
    font.family: Theme.bodyFont
    font.pixelSize: 12
    padding: 10
    background: Rectangle { color: Theme.paper; border.color: parent.activeFocus ? Theme.accent : Theme.line; border.width: parent.activeFocus ? 2 : 1; radius: Theme.retro ? 0 : 3 }
}
