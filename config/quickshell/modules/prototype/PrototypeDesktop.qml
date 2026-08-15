import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"
import "../dashboard"

FloatingWindow {
    id: root

    property string activeOverlay: "launcher"
    property int activeWorkspace: 3
    property int launchedApp: -1
    property string toastMessage: ""
    readonly property var dockApps: {
        DesktopEntries.applications.values;
        const candidates = ["org.gnome.Nautilus", "kitty", "firefox", "discord"];
        const result = [];
        for (const candidate of candidates) {
            const entry = DesktopEntries.heuristicLookup(candidate);
            if (entry && !result.some(item => item.id === entry.id))
                result.push({ id: entry.id, entry: entry, label: entry.name,
                    icon: entry.icon, tone: result.length % 3 === 0 ? "secondary"
                        : result.length % 3 === 1 ? "neutral" : "tertiary" });
        }
        return result;
    }
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
        function dashboard(): void { root.activeOverlay = "dashboard"; }
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
            hostWindow: root
            activeOverlay: root.activeOverlay
            activeWorkspace: root.activeWorkspace
            activeWindowTitle: "Ayame V2 — interactive preview"
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
                apps: root.dockApps
                onOverlayRequested: name => root.toggleOverlay(name)
                onAppRequested: index => {
                    root.launchedApp = index;
                    const app = root.dockApps[index];
                    if (!app || !app.entry) return;
                    app.entry.execute();
                    root.showToast(app.label + " launched");
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
            id: launcherPanel
            anchors { horizontalCenter: parent.horizontalCenter; top: bar.bottom; bottom: parent.bottom; topMargin: Theme.space16; bottomMargin: 98 }
            width: Math.min(610, parent.width * 0.58)
            enabled: root.activeOverlay === "launcher"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.94
            transformOrigin: Item.Bottom
            transform: Translate {
                y: root.activeOverlay === "launcher" ? 0 : 28
                Behavior on y { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeExit } }
            }
            onCloseRequested: root.activeOverlay = ""
            onAppRequested: entry => {
                if (!entry) return;
                if (entry.ayameExecutable) {
                    addedAppProcess.command = [entry.path];
                    addedAppProcess.running = true;
                } else {
                    entry.execute();
                }
                root.activeOverlay = "";
                root.showToast((entry.name || "Application") + " launched");
            }
            onPowerRequested: root.activeOverlay = "power"
            Behavior on opacity { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on scale { NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter } }
        }

        DashboardPanel {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: bar.bottom
                bottom: parent.bottom
                topMargin: Theme.space16
                bottomMargin: 98
            }
            width: Math.min(470, parent.width - Theme.space40 * 2)
            enabled: root.activeOverlay === "dashboard"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.94
            transformOrigin: Item.Top
            transform: Translate {
                y: root.activeOverlay === "dashboard" ? 0 : -24
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.motionResponsive
                        easing.type: Theme.easeExit
                    }
                }
            }
            onCloseRequested: root.activeOverlay = ""
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
            hostWindow: root
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
            onPowerRequested: root.activeOverlay = "power"
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

        PowerPanel {
            anchors.centerIn: parent
            width: Math.min(620, parent.width - Theme.space40 * 2)
            height: Math.min(500, parent.height - 150)
            enabled: root.activeOverlay === "power"
            opacity: enabled ? 1 : 0
            scale: enabled ? 1 : 0.90
            transform: Translate {
                y: root.activeOverlay === "power" ? 0 : 28
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

    Process { id: addedAppProcess }

    onDockRevealedChanged: {
        if (dockRevealed) dock.playReveal();
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.activeOverlay === "launcher" && launcherPanel.pickerOpen)
                launcherPanel.pickerOpen = false;
            else
                root.activeOverlay = "";
        }
    }
    Shortcut { sequence: "Ctrl+Space"; onActivated: root.toggleOverlay("launcher") }
}
