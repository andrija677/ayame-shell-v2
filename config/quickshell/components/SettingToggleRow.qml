import "../theme"
import QtQuick
import QtQuick.Layouts

GlassSurface {
    id: root

    property string title: "Setting"
    property string subtitle: ""
    property bool checked: false
    property bool available: true
    property string icon: ""

    signal toggled(bool checked)

    implicitHeight: 74
    radius: Theme.radiusLarge
    depth: 1
    opacity: available ? 1 : 0.58

    RowLayout {
        spacing: Theme.space12

        anchors {
            fill: parent
            margins: Theme.space16
        }

        AppIcon {
            visible: root.icon.length > 0
            icon: root.icon
            backgroundColor: root.checked ? Theme.accentSoft : Theme.glassHighest
            iconColor: root.checked ? Theme.onAccentSoft : Theme.onSurfaceMuted
            implicitWidth: 38
            implicitHeight: 38
            iconSize: 21
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            AppText {
                text: root.title
                font.weight: Font.Bold
            }

            AppText {
                Layout.fillWidth: true
                text: root.subtitle
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

        }

        ToggleSwitch {
            accessibleName: root.title
            checked: root.checked
            enabled: root.available
            onToggled: (checked) => {
                return root.toggled(checked);
            }
        }

    }

}
