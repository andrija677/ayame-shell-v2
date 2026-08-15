import "../settings"
import "../theme"
import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root

    required property var trayItem
    required property var hostWindow
    readonly property bool itemVisible: ShellSettings.showPassiveTrayItems || trayItem.status !== Status.Passive

    visible: itemVisible
    implicitWidth: itemVisible ? 30 : 0
    implicitHeight: 30
    radius: Theme.radiusPill
    color: pointer.containsMouse ? Theme.accentSoft : "transparent"
    scale: pointer.pressed ? 0.9 : 1

    IconImage {
        anchors.centerIn: parent
        implicitSize: 17
        source: root.trayItem.icon
        asynchronous: true
        mipmap: true
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (event) => {
            if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && root.trayItem.hasMenu)) {
                const point = root.mapToItem(null, 0, root.height);
                root.trayItem.display(root.hostWindow, point.x, point.y);
            } else if (event.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate();
            } else {
                root.trayItem.activate();
            }
        }
        onWheel: (event) => {
            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
            root.trayItem.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.motionQuick
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionQuick
        }

    }

}
