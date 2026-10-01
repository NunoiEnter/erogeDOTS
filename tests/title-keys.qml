import QtQuick
import QtTest

Item {
    width: 420; height: 280
    TitleChoice { id: choice; width: 300; text: "Load" }
    TitleChoice { id: second; y: 70; width: 300; text: "Continue" }
    VnButton { id: button; y: 150; text: "Terminal" }
    SignalSpy { id: choices; target: choice; signalName: "clicked" }
    SignalSpy { id: buttons; target: button; signalName: "clicked" }
    TestCase {
        name: "TitleKeys"
        when: windowShown
        function init() { choice.enabled = true; choices.clear(); buttons.clear(); }
        function test_return_and_keypad_enter_activate_choice() {
            choice.forceActiveFocus(); verify(choice.activeFocus);
            keyClick(Qt.Key_Return); compare(choices.count, 1);
            keyClick(Qt.Key_Enter); compare(choices.count, 2);
        }
        function test_arrow_navigation() {
            choice.forceActiveFocus(); keyClick(Qt.Key_Down); verify(second.activeFocus);
            keyClick(Qt.Key_Up); verify(choice.activeFocus);
        }
        function test_disabled_choice_does_not_activate() {
            choice.forceActiveFocus(); choice.enabled = false;
            keyClick(Qt.Key_Return); compare(choices.count, 0);
        }
        function test_page_buttons_accept_enter() {
            button.forceActiveFocus(); keyClick(Qt.Key_Return); compare(buttons.count, 1);
            keyClick(Qt.Key_Enter); compare(buttons.count, 2);
        }
    }
}
