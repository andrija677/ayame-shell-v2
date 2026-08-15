import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../components"
import "../../settings"
import "../../theme"

GlassSurface {
    id: root

    property string activeOverlay: ""
    property int launchedIndex: -1
    property int hoverIndex: -99
    property var apps: []
    signal overlayRequested(string name)
    signal appRequested(int index)
    signal appSecondaryRequested(int index)

    function playReveal() { revealed(); }
    signal revealed()

    implicitWidth: dockContent.implicitWidth + Theme.space16
    implicitHeight: 68
    radius: Theme.radiusLarge
    depth: 2

    RowLayout {
        id: dockContent
        anchors.centerIn: parent
        spacing: Theme.space8

        IconButton {
            icon: "apps"
            accessibleName: "Open application launcher"
            checked: root.activeOverlay === "launcher"
            implicitWidth: 46
            implicitHeight: 46
            circular: false
            onActivated: root.overlayRequested("launcher")
        }

        Rectangle {
            width: 1
            height: 32
            color: Theme.glassStroke
        }

        Repeater {
            model: root.apps

            Item {
                id: appItem
                required property var modelData
                required property int index
                property real bounceScale: 1
                readonly property real hoverScale: root.hoverIndex < 0 ? 1
                    : 1 + Math.max(0, 0.14 - 0.055 * Math.abs(index - root.hoverIndex))
                width: 50
                height: 54
                scale: bounceScale * hoverScale

                Rectangle {
                    anchors.centerIn: parent
                    width: appPointer.containsMouse ? 48 : 44
                    height: width
                    radius: Theme.radiusMedium
                    color: modelData.tone === "primary" ? Theme.accentSoft
                        : modelData.tone === "secondary" ? Theme.secondarySoft
                        : modelData.tone === "tertiary" ? Theme.tertiarySoft
                        : Theme.glassHighest

                    IconImage {
                        id: appImage
                        anchors.fill: parent
                        anchors.margins: 9
                        source: Quickshell.iconPath(modelData.icon || "", true)
                        asynchronous: true
                    }
                    AppText {
                        anchors.centerIn: parent
                        visible: appImage.source.toString().length === 0
                        text: (modelData.label || "?").slice(0, 1).toUpperCase()
                        font.weight: Font.ExtraBold
                    }

                    Behavior on width {
                        NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter }
                    }
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: modelData.active ? 16 : modelData.running ? 4 : 0
                    height: modelData.active ? 3 : 4
                    radius: 2
                    color: modelData.active ? Theme.accent : Theme.outline
                    opacity: modelData.active || modelData.running ? 1 : 0
                    Behavior on width { NumberAnimation { duration: Theme.motionResponsive } }
                }

                MouseArea {
                    id: appPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverIndex = appItem.index
                    onExited: {
                        if (root.hoverIndex === appItem.index) root.hoverIndex = -99;
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            root.appSecondaryRequested(appItem.index);
                        } else {
                            launchBounce.restart();
                            root.appRequested(appItem.index);
                        }
                    }
                }

                Connections {
                    target: root
                    function onRevealed() { entranceBounce.restart(); }
                }

                SequentialAnimation {
                    id: entranceBounce
                    PauseAnimation { duration: appItem.index * 38 }
                    NumberAnimation {
                        target: appItem; property: "bounceScale"
                        from: 0.82; to: 1.16; duration: Theme.motionResponsive
                        easing.type: Easing.OutBack
                    }
                    NumberAnimation {
                        target: appItem; property: "bounceScale"
                        to: 1; duration: Theme.motionResponsive
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation {
                    id: launchBounce
                    NumberAnimation {
                        target: appItem; property: "bounceScale"
                        to: 0.78; duration: Theme.motionQuick
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        target: appItem; property: "bounceScale"
                        to: 1.22; duration: Theme.motionResponsive
                        easing.type: Easing.OutBack
                    }
                    NumberAnimation {
                        target: appItem; property: "bounceScale"
                        to: 1; duration: Theme.motionResponsive
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation { duration: Theme.motionQuick; easing.type: Theme.easeEnter }
                }
            }
        }

        Rectangle {
            Layout.leftMargin: Theme.space4
            width: 1
            height: 32
            color: Theme.glassStroke
        }

        IconButton {
            icon: "auto_awesome"
            accessibleName: "Open Ayame AI"
            checked: root.activeOverlay === "ai"
            implicitWidth: 46
            implicitHeight: 46
            circular: false
            visible: ShellSettings.aiEnabled
            onActivated: root.overlayRequested("ai")
        }

        IconButton {
            icon: "settings"
            accessibleName: "Open Ayame Settings"
            checked: root.activeOverlay === "settings"
            implicitWidth: 46
            implicitHeight: 46
            circular: false
            onActivated: root.overlayRequested("settings")
        }
    }
}
