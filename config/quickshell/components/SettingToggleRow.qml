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

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }

    RowLayout {
        z: 1
        spacing: Theme.space8

        anchors {
            fill: parent
            margins: Theme.space12
        }

        AppIcon {
            visible: root.icon.length > 0
            icon: root.icon
            backgroundColor: root.checked ? Theme.accentSoft : Theme.glassHighest
            iconColor: root.checked ? Theme.onAccentSoft : Theme.onSurfaceMuted
            implicitWidth: 38
            implicitHeight: 38
            iconSize: 21
            Layout.minimumWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            AppText {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.Bold
                elide: Text.ElideRight
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
            Layout.minimumWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            accessibleName: root.title
            checked: root.checked
            enabled: root.available
            onToggled: (checked) => {
                return root.toggled(checked);
            }
        }

    }

}
