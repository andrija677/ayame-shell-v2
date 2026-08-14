import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

Item {
    id: root

    property string activeOverlay: ""
    property int activeWorkspace: 3
    signal overlayRequested(string name)
    signal workspaceRequested(int workspace)

    implicitHeight: 52

    GlassSurface {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: workspaceContent.implicitWidth + Theme.space20
        height: 46
        radius: Theme.radiusPill
        depth: 1

        RowLayout {
            id: workspaceContent
            anchors.centerIn: parent
            spacing: Theme.space4

            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: root.activeWorkspace === index + 1 ? 34 : 28
                    height: 34
                    radius: Theme.radiusPill
                    color: root.activeWorkspace === index + 1
                        ? Theme.accent : workspacePointer.containsMouse
                            ? Theme.accentSoft : "transparent"

                    AppText {
                        anchors.centerIn: parent
                        text: parent.index + 1
                        color: root.activeWorkspace === parent.index + 1
                            ? Theme.onAccent : Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontLabel
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: workspacePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.workspaceRequested(parent.index + 1)
                    }

                    Behavior on width {
                        NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                }
            }
        }
    }

    GlassSurface {
        anchors.centerIn: parent
        width: clockContent.implicitWidth + Theme.space24
        height: 46
        radius: Theme.radiusPill
        depth: 1
        active: root.activeOverlay === "hub"

        RowLayout {
            id: clockContent
            anchors.centerIn: parent
            spacing: Theme.space8

            AppIcon {
                icon: "auto_awesome"
                implicitWidth: 20
                implicitHeight: 20
                iconSize: 16
                iconColor: Theme.accent
            }
            AppText {
                text: Qt.formatTime(new Date(), "hh:mm")
                font.family: Theme.numericFontFamily
                font.weight: Font.Bold
            }
            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Theme.outline
            }
            AppText {
                text: Qt.formatDate(new Date(), "ddd d MMM")
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontLabel
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.overlayRequested("hub")
        }
    }

    GlassSurface {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: statusContent.implicitWidth + Theme.space16
        height: 46
        radius: Theme.radiusPill
        depth: 1
        active: root.activeOverlay === "hub"

        RowLayout {
            id: statusContent
            anchors.centerIn: parent
            spacing: Theme.space4

            AppIcon {
                icon: "wifi"
                implicitWidth: 30
                implicitHeight: 30
                iconSize: 17
                iconColor: Theme.onSurfaceMuted
            }
            AppIcon {
                icon: "volume_up"
                implicitWidth: 30
                implicitHeight: 30
                iconSize: 17
                iconColor: Theme.onSurfaceMuted
            }
            AppText {
                text: "25°"
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontLabel
                font.weight: Font.Bold
            }
            IconButton {
                icon: root.activeOverlay === "hub" ? "close" : "tune"
                accessibleName: "Open control and notification hub"
                checked: root.activeOverlay === "hub"
                implicitWidth: 36
                implicitHeight: 36
                onActivated: root.overlayRequested("hub")
            }
        }
    }
}
