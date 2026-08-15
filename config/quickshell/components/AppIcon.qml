import QtQuick
import "../theme"

Rectangle {
    id: root

    property string icon: "apps"
    property color iconColor: Theme.onSurface
    property color backgroundColor: "transparent"
    property int iconSize: Math.round(Math.min(width, height) * 0.52)

    implicitWidth: 40
    implicitHeight: 40
    radius: Math.min(width, height) / 2
    color: backgroundColor

    Text {
        anchors.fill: parent
        text: root.icon
        color: root.iconColor
        font.family: "Material Icons Round"
        font.pixelSize: root.iconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
