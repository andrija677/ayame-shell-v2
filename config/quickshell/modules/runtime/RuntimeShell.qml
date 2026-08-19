import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../settings"

Scope {
    id: root
    readonly property var shellController: controller

    QtObject {
        id: controller
        property string activeOverlay: ""
        property var activeScreen: null
        property int areaCaptureSerial: 0

        function toggleOverlay(name, screen) {
            activeScreen = screen;
            activeOverlay = activeOverlay === name ? "" : name;
        }
        function closeOverlay() { activeOverlay = ""; }
        function requestAreaCapture() {
            closeOverlay();
            areaCaptureSerial++;
        }
    }

    IpcHandler {
        target: "ayame-v2"
        function launcher(): void { controller.activeOverlay = "launcher"; }
        function dashboard(): void { controller.activeOverlay = "dashboard"; }
        function hub(): void { controller.activeOverlay = "hub"; }
        function ai(): void { controller.activeOverlay = "ai"; }
        function settings(): void { controller.activeOverlay = "settings"; }
        function close(): void { controller.closeOverlay(); }
        function capture(): void { controller.requestAreaCapture(); }
    }

    // Hyprland does not continuously publish window geometry while a window is
    // being moved. Refresh it while intelligent hiding is enabled so the dock
    // reacts as soon as a window crosses its bounds.
    Timer {
        interval: 120
        repeat: true
        running: ShellSettings.dockEnabled && ShellSettings.dockAutoHide
        triggeredOnStart: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            RuntimeBar {
                required property var modelData
                screen: modelData
                controller: root.shellController
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            RuntimeDock {
                required property var modelData
                screen: modelData
                controller: root.shellController
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            RuntimeOverlay {
                required property var modelData
                screen: modelData
                controller: root.shellController
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            RuntimeCapturePill {
                required property var modelData
                screen: modelData
                controller: root.shellController
            }
        }
    }

    RuntimeSettingsWindow { controller: root.shellController }
    RuntimeNotificationPopups {}
}
