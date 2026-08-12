import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string label: "Action"
    property string symbol: ""
    property bool primary: false
    property bool checked: false
    readonly property bool highlighted: primary || checked
    signal activated()

    implicitWidth: content.implicitWidth + Theme.space24
    implicitHeight: 38
    radius: Theme.radiusPill
    color: !enabled ? Theme.alpha(Theme.glassHighest, 0.48)
        : pointer.containsMouse || activeFocus ? Theme.accent
        : highlighted ? Theme.accentSoft : Theme.glassHighest
    border.width: highlighted && !pointer.containsMouse ? 1 : 0
    border.color: Theme.accent
    opacity: enabled ? 1 : 0.58
    scale: pointer.pressed ? 0.96 : pointer.containsMouse ? 1.02 : 1

    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label
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

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Theme.space8

        AppText {
            visible: root.symbol.length > 0
            text: root.symbol
            color: pointer.containsMouse || root.activeFocus ? Theme.onAccent
                : root.highlighted ? Theme.onAccentSoft : Theme.accent
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        AppText {
            text: root.label
            color: pointer.containsMouse || root.activeFocus ? Theme.onAccent
                : root.highlighted ? Theme.onAccentSoft : Theme.onSurface
            font.pixelSize: Theme.fontLabel
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.forceActiveFocus();
            root.activated();
        }
    }
}
