import QtQuick
import QtQuick.Controls
import "Keyboard.js" as Keyboard

SpinBox {
    id: control
    editable: true
    font.family: Theme.bodyFont
    font.pixelSize: 12
    palette.button: Theme.paper
    palette.buttonText: Theme.ink
    palette.text: Theme.ink
    palette.base: Theme.paper
    palette.highlight: Theme.accent
    contentItem: VnField {
        text: control.displayText
        font: control.font
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        padding: 2
        background: null
    }
    Keys.onTabPressed: event => { Keyboard.move(control, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(control, false); event.accepted = true; }
}
