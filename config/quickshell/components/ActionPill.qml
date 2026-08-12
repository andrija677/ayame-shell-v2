import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string label: "Action"
    property string symbol: ""
    property bool primary: false
    signal activated()

    implicitWidth: content.implicitWidth + Theme.space24
    implicitHeight: 38
    radius: Theme.radiusPill
    color: pointer.containsMouse
        ? Theme.accent : primary ? Theme.accentSoft : Theme.glassHighest
    border.width: primary && !pointer.containsMouse ? 1 : 0
    border.color: Theme.accent
    scale: pointer.pressed ? 0.96 : pointer.containsMouse ? 1.02 : 1

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
            color: pointer.containsMouse ? Theme.onAccent
                : root.primary ? Theme.onAccentSoft : Theme.accent
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        AppText {
            text: root.label
            color: pointer.containsMouse ? Theme.onAccent
                : root.primary ? Theme.onAccentSoft : Theme.onSurface
            font.pixelSize: Theme.fontLabel
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
