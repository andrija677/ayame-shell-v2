import QtQuick
import "../theme"

Rectangle {
    id: root

    property string icon: "more_horiz"
    property string accessibleName: icon
    property bool checked: false
    property bool circular: true
    signal activated()

    implicitWidth: 42
    implicitHeight: 42
    radius: circular ? Math.min(width, height) / 2 : Theme.radiusMedium
    color: !enabled ? Theme.alpha(Theme.glassHighest, 0.36)
        : pointer.containsMouse || activeFocus ? Theme.accentSoft
        : checked ? Theme.accent : Theme.alpha(Theme.glassHighest, 0.76)
    border.width: activeFocus ? 2 : checked ? 0 : 1
    border.color: activeFocus ? Theme.accent : Theme.glassStroke
    opacity: enabled ? 1 : 0.5
    scale: pointer.pressed ? 0.92 : pointer.containsMouse ? 1.04 : 1

    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.pressed: checked

    Keys.onPressed: event => {
        if (enabled && (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space)) {
            root.activated();
            event.accepted = true;
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionQuick; easing.type: Theme.easeEnter }
    }

    AppIcon {
        anchors.fill: parent
        icon: root.icon
        iconColor: root.checked ? Theme.onAccent
            : pointer.containsMouse || root.activeFocus
                ? Theme.onAccentSoft : Theme.onSurface
        backgroundColor: "transparent"
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.activated();
        }
    }
}
