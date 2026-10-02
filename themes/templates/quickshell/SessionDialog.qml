import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "Keyboard.js" as Keyboard

FocusScope {
    id: dialog
    required property var state
    property bool keyboardBoundary: true
    property string action: ""
    readonly property var labels: ({sleep: "sleep", lock: "lock the screen", restart: "restart", shutdown: "shut down"})
    readonly property var descriptions: ({sleep: "Your applications stay open. Wake the computer to continue.", lock: "Your applications stay open. Unlock to continue.", restart: "Open applications will close. Save your work first.", shutdown: "The computer will turn off. Save your work first."})
    function focusCurrent() { if (action) noChoice.forceActiveFocus(Qt.TabFocusReason); else sleepChoice.forceActiveFocus(Qt.TabFocusReason); }
    function choose(value) { action = value; state.playSessionSound("confirm"); Qt.callLater(() => noChoice.forceActiveFocus(Qt.TabFocusReason)); }
    function reset(value) {
        action = value || "";
        Qt.callLater(focusCurrent);
    }
    function back() { if (action) { action = ""; Qt.callLater(() => sleepChoice.forceActiveFocus(Qt.TabFocusReason)); } else state.sessionShown = false; }
    Keys.onEscapePressed: { state.playSessionSound("cancel"); back(); }
    Keys.onTabPressed: event => { Keyboard.move(Window.window.activeFocusItem, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(Window.window.activeFocusItem, false); event.accepted = true; }
    Flickable {
        id: viewport
        anchors.fill: parent; anchors.margins: 24
        contentWidth: width
        contentHeight: Math.max(height, content.implicitHeight + 32)
        clip: true; boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: content
            width: Math.min(viewport.width, 960)
            x: (viewport.width - width) / 2
            y: Math.max(16, (viewport.height - implicitHeight) / 2)
            spacing: 24
            VnText {
                Layout.fillWidth: true
                text: dialog.action ? "Do you want to " + (dialog.labels[dialog.action] || "") + "?" : "Until we meet again"
                font.family: Theme.titleFont; font.pixelSize: 28
                horizontalAlignment: Text.AlignHCenter
                color: "#fff8fa"; style: Text.Outline; styleColor: "#33262b"
                wrapMode: Text.WordWrap; elide: Text.ElideNone
            }
            VnText {
                visible: dialog.action !== ""; Layout.fillWidth: true
                text: dialog.descriptions[dialog.action] || ""
                horizontalAlignment: Text.AlignHCenter; font.pixelSize: 16
                color: "#fff8fa"; style: Text.Outline; styleColor: "#33262b"
                wrapMode: Text.WordWrap; elide: Text.ElideNone
            }
            ColumnLayout {
                visible: dialog.action === ""; Layout.fillWidth: true; spacing: 22
                SessionChoice { id: sleepChoice; Layout.fillWidth: true; text: "Sleep"; japanese: "おやすみ"; description: "Pause here and keep your applications open"; onClicked: dialog.choose("sleep") }
                SessionChoice { Layout.fillWidth: true; text: "Lock"; japanese: "またあとで"; description: "Keep this scene private until you return"; onClicked: dialog.choose("lock") }
                SessionChoice { Layout.fillWidth: true; text: "Restart"; japanese: "もう一度"; description: "Save your work, then begin a fresh session"; onClicked: dialog.choose("restart") }
                SessionChoice { Layout.fillWidth: true; text: "Shutdown"; japanese: "また明日"; description: "Save your work and say goodnight"; onClicked: dialog.choose("shutdown") }
            }
            ColumnLayout {
                visible: dialog.action !== ""; Layout.fillWidth: true; spacing: 32
                SessionChoice {
                    id: noChoice; Layout.fillWidth: true
                    text: "No, stay here"; japanese: "いいえ、このままで"
                    description: "Cancel this action and return to the choices"
                    onClicked: { dialog.state.playSessionSound("cancel"); dialog.back(); }
                }
                SessionChoice {
                    id: yesChoice; objectName: "session-confirm"; Layout.fillWidth: true
                    text: "Yes, " + (dialog.action === "shutdown" ? "shut down" : dialog.action)
                    japanese: ({sleep: "はい、休む", lock: "はい、画面をロック", restart: "はい、再起動する", shutdown: "はい、終了する"})[dialog.action] || ""
                    description: dialog.descriptions[dialog.action] || ""
                    onClicked: dialog.state.performSession(dialog.action)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                VnText { Layout.fillWidth: true; text: "↑ ↓ choose · Enter select · Esc return"; font.pixelSize: 12; color: "#fff8fa"; style: Text.Outline; styleColor: "#33262b" }
                VnButton {
                    id: returnChoice; visible: dialog.action === ""; compact: true; quiet: true
                    text: "Return"; onClicked: dialog.state.sessionShown = false
                    contentItem: VnText { text: returnChoice.text; color: returnChoice.hovered || returnChoice.visualFocus ? "#ff9de1" : "#fff8fa"; font.underline: returnChoice.visualFocus; style: Text.Outline; styleColor: "#33262b" }
                    background: Item {}
                }
            }
        }
    }
}
