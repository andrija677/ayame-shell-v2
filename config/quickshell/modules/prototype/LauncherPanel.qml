import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../components"
import "../../theme"

GlassSurface {
    id: root

    property string query: ""
    property bool pickerOpen: false
    property string addAppStatus: ""
    property var newlyAddedApps: []
    property var removedAppIds: []
    property var pendingRemoval: null
    signal appRequested(var entry)
    signal closeRequested()
    signal powerRequested()

    radius: Theme.radiusXLarge
    depth: 2

    readonly property var apps: {
        DesktopEntries.applications.values;
        const needle = query.trim().toLowerCase();
        const desktopApps = DesktopEntries.applications.values.filter(entry =>
            root.removedAppIds.indexOf(entry.id) < 0);
        const pendingApps = root.newlyAddedApps.filter(added =>
            !desktopApps.some(entry => (entry.execString || "").includes(added.path)));
        const entries = desktopApps.concat(pendingApps).filter(entry => {
            if (entry.noDisplay) return false;
            if (!needle) return true;
            const keywords = entry.keywords ? entry.keywords.join(" ") : "";
            return ((entry.name || "") + " " + (entry.genericName || "")
                + " " + keywords).toLowerCase().includes(needle);
        });
        entries.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return entries.slice(0, 9);
    }

    function isAyameApp(entry) {
        return entry && (entry.ayameExecutable
            || (entry.id || "").startsWith("ayame-app-"));
    }

    function executablePath(entry) {
        if (entry.path)
            return entry.path;
        if (entry.command && entry.command.length > 0)
            return entry.command[0];
        const raw = entry.execString || "";
        const quoted = raw.match(/^\"([^\"]+)\"/);
        return quoted ? quoted[1] : raw.split(" ")[0];
    }

    function removeApp(entry) {
        if (!isAyameApp(entry) || removeProcess.running)
            return;
        const path = executablePath(entry);
        if (!path) {
            addAppStatus = "Could not locate that app";
            statusTimer.restart();
            return;
        }
        pendingRemoval = { id: entry.id, path: path, name: entry.name };
        removeProcess.command = ["bash", Quickshell.shellDir
            + "/../../scripts/ayame-add-app", "--remove", path];
        removeProcess.running = true;
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space20 }
        spacing: Theme.space16

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText {
                    text: "Good evening, Andrija"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                AppText {
                    text: "Where are we going?"
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                icon: "close"
                accessibleName: "Close launcher"
                onActivated: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: Theme.radiusPill
            color: Theme.glassHighest
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? Theme.accent : Theme.glassStroke

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.space16; rightMargin: Theme.space16 }
                spacing: Theme.space12
                AppIcon {
                    icon: "search"
                    implicitWidth: 24
                    implicitHeight: 24
                    iconSize: 20
                    iconColor: Theme.onSurfaceMuted
                }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.onSurface
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.onAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    clip: true
                    onTextChanged: root.query = text
                    onAccepted: {
                        if (root.query.trim().length > 0 && root.apps.length === 1)
                            root.appRequested(root.apps[0]);
                    }
                    Keys.onEscapePressed: root.closeRequested()

                    AppText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text.length === 0
                        text: "Search apps, actions, and settings"
                        color: Theme.outline
                    }
                }
                AppText {
                    text: "ESC"
                    color: Theme.outline
                    font.family: Theme.numericFontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            AppText {
                Layout.fillWidth: true
                text: root.query.length > 0 ? "Results" : "Your space"
                font.weight: Font.Bold
            }
            AppText {
                text: root.query.length > 0 ? root.apps.length + " matching “" + root.query + "”"
                    : "First 9 alphabetically"
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontSmall
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Theme.space12
            rowSpacing: Theme.space12

            Repeater {
                model: root.apps
                Rectangle {
                    id: appTile
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    radius: Theme.radiusLarge
                    color: appPointer.containsMouse ? Theme.accentSoft : Theme.glassHighest
                    border.width: 1
                    border.color: appPointer.containsMouse ? Theme.accent : Theme.glassStroke
                    scale: appPointer.pressed ? 0.97 : 1

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.space12 }
                        spacing: Theme.space8
                        Rectangle {
                            property string resolvedIcon: Quickshell.iconPath(
                                appTile.modelData.icon || "", true)
                            implicitWidth: 42
                            implicitHeight: 42
                            radius: Theme.radiusMedium
                            color: appTile.index % 3 === 0 ? Theme.secondarySoft
                                : appTile.index % 3 === 1 ? Theme.accentSoft : Theme.tertiarySoft

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 28
                                source: parent.resolvedIcon
                                visible: parent.resolvedIcon.length > 0
                                asynchronous: true
                            }
                            AppText {
                                anchors.centerIn: parent
                                visible: parent.resolvedIcon.length === 0
                                text: (appTile.modelData.name || "?").slice(0, 1).toUpperCase()
                                font.weight: Font.ExtraBold
                            }
                        }
                        AppText {
                            text: appTile.modelData.name
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        AppText {
                            text: appTile.modelData.genericName || "Application"
                            color: Theme.onSurfaceMuted
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: appPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                root.removeApp(appTile.modelData);
                            else
                                root.appRequested(appTile.modelData);
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                    Behavior on scale { NumberAnimation { duration: Theme.motionQuick } }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8
            ActionPill {
                label: "Add an app"
                symbol: "+"
                onActivated: {
                    root.pickerOpen = true;
                    executablePicker.open();
                }
            }
            AppText {
                Layout.fillWidth: true
                text: root.addAppStatus.length > 0 ? root.addAppStatus
                    : "Right-click Ayame-added apps to remove them"
                color: Theme.outline
                font.pixelSize: Theme.fontSmall
            }
            ActionPill { label: "Power"; symbol: "⏻"; onActivated: root.powerRequested() }
        }
    }

    ExecutablePicker {
        id: executablePicker
        anchors.fill: parent
        z: 20
        visible: root.pickerOpen
        enabled: visible
        opacity: visible ? 1 : 0
        onCloseRequested: {
            root.pickerOpen = false;
            Qt.callLater(() => searchInput.forceActiveFocus());
        }
        onAppAdded: (name, path) => {
            const id = "ayame-added:" + path;
            const remaining = root.newlyAddedApps.filter(app => app.path !== path);
            root.newlyAddedApps = remaining.concat([{
                id: id,
                name: name,
                genericName: "Added by Ayame",
                keywords: [],
                icon: "application-x-executable",
                noDisplay: false,
                execString: path,
                path: path,
                ayameExecutable: true
            }]);
            root.addAppStatus = name + " added";
            statusTimer.restart();
        }
        Behavior on opacity { NumberAnimation { duration: Theme.motionQuick } }
    }

    Process { id: addedAppProcess }
    Process {
        id: removeProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.pendingRemoval) {
                root.removedAppIds = root.removedAppIds.concat([root.pendingRemoval.id]);
                root.newlyAddedApps = root.newlyAddedApps.filter(app =>
                    app.path !== root.pendingRemoval.path);
                root.addAppStatus = root.pendingRemoval.name + " removed";
            } else {
                root.addAppStatus = "Could not remove that app";
            }
            root.pendingRemoval = null;
            statusTimer.restart();
        }
    }

    Timer { id: statusTimer; interval: 3200; onTriggered: root.addAppStatus = "" }

    Component.onCompleted: searchInput.forceActiveFocus()
}
