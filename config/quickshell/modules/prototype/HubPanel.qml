import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

GlassSurface {
    id: root

    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property bool nightLightEnabled: false
    property bool doNotDisturb: false
    property real volume: 0.35
    signal closeRequested()
    signal settingsRequested()

    radius: Theme.radiusXLarge
    depth: 2

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space20 }
        spacing: Theme.space16

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText {
                    text: "Control center"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                AppText {
                    text: "Everything feels good"
                    color: Theme.success
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                icon: "settings"
                accessibleName: "Open Settings"
                onActivated: root.settingsRequested()
            }
            IconButton {
                icon: "close"
                accessibleName: "Close control center"
                onActivated: root.closeRequested()
            }
        }

        MediaCard {
            Layout.fillWidth: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.space12
            rowSpacing: Theme.space12

            Repeater {
                model: [
                    { title: "Wi-Fi", subtitle: root.wifiEnabled ? "Home • Connected" : "Off", icon: "wifi", checked: root.wifiEnabled },
                    { title: "Bluetooth", subtitle: root.bluetoothEnabled ? "On" : "Off", icon: "bluetooth", checked: root.bluetoothEnabled },
                    { title: "Night light", subtitle: root.nightLightEnabled ? "Warm and easy" : "Off", icon: "bedtime", checked: root.nightLightEnabled },
                    { title: "Focus", subtitle: root.doNotDisturb ? "Quiet mode" : "Notifications on", icon: "do_not_disturb_on", checked: root.doNotDisturb }
                ]
                Rectangle {
                    id: controlTile
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    radius: Theme.radiusLarge
                    color: modelData.checked ? Theme.accentSoft : Theme.glassHighest
                    border.width: 1
                    border.color: modelData.checked ? Theme.accent : Theme.glassStroke

                    RowLayout {
                        anchors { fill: parent; margins: Theme.space12 }
                        spacing: Theme.space12
                        AppIcon {
                            icon: controlTile.modelData.icon
                            backgroundColor: controlTile.modelData.checked
                                ? Theme.accent : Theme.alpha(Theme.outline, 0.18)
                            iconColor: controlTile.modelData.checked
                                ? Theme.onAccent : Theme.onSurfaceMuted
                            implicitWidth: 42
                            implicitHeight: 42
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            AppText { text: controlTile.modelData.title; font.weight: Font.Bold }
                            AppText {
                                text: controlTile.modelData.subtitle
                                color: Theme.onSurfaceMuted
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (controlTile.index === 0) root.wifiEnabled = !root.wifiEnabled;
                            else if (controlTile.index === 1) root.bluetoothEnabled = !root.bluetoothEnabled;
                            else if (controlTile.index === 2) root.nightLightEnabled = !root.nightLightEnabled;
                            else root.doNotDisturb = !root.doNotDisturb;
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionResponsive } }
                }
            }
        }

        GlassSurface {
            Layout.fillWidth: true
            implicitHeight: 72
            depth: 1
            radius: Theme.radiusLarge
            RowLayout {
                anchors { fill: parent; margins: Theme.space16 }
                spacing: Theme.space12
                AppIcon {
                    icon: root.volume === 0 ? "volume_off" : "volume_up"
                    implicitWidth: 28
                    implicitHeight: 28
                    iconSize: 22
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Theme.alpha(Theme.outline, 0.24)
                    Rectangle {
                        width: parent.width * root.volume
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                    Rectangle {
                        x: Math.max(0, parent.width * root.volume - width / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: Theme.accent
                        border.width: 3
                        border.color: Theme.onAccent
                    }
                    MouseArea {
                        anchors { fill: parent; topMargin: -12; bottomMargin: -12 }
                        onPressed: mouse => root.volume = Math.max(0, Math.min(1, mouse.x / width))
                        onPositionChanged: mouse => {
                            if (pressed) root.volume = Math.max(0, Math.min(1, mouse.x / width));
                        }
                    }
                }
                AppText {
                    text: Math.round(root.volume * 100) + "%"
                    font.family: Theme.numericFontFamily
                    font.weight: Font.Bold
                }
            }
        }

        SectionTitle { title: "Notifications"; detail: root.doNotDisturb ? "Paused" : "All caught up" }

        GlassSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            depth: 1
            radius: Theme.radiusLarge
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.space8
                AppIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: root.doNotDisturb ? "notifications_paused" : "done_all"
                    backgroundColor: Theme.accentSoft
                    iconColor: Theme.onAccentSoft
                    implicitWidth: 52
                    implicitHeight: 52
                }
                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.doNotDisturb ? "Peace and quiet" : "You’re all caught up"
                    font.weight: Font.Bold
                }
                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.doNotDisturb ? "Notifications are waiting politely" : "New moments will appear here"
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
