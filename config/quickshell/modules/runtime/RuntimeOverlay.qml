import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../prototype"
import "../dashboard"
import "../../theme"

PanelWindow {
    id: root

    required property var controller
    readonly property bool open: controller.activeOverlay.length > 0
        && controller.activeOverlay !== "settings"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open
    WlrLayershell.namespace: "ayame-shell-v2-overlay"
    // The backdrop and opened panel sit above applications, while Ayame's
    // persistent chrome uses the Overlay layer and therefore stays crisp.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, Theme.light ? 0.20 : 0.40)
        MouseArea { anchors.fill: parent; onClicked: root.controller.closeOverlay() }
    }

    LauncherPanel {
        id: launcher
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 112 }
        width: Math.min(610, parent.width * 0.58)
        height: Math.min(650, parent.height - 210)
        enabled: root.controller.activeOverlay === "launcher"
        opacity: enabled ? 1 : 0
        scale: enabled ? 1 : 0.94
        transformOrigin: Item.Bottom
        onCloseRequested: root.controller.closeOverlay()
        onAppRequested: entry => {
            if (!entry) return;
            if (entry.ayameExecutable) {
                executableProcess.command = [entry.path];
                executableProcess.running = true;
            } else entry.execute();
            root.controller.closeOverlay();
        }
        onPowerRequested: root.controller.activeOverlay = "power"
        Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
        Behavior on scale { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter } }
    }

    DashboardPanel {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
            topMargin: 88
            bottomMargin: 112
        }
        width: Math.min(470, parent.width - Theme.space40 * 2)
        enabled: root.controller.activeOverlay === "dashboard"
        opacity: enabled ? 1 : 0
        scale: enabled ? 1 : 0.94
        transformOrigin: Item.Top
        transform: Translate {
            y: root.controller.activeOverlay === "dashboard" ? 0 : -24
            Behavior on y {
                NumberAnimation {
                    duration: Theme.motionResponsive
                    easing.type: Theme.easeExit
                }
            }
        }
        onCloseRequested: root.controller.closeOverlay()
        Behavior on opacity {
            NumberAnimation { duration: Theme.motionResponsive }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionResponsive
                easing.type: Theme.easeEnter
            }
        }
    }

    HubPanel {
        id: hubPanel
        hostWindow: root
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: Theme.space16; topMargin: 88; bottomMargin: 112 }
        width: Math.min(460, parent.width * 0.44)
        enabled: root.controller.activeOverlay === "hub"
        opacity: enabled ? 1 : 0
        transform: [
            Translate {
                x: root.controller.activeOverlay === "hub" ? 0 : 20
                y: root.controller.activeOverlay === "hub" ? 0 : -12
                Behavior on x {
                    NumberAnimation {
                        duration: Theme.motionResponsive
                        easing.type: root.controller.activeOverlay === "hub"
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.motionResponsive
                        easing.type: root.controller.activeOverlay === "hub"
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
            },
            Scale {
                origin.x: hubPanel.width
                origin.y: 0
                xScale: root.controller.activeOverlay === "hub" ? 1 : 0.92
                yScale: root.controller.activeOverlay === "hub" ? 1 : 0.84
                Behavior on xScale {
                    NumberAnimation {
                        duration: Theme.motionResponsive
                        easing.type: root.controller.activeOverlay === "hub"
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: Theme.motionResponsive
                        easing.type: root.controller.activeOverlay === "hub"
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
            }
        ]
        onCloseRequested: root.controller.closeOverlay()
        onSettingsRequested: root.controller.activeOverlay = "settings"
        onPowerRequested: root.controller.activeOverlay = "power"
        Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
    }

    AiPanel {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: Theme.space16; topMargin: 88; bottomMargin: 112 }
        width: Math.min(500, parent.width * 0.48)
        enabled: root.controller.activeOverlay === "ai"
        opacity: enabled ? 1 : 0
        scale: enabled ? 1 : 0.94
        transformOrigin: Item.BottomRight
        onCloseRequested: root.controller.closeOverlay()
        onSettingsRequested: root.controller.activeOverlay = "settings"
        Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
        Behavior on scale { NumberAnimation { duration: Theme.motionExpressive; easing.type: Theme.easeEnter } }
    }

    PowerPanel {
        anchors.centerIn: parent
        width: Math.min(620, parent.width - Theme.space40 * 2)
        height: Math.min(500, parent.height - 160)
        enabled: root.controller.activeOverlay === "power"
        opacity: enabled ? 1 : 0
        scale: enabled ? 1 : 0.92
        onCloseRequested: root.controller.closeOverlay()
        Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
        Behavior on scale { NumberAnimation { duration: Theme.motionExpressive; easing.type: Theme.easeEnter } }
    }

    Process { id: executableProcess }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.controller.activeOverlay === "launcher" && launcher.pickerOpen)
                launcher.pickerOpen = false;
            else root.controller.closeOverlay();
        }
    }
}
