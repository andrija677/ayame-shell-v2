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
    property bool pointerReveal: false
    property bool closeReveal: false
    property int launchedIndex: -1
    property int previousWindowCount: -1
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property bool revealed: !ShellSettings.dockAutoHide
        || !workspaceObstructed || pointerReveal || closeReveal
        || controller.activeOverlay.length > 0
    readonly property int runningWindowCount: {
        let count = 0;
        for (const candidate of Hyprland.toplevels.values) {
            if (candidate.monitor === root.hyprlandMonitor)
                count++;
        }
        return count;
    }
    readonly property bool workspaceObstructed: {
        const workspace = hyprlandMonitor?.activeWorkspace;
        if (!workspace)
            return false;
        if (workspace.hasFullscreen)
            return true;

        const windows = workspace.toplevels.values;
        const monitorLeft = hyprlandMonitor.x;
        const monitorBottom = hyprlandMonitor.y + hyprlandMonitor.height;
        const dockLeft = monitorLeft
            + (hyprlandMonitor.width - dock.implicitWidth) / 2;
        const dockRight = dockLeft + dock.implicitWidth;
        const dockTop = monitorBottom - dock.implicitHeight - Theme.space32;
        for (let i = 0; i < windows.length; ++i) {
            const geometry = windows[i].lastIpcObject?.size;
            const position = windows[i].lastIpcObject?.at;
            if (!geometry || geometry.length < 2
                    || !position || position.length < 2)
                continue;
            const windowRight = position[0] + geometry[0];
            const windowBottom = position[1] + geometry[1];
            const overlapsDock = windowRight > dockLeft
                && position[0] < dockRight
                && windowBottom > dockTop
                && position[1] < monitorBottom;
            if (overlapsDock)
                return true;
        }
        return false;
    }
    readonly property var dockApps: {
        DesktopEntries.applications.values;
        const candidates = ShellSettings.dockFavorites();
        const result = [];
        for (const candidate of candidates) {
            const entry = DesktopEntries.byId(candidate)
                || DesktopEntries.heuristicLookup(candidate);
            if (entry && !result.some(item => item.id === entry.id))
                result.push({ id: entry.id, entry: entry, label: entry.name,
                    icon: entry.icon, tone: result.length % 3 === 0 ? "secondary"
                        : result.length % 3 === 1 ? "neutral" : "tertiary",
                    running: false, active: false, toplevel: null });
        }
        for (const toplevel of Hyprland.toplevels.values) {
            if (toplevel.monitor !== root.hyprlandMonitor)
                continue;
            const appId = toplevel?.wayland?.appId
                || toplevel?.lastIpcObject?.class || "";
            const entry = DesktopEntries.heuristicLookup(appId);
            const id = entry?.id || appId;
            if (!id)
                continue;
            const existing = result.findIndex(item => item.id === id);
            const item = { id: id, entry: entry, label: entry?.name || appId,
                icon: entry?.icon || "application-x-executable", tone: "primary",
                running: true, active: toplevel.activated, toplevel: toplevel };
            if (existing >= 0) {
                const previous = result[existing];
                item.active = previous.active || toplevel.activated;
                item.toplevel = toplevel.activated
                    ? toplevel : previous.toplevel || toplevel;
                result[existing] = item;
            }
            else
                result.push(item);
        }
        return result;
    }

    anchors.bottom: true
    implicitWidth: dock.implicitWidth + 120
    implicitHeight: 98
    exclusiveZone: 0
    visible: ShellSettings.dockEnabled
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-v2-dock"
    WlrLayershell.layer: WlrLayer.Overlay

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                hideDelay.stop();
                root.pointerReveal = true;
            } else {
                hideDelay.restart();
            }
        }
    }

    Timer {
        id: hideDelay
        interval: 420
        onTriggered: root.pointerReveal = false
    }

    Timer {
        id: closeRevealTimer
        interval: 1700
        onTriggered: root.closeReveal = false
    }

    PrototypeDock {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.revealed ? Theme.space16 : -60
        activeOverlay: root.controller.activeOverlay
        launchedIndex: root.launchedIndex
        apps: root.dockApps
        onOverlayRequested: name => root.controller.toggleOverlay(name, root.screen)
        onAppRequested: index => {
            const app = root.dockApps[index];
            if (!app) return;
            root.launchedIndex = index;
            if (app.toplevel?.wayland) {
                if (app.toplevel.activated)
                    app.toplevel.wayland.minimized = true;
                else
                    app.toplevel.wayland.activate();
            } else if (app.entry) {
                app.entry.execute();
            }
        }
        onAppSecondaryRequested: index => {
            const app = root.dockApps[index];
            if (app) ShellSettings.toggleDockFavorite(app.id);
        }
        Behavior on anchors.bottomMargin {
            SpringAnimation { spring: 3.4; damping: 0.32; mass: 0.72; epsilon: 0.2 }
        }
    }

    onRevealedChanged: if (revealed) dock.playReveal()
    onRunningWindowCountChanged: {
        if (previousWindowCount >= 0
                && runningWindowCount < previousWindowCount
                && ShellSettings.dockAutoHide) {
            closeReveal = true;
            closeRevealTimer.restart();
        }
        previousWindowCount = runningWindowCount;
    }
    Component.onCompleted: previousWindowCount = runningWindowCount
}
