import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

FloatingWindow {
    id: root

    property string activeOverlay: "launcher"
    property int activeWorkspace: 3
    property int launchedApp: -1
    property string toastMessage: ""
    readonly property bool dockRevealed: !ShellSettings.dockAutoHide
        || dockWakeArea.containsMouse || activeOverlay.length > 0

    title: "Ayame Shell V2 — Interactive Prototype"
    implicitWidth: 1180
    implicitHeight: 760
    minimumSize: Qt.size(840, 600)
    color: Theme.background
    visible: ShellSettings.previewVisible

    function toggleOverlay(name) {
        activeOverlay = activeOverlay === name ? "" : name;
    }

    function showToast(message) {
        toastMessage = message;
        toastTimer.restart();
    }

    IpcHandler {
        target: "preview"
        function launcher(): void { root.activeOverlay = "launcher"; }
        function hub(): void { root.activeOverlay = "hub"; }
        function ai(): void { root.activeOverlay = "ai"; }
        function settings(): void { root.activeOverlay = "settings"; }
        function close(): void { root.activeOverlay = ""; }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        Image {
            anchors.fill: parent
            source: PaletteService.detectedWallpaper.length > 0
                ? "file://" + PaletteService.detectedWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.background, Theme.light ? 0.12 : 0.28)
        }

        Rectangle {
            anchors.fill: parent
            enabled: root.activeOverlay.length > 0
            color: Theme.alpha(Theme.background, Theme.light ? 0.18 : 0.34)
            opacity: enabled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.activeOverlay = ""
            }
        }

        PrototypeBar {
            id: bar
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
            activeOverlay: root.activeOverlay
            activeWorkspace: root.activeWorkspace
            onOverlayRequested: name => root.toggleOverlay(name)
            onWorkspaceRequested: workspace => {
                root.activeWorkspace = workspace;
                root.showToast("Workspace " + workspace);
            }
        }

        Item {
            id: dockHost
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 98

            MouseArea {
                id: dockWakeArea
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                width: dock.width + 100
                height: parent.height
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            PrototypeDock {
                id: dock
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.dockRevealed ? 14 : dockHost.height - 8
                activeOverlay: root.activeOverlay
                launchedIndex: root.launchedApp
                onOverlayRequested: name => root.toggleOverlay(name)
                onAppRequested: index => {
                    root.launchedApp = index;
                    root.showToast(["Files", "Kitty", "Firefox", "Discord"][index] + " ready");
                }

                Behavior on y {
                    SpringAnimation {
                        spring: 3.4
                        damping: 0.32
                        mass: 0.72
                        epsilon: 0.2
                    }
                }
            }
        }

        LauncherPanel {
            anchors { left: parent.left; top: bar.bottom; bottom: parent.bottom; margins: Theme.space16; bottomMargin: 98 }
            width: Math.min(610, parent.width * 0.58)
            enabled: root.activeOverlay === "launcher"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.94
            transformOrigin: Item.BottomLeft
            transform: Translate {
                x: root.activeOverlay === "launcher" ? 0 : -28
                Behavior on x { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeExit } }
            }
            onCloseRequested: root.activeOverlay = ""
            onAppRequested: entry => {
                if (!entry) return;
                entry.execute();
                root.activeOverlay = "";
                root.showToast((entry.name || "Application") + " launched");
            }
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on scale { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter } }
        }

        HubPanel {
            anchors { right: parent.right; top: bar.bottom; bottom: parent.bottom; margins: Theme.space16; bottomMargin: 98 }
            width: Math.min(460, parent.width * 0.44)
            enabled: root.activeOverlay === "hub"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.94
            transformOrigin: Item.TopRight
            transform: Translate {
                x: root.activeOverlay === "hub" ? 0 : 28
                Behavior on x { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeExit } }
            }
            onCloseRequested: root.activeOverlay = ""
            onSettingsRequested: root.activeOverlay = "settings"
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on scale { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter } }
        }

        AiPanel {
            anchors { right: parent.right; top: bar.bottom; bottom: parent.bottom; margins: Theme.space16; bottomMargin: 98 }
            width: Math.min(500, parent.width * 0.48)
            enabled: root.activeOverlay === "ai"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.94
            transformOrigin: Item.BottomRight
            transform: Translate {
                x: root.activeOverlay === "ai" ? 0 : 30
                Behavior on x { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeExit } }
            }
            onCloseRequested: root.activeOverlay = ""
            onSettingsRequested: root.activeOverlay = "settings"
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on scale { NumberAnimation { duration: Theme.motionExpressive; easing.type: Theme.easeEnter } }
        }

        SettingsPanel {
            anchors.centerIn: parent
            width: Math.min(850, parent.width - Theme.space40 * 2)
            height: Math.min(570, parent.height - 150)
            enabled: root.activeOverlay === "settings"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.90
            transform: Translate {
                y: root.activeOverlay === "settings" ? 0 : 26
                Behavior on y { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeExit } }
            }
            onCloseRequested: root.activeOverlay = ""
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on scale { NumberAnimation { duration: Theme.motionExpressive; easing.type: Theme.easeEnter } }
        }

        GlassSurface {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 96 }
            width: toastText.implicitWidth + Theme.space32
            height: 44
            radius: Theme.radiusPill
            depth: 2
            visible: root.toastMessage.length > 0
            opacity: visible ? 1 : 0
            AppText {
                id: toastText
                anchors.centerIn: parent
                text: root.toastMessage
                font.weight: Font.Bold
            }
            Behavior on opacity { NumberAnimation { duration: Theme.motionQuick } }
        }
    }

    function appsForToast(index) {
        return ["Files ready", "Kitty ready", "Firefox ready", "Discord ready", "Settings", "Music ready"][index];
    }

    Timer {
        id: toastTimer
        interval: 1800
        onTriggered: root.toastMessage = ""
    }

    onDockRevealedChanged: {
        if (dockRevealed) dock.playReveal();
    }

    Shortcut { sequence: "Escape"; onActivated: root.activeOverlay = "" }
    Shortcut { sequence: "Ctrl+Space"; onActivated: root.toggleOverlay("launcher") }
}
