import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../theme"

GlassSurface {
    id: root

    property var executables: []
    property string query: ""
    property string status: ""
    signal appAdded(string name, string path)
    signal closeRequested()

    readonly property var filteredExecutables: {
        const needle = query.trim().toLowerCase();
        if (!needle)
            return executables;
        return executables.filter(path => {
            const name = path.substring(path.lastIndexOf("/") + 1);
            return (name + " " + path).toLowerCase().includes(needle);
        });
    }

    function open() {
        query = "";
        status = "";
        scanner.running = true;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function add(path) {
        if (registration.running)
            return;
        status = "Adding app…";
        registration.selectedPath = path;
        registration.command = ["bash", Quickshell.shellDir
            + "/../../scripts/ayame-add-app", path];
        registration.running = true;
    }

    radius: Theme.radiusXLarge
    depth: 3

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space20 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText { text: "Add an app"; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }
                AppText {
                    text: "Choose any runnable app or executable"
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                icon: "close"
                accessibleName: "Close executable picker"
                onActivated: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Theme.radiusPill
            color: Theme.glassHighest
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? Theme.accent : Theme.glassStroke
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.space16; rightMargin: Theme.space16 }
                AppIcon { icon: "search"; implicitWidth: 24; implicitHeight: 24; iconSize: 20 }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.onSurface
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.onAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: root.closeRequested()
                    AppText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text.length === 0
                        text: "Search runnable files…"
                        color: Theme.outline
                    }
                }
            }
        }

        AppText {
            text: "Applications, Downloads, Desktop, and local commands"
            color: Theme.accent
            font.pixelSize: Theme.fontSmall
            font.weight: Font.Bold
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.filteredExecutables
            spacing: Theme.space8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: fileRow
                required property string modelData
                width: ListView.view.width
                height: 58
                radius: Theme.radiusMedium
                color: filePointer.containsMouse ? Theme.accentSoft : Theme.glassHighest
                readonly property string fileName: modelData.substring(modelData.lastIndexOf("/") + 1)
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    AppIcon {
                        icon: "deployed_code"
                        backgroundColor: Theme.accentSoft
                        iconColor: Theme.onAccentSoft
                        implicitWidth: 36; implicitHeight: 36; iconSize: 20
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        AppText { Layout.fillWidth: true; text: fileRow.fileName; font.weight: Font.Bold; elide: Text.ElideMiddle }
                        AppText { Layout.fillWidth: true; text: fileRow.modelData; color: Theme.onSurfaceMuted; font.pixelSize: Theme.fontSmall; elide: Text.ElideMiddle }
                    }
                    AppText { text: "Add"; color: Theme.accent; font.weight: Font.Bold }
                }
                MouseArea {
                    id: filePointer
                    anchors.fill: parent
                    enabled: !registration.running
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.add(fileRow.modelData)
                }
                Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
            }
            AppText {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: scanner.running ? "Finding runnable files…"
                    : root.query.length > 0 ? "No matching files" : "No runnable files found"
                color: Theme.outline
            }
        }

        AppText {
            Layout.fillWidth: true
            text: root.status.length > 0 ? root.status
                : "Ayame adds a launcher entry; your original file stays untouched."
            color: root.status.endsWith(" added") ? Theme.success : Theme.outline
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Process {
        id: scanner
        command: ["sh", "-c", "find \"$HOME/Applications\" \"$HOME/Downloads\" "
            + "\"$HOME/Desktop\" \"${XDG_BIN_HOME:-$HOME/.local/bin}\" -maxdepth 4 -type f "
            + "\\( -perm /u=x,g=x,o=x -o -iname '*.appimage' \\) "
            + "-not -name '*.desktop' -print 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const clean = text.trim();
                root.executables = clean.length > 0 ? clean.split("\n") : [];
            }
        }
    }

    Process {
        id: registration
        property string selectedPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0) {
                    root.status = name + " added";
                    root.appAdded(name, registration.selectedPath);
                    closeTimer.restart();
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.status = "Could not add that file";
        }
    }

    Timer { id: closeTimer; interval: 850; onTriggered: root.closeRequested() }
}
