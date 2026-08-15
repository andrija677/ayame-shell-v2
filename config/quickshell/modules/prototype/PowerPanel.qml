import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../components"
import "../../theme"

GlassSurface {
    id: root

    property string pendingAction: ""
    property string status: ""
    signal closeRequested()

    readonly property var actions: [
        { key: "lock", title: "Lock", subtitle: "Keep everything waiting", icon: "lock" },
        { key: "suspend", title: "Sleep", subtitle: "Rest without closing", icon: "bedtime" },
        { key: "logout", title: "Log out", subtitle: "End this Hyprland session", icon: "logout" },
        { key: "reboot", title: "Restart", subtitle: "Start the system fresh", icon: "restart_alt" },
        { key: "poweroff", title: "Shut down", subtitle: "Turn this computer off", icon: "power_settings_new" }
    ]

    function request(key) {
        if (key === "lock") {
            execute(key);
            return;
        }
        pendingAction = key;
        status = "";
    }

    function execute(key) {
        if (actionProcess.running)
            return;
        const commands = {
            lock: ["loginctl", "lock-session"],
            suspend: ["systemctl", "suspend"],
            logout: ["hyprctl", "dispatch", "exit"],
            reboot: ["systemctl", "reboot"],
            poweroff: ["systemctl", "poweroff"]
        };
        actionProcess.command = commands[key];
        actionProcess.running = true;
        status = "Working…";
    }

    function titleFor(key) {
        for (const action of actions) {
            if (action.key === key)
                return action.title;
        }
        return key;
    }

    radius: Theme.radiusXLarge
    depth: 3

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space20 }
        spacing: Theme.space16

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText { text: "Power"; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }
                AppText { text: "Take a breath, or call it a day"; color: Theme.onSurfaceMuted }
            }
            IconButton { icon: "close"; accessibleName: "Close power menu"; onActivated: root.closeRequested() }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.space12
            rowSpacing: Theme.space12
            Repeater {
                model: root.actions
                Rectangle {
                    id: actionTile
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 86
                    radius: Theme.radiusLarge
                    color: actionPointer.containsMouse ? Theme.accentSoft : Theme.glassHighest
                    border.width: 1
                    border.color: actionPointer.containsMouse ? Theme.accent : Theme.glassStroke
                    RowLayout {
                        anchors { fill: parent; margins: Theme.space12 }
                        AppIcon {
                            icon: actionTile.modelData.icon
                            backgroundColor: Theme.accentSoft
                            iconColor: Theme.onAccentSoft
                            implicitWidth: 44; implicitHeight: 44; iconSize: 23
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            AppText { text: actionTile.modelData.title; font.weight: Font.Bold }
                            AppText { Layout.fillWidth: true; text: actionTile.modelData.subtitle; color: Theme.onSurfaceMuted; font.pixelSize: Theme.fontSmall; wrapMode: Text.WordWrap }
                        }
                    }
                    MouseArea {
                        id: actionPointer
                        anchors.fill: parent
                        enabled: !actionProcess.running
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.request(actionTile.modelData.key)
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                }
            }
        }

        GlassSurface {
            Layout.fillWidth: true
            implicitHeight: root.pendingAction.length > 0 ? 76 : 48
            radius: Theme.radiusLarge
            depth: 1
            RowLayout {
                anchors { fill: parent; margins: Theme.space12 }
                AppText {
                    Layout.fillWidth: true
                    text: root.pendingAction.length > 0
                        ? "Really " + root.titleFor(root.pendingAction).toLowerCase() + "?"
                        : root.status.length > 0 ? root.status : "Lock acts immediately; system actions ask first."
                    color: root.status.startsWith("Could") ? Theme.danger : Theme.onSurfaceMuted
                    font.weight: root.pendingAction.length > 0 ? Font.Bold : Font.Normal
                }
                ActionPill {
                    visible: root.pendingAction.length > 0
                    label: "Cancel"
                    onActivated: root.pendingAction = ""
                }
                ActionPill {
                    visible: root.pendingAction.length > 0
                    label: "Confirm"
                    primary: true
                    onActivated: {
                        const key = root.pendingAction;
                        root.pendingAction = "";
                        root.execute(key);
                    }
                }
            }
        }
    }

    Process {
        id: actionProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.status = "Could not complete that action";
            else {
                root.status = "Done";
                closeTimer.restart();
            }
        }
    }
    Timer { id: closeTimer; interval: 600; onTriggered: root.closeRequested() }
}
