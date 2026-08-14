import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root

    property string title: "Section"
    property string detail: ""

    AppText {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: Theme.fontTitle
        font.weight: Font.Bold
    }

    AppText {
        visible: root.detail.length > 0
        text: root.detail
        color: Theme.onSurfaceMuted
        font.pixelSize: Theme.fontSmall
    }
}
