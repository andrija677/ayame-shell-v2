import QtQuick
import QtTest
import "../config/quickshell/components"

TestCase {
    name: "IconButton"
    when: windowShown

    width: 200
    height: 120

    Component {
        id: buttonComponent
        IconButton { icon: "settings"; accessibleName: "Settings" }
    }

    function test_pointerActivation() {
        const button = createTemporaryObject(buttonComponent, this);
        verify(button !== null);
        const signal = createSignalSpy(button, "activated");
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton);
        compare(signal.count, 1);
    }

    function test_keyboardActivation() {
        const button = createTemporaryObject(buttonComponent, this);
        verify(button !== null);
        const signal = createSignalSpy(button, "activated");
        button.forceActiveFocus();
        keyClick(Qt.Key_Return);
        compare(signal.count, 1);
    }

    function test_disabled() {
        const button = createTemporaryObject(buttonComponent, this, { enabled: false });
        verify(button !== null);
        const signal = createSignalSpy(button, "activated");
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton);
        compare(signal.count, 0);
    }
}
