import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../prototype"
import "../../settings"
import "../../theme"

PanelWindow {
    id: root

    required property var controller
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)

    anchors { top: true; left: true; right: true }
    implicitHeight: 76
    exclusiveZone: 64
    visible: ShellSettings.barEnabled
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-v2-bar"
    WlrLayershell.layer: WlrLayer.Top

    PrototypeBar {
        anchors { fill: parent; margins: Theme.space16; bottomMargin: Theme.space8 }
        hostWindow: root
        activeOverlay: root.controller.activeOverlay
        activeWorkspace: Math.max(1, root.hyprlandMonitor?.activeWorkspace?.id || 1)
        activeWindowTitle: Hyprland.activeToplevel?.title ?? ""
        onOverlayRequested: name => root.controller.toggleOverlay(name, root.screen)
        onWorkspaceRequested: workspace => Hyprland.dispatch(
            "hl.dsp.focus({ workspace = " + workspace + " })")
    }

}
