import QtQuick
import QtTest
import "../config/quickshell/components"

TestCase {
    name: "ActionPill"
    when: windowShown

    width: 320
    height: 160

    Component {
        id: pillComponent

        ActionPill {
            label: "Test action"
        }
    }

    function test_pointerActivation() {
        const pill = createTemporaryObject(pillComponent, this);
        verify(pill !== null);

        const signal = createSignalSpy(pill, "activated");
        verify(signal.valid);
        mouseClick(pill, pill.width / 2, pill.height / 2, Qt.LeftButton);
        compare(signal.count, 1);
    }

    function test_keyboardActivation() {
        const pill = createTemporaryObject(pillComponent, this);
        verify(pill !== null);

        const signal = createSignalSpy(pill, "activated");
        pill.forceActiveFocus();
        verify(pill.activeFocus);
        keyClick(Qt.Key_Space);
        compare(signal.count, 1);
    }

    function test_disabled() {
        const pill = createTemporaryObject(pillComponent, this, {
            enabled: false
        });
        verify(pill !== null);

        const signal = createSignalSpy(pill, "activated");
        mouseClick(pill, pill.width / 2, pill.height / 2, Qt.LeftButton);
        compare(signal.count, 0);
    }
}
