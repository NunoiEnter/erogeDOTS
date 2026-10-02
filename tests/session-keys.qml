import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtTest
import "Keyboard.js" as Keyboard

Item {
    width: 800; height: 680
    QtObject {
        id: state
        property bool sessionShown: true
        property string performed: ""
        property int sounds: 0
        function playSessionSound(kind) { sounds++; }
        function performSession(action) { performed = action; }
    }
    SessionDialog { id: dialog; anchors.fill: parent; state: state }
    Item {
        id: pane; width: 300; height: 200; visible: false
        property bool keyboardBoundary: true
        Keys.onTabPressed: event => { Keyboard.move(Window.window.activeFocusItem, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
        Keys.onBacktabPressed: event => { Keyboard.move(Window.window.activeFocusItem, false); event.accepted = true; }
        VnButton { id: first; text: "First" }
        VnButton { y: 40; text: "Disabled"; enabled: false }
        VnButton { id: last; y: 80; text: "Last" }
        VnSlider { id: volume; y: 120; width: 280; label: "Volume"; value: 0.5; onMoved: value => volume.value = value }
        VnSpinBox { id: number; y: 170; from: 0; to: 50; value: 20; visible: false }
    }
    VnButton { text: "Outside pane"; visible: pane.visible; y: 240 }
    TestCase {
        name: "SessionKeys"
        when: windowShown
        function init() { pane.visible = false; number.visible = false; dialog.visible = true; state.performed = ""; state.sessionShown = true; dialog.reset(""); wait(30); }
        function test_choice_then_enter_defaults_to_no() {
            keyClick(Qt.Key_Return); compare(dialog.action, "sleep"); wait(30);
            keyClick(Qt.Key_Return); compare(dialog.action, ""); compare(state.performed, "");
        }
        function test_all_four_choices_are_keyboard_reachable() {
            const actions = ["sleep", "lock", "restart", "shutdown"];
            for (let index = 0; index < actions.length; index++) {
                dialog.reset(""); wait(20);
                for (let step = 0; step < index; step++) keyClick(Qt.Key_Down);
                keyClick(Qt.Key_Return); compare(dialog.action, actions[index]); wait(20);
                keyClick(Qt.Key_Right); keyClick(Qt.Key_Return);
                compare(state.performed, actions[index]);
            }
        }
        function test_escape_cancels_confirmation_and_returns() {
            dialog.reset("shutdown"); wait(20);
            keyClick(Qt.Key_Escape); compare(dialog.action, ""); compare(state.performed, "");
            keyClick(Qt.Key_Escape); compare(state.sessionShown, false);
        }
        function test_button_navigation_skips_disabled_and_stays_in_pane() {
            dialog.visible = false; pane.visible = true; const slider = Keyboard.controls(volume)[0]; first.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Down); verify(last.activeFocus);
            keyClick(Qt.Key_Down); verify(slider.activeFocus);
            Keyboard.move(slider, true); verify(first.activeFocus);
            keyClick(Qt.Key_Up); verify(slider.activeFocus);
        }
        function test_slider_keeps_native_arrow_adjustment() {
            dialog.visible = false; pane.visible = true; const slider = Keyboard.controls(volume)[0]; volume.value = 0.5; slider.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Right); compare(Math.round(slider.value * 100), 51); verify(slider.activeFocus);
            keyClick(Qt.Key_Left); compare(Math.round(slider.value * 100), 50);
        }
        function test_editable_spinbox_keeps_adjustment_and_tab_wraps() {
            dialog.visible = false; pane.visible = true; number.visible = true; number.value = 20;
            number.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Up); compare(number.value, 21);
            keyClick(Qt.Key_Tab); verify(first.activeFocus);
        }
        function test_editable_spinbox_accepts_typed_value() {
            dialog.visible = false; pane.visible = true; number.visible = true;
            number.contentItem.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_A, Qt.ControlModifier); keyClick(Qt.Key_3); keyClick(Qt.Key_4);
            keyClick(Qt.Key_Return); compare(number.value, 34);
            keyClick(Qt.Key_Tab); verify(first.activeFocus);
        }
        function test_tab_wraps_without_leaving_page() {
            dialog.visible = false; pane.visible = true; const slider = Keyboard.controls(volume)[0]; slider.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Tab); verify(first.activeFocus);
            keyClick(Qt.Key_Tab, Qt.ShiftModifier); verify(slider.activeFocus);
        }
    }
}
