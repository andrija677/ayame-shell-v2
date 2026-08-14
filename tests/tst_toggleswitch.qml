import QtQuick
import QtTest
import "../config/quickshell/components"

TestCase {
    name: "ToggleSwitch"
    when: windowShown

    width: 200
    height: 120

    Component {
        id: toggleComponent
        ToggleSwitch { accessibleName: "Test toggle" }
    }

    function test_pointerRequestsOppositeState() {
        const toggle = createTemporaryObject(toggleComponent, this, { checked: false });
        verify(toggle !== null);
        const signal = createSignalSpy(toggle, "toggled");
        mouseClick(toggle, toggle.width / 2, toggle.height / 2, Qt.LeftButton);
        compare(signal.count, 1);
        compare(signal.signalArguments[0][0], true);
    }

    function test_keyboardRequestsOppositeState() {
        const toggle = createTemporaryObject(toggleComponent, this, { checked: true });
        verify(toggle !== null);
        const signal = createSignalSpy(toggle, "toggled");
        toggle.forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(signal.count, 1);
        compare(signal.signalArguments[0][0], false);
    }
}
