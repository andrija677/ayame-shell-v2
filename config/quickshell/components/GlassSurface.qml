import QtQuick
import "../theme"

Rectangle {
    id: root

    property int depth: 0
    property bool interactive: false
    property bool active: false

    radius: Theme.radiusLarge
    color: active ? Theme.accentSoft
        : depth >= 2 ? Theme.glassHighest
        : depth === 1 ? Theme.glassRaised : Theme.glass
    border.width: 1
    border.color: active ? Theme.accent : Theme.glassStroke

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.radius * 0.58
            rightMargin: root.radius * 0.58
        }
        height: 1
        color: Theme.glassHighlight
        visible: !root.active
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionResponsive }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.motionResponsive }
    }
}
