import QtQuick
import "../theme"

Rectangle {
    id: root

    property bool checked: false
    property string accessibleName: "Toggle"
    signal toggled(bool checked)

    implicitWidth: 48
    implicitHeight: 28
    radius: height / 2
    color: checked ? Theme.accent : Theme.alpha(Theme.outline, 0.34)
    border.width: checked ? 0 : 1
    border.color: Theme.outline

    activeFocusOnTab: enabled
    Accessible.role: Accessible.CheckBox
    Accessible.name: accessibleName
    Accessible.checked: checked

    Keys.onPressed: event => {
        if (enabled && (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space)) {
            root.toggled(!root.checked);
            event.accepted = true;
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }

    Rectangle {
        width: root.checked ? 20 : 16
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - 4 : 6
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked
            ? Theme.light ? "#FFFFFF" : Theme.onAccent
            : Theme.onSurfaceMuted

        Behavior on x {
            NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter }
        }
        Behavior on width { NumberAnimation { duration: Theme.motionQuick } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.toggled(!root.checked);
        }
    }
}
