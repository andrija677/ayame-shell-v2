import "../theme"
import QtQuick
import QtQuick.Layouts

GlassSurface {
    id: root

    property string title: "Choice"
    property string subtitle: ""
    property var options: []
    property var value

    signal chosen(var value)

    implicitHeight: choiceContent.implicitHeight + Theme.space32
    radius: Theme.radiusLarge
    depth: 1

    ColumnLayout {
        id: choiceContent

        spacing: Theme.space12

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.space16
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

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

        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.space8

            Repeater {
                model: root.options

                ActionPill {
                    required property var modelData

                    label: modelData.label
                    checked: root.value === modelData.value
                    onActivated: root.chosen(modelData.value)
                }

            }

        }

    }

}
