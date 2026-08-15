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
    property bool hovered: false
    property int launchedIndex: -1
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property bool revealed: !ShellSettings.dockAutoHide
        || hovered || controller.activeOverlay.length > 0
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

    HoverHandler { onHoveredChanged: root.hovered = hovered }

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
}
