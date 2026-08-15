import "../theme"
import QtQuick
import QtQuick.Layouts

GlassSurface {
    id: root

    property string title: "Level"
    property string subtitle: ""
    property real value: 0.5
    property real from: 0
    property real to: 1
    property string valueText: Math.round(value * 100) + "%"
    property bool available: true

    signal moved(real value)

    implicitHeight: 90
    radius: Theme.radiusLarge
    depth: 1
    opacity: available ? 1 : 0.58

    ColumnLayout {
        spacing: Theme.space12

        anchors {
            fill: parent
            margins: Theme.space16
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                AppText {
                    text: root.title
                    font.weight: Font.Bold
                }

                AppText {
                    text: root.subtitle
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }

            }

            AppText {
                text: root.valueText
                font.family: Theme.numericFontFamily
                font.weight: Font.Bold
            }

        }

        Rectangle {
            id: track

            readonly property real fraction: Math.max(0, Math.min(1, (root.value - root.from) / Math.max(0.0001, root.to - root.from)))

            Layout.fillWidth: true
            implicitHeight: 8
            radius: 4
            color: Theme.alpha(Theme.outline, 0.24)

            Rectangle {
                width: parent.width * track.fraction
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * track.fraction - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: Theme.accent
                border.width: 3
                border.color: Theme.onAccent
            }

            MouseArea {
                function update(x) {
                    root.moved(root.from + Math.max(0, Math.min(1, x / width)) * (root.to - root.from));
                }

                enabled: root.available
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: (mouse) => {
                    return update(mouse.x);
                }
                onPositionChanged: (mouse) => {
                    if (pressed)
                        update(mouse.x);

                }

                anchors {
                    fill: parent
                    topMargin: -12
                    bottomMargin: -12
                }

            }

        }

    }

}
