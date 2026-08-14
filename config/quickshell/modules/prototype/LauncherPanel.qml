import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../components"
import "../../theme"

GlassSurface {
    id: root

    property string query: ""
    signal appRequested(var entry)
    signal closeRequested()

    radius: Theme.radiusXLarge
    depth: 2

    readonly property var apps: {
        DesktopEntries.applications.values;
        const needle = query.trim().toLowerCase();
        const entries = DesktopEntries.applications.values.filter(entry => {
            if (entry.noDisplay) return false;
            if (!needle) return true;
            const keywords = entry.keywords ? entry.keywords.join(" ") : "";
            return ((entry.name || "") + " " + (entry.genericName || "")
                + " " + keywords).toLowerCase().includes(needle);
        });
        entries.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return entries.slice(0, 9);
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
                        onClicked: root.appRequested(appTile.modelData)
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
            ActionPill { label: "Add an app"; symbol: "+"; enabled: false }
            AppText {
                Layout.fillWidth: true
                text: "Executable picker arrives with launcher integration"
                color: Theme.outline
                font.pixelSize: Theme.fontSmall
            }
            ActionPill { label: "Power"; symbol: "⏻"; enabled: false }
        }
    }

    Component.onCompleted: searchInput.forceActiveFocus()
}
