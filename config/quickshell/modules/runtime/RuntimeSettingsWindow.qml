import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../prototype"
import "../../theme"

FloatingWindow {
    id: root

    required property var controller
    title: "Ayame V2 Settings"
    implicitWidth: 920
    implicitHeight: 640
    minimumSize: Qt.size(760, 540)
    color: Theme.background
    visible: controller.activeOverlay === "settings"

    SettingsPanel {
        anchors { fill: parent; margins: Theme.space16 }
        onCloseRequested: root.controller.closeOverlay()
    }

    Shortcut { sequence: "Escape"; onActivated: root.controller.closeOverlay() }

    Timer {
        id: floatTimer
        interval: 80
        onTriggered: {
            Hyprland.dispatch("hl.dsp.window.float({ action = \"set\", window = \"title:^Ayame V2 Settings$\" })");
            Hyprland.dispatch("hl.dsp.window.resize({ x = 920, y = 640, window = \"title:^Ayame V2 Settings$\" })");
            Hyprland.dispatch("hl.dsp.window.center({ window = \"title:^Ayame V2 Settings$\" })");
        }
    }

    onVisibleChanged: if (visible) floatTimer.restart()
}
