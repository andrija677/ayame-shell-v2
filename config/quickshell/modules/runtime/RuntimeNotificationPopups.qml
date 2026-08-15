import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../theme"

PanelWindow {
    id: root

    property var popups: []

    function showPopup(notification) {
        const id = Date.now().toString() + Math.random().toString(16).slice(2);
        popups = popups.concat([{ id: id, notification: notification }]);
        expiry.popupId = id;
        expiry.interval = Math.max(2500, Math.min(12000,
            Number(notification.expireTimeout) || 6000));
        expiry.restart();
    }

    function dismiss(id) {
        popups = popups.filter(item => item.id !== id);
    }

    anchors { top: true; right: true }
    margins { top: 76; right: 16 }
    implicitWidth: 380
    implicitHeight: Math.max(1, popupColumn.implicitHeight)
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: popups.length > 0
    WlrLayershell.namespace: "ayame-shell-v2-notification-popups"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: popupColumn
        width: parent.width
        spacing: Theme.space8
        Repeater {
            model: root.popups
            GlassSurface {
                id: popupCard
                required property var modelData
                width: popupColumn.width
                implicitHeight: popupContent.implicitHeight + Theme.space24
                radius: Theme.radiusLarge
                depth: 3
                RowLayout {
                    id: popupContent
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.space12 }
                    spacing: Theme.space12
                    AppIcon {
                        icon: "notifications"
                        backgroundColor: Theme.accentSoft
                        iconColor: Theme.onAccentSoft
                        implicitWidth: 42; implicitHeight: 42; iconSize: 22
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText {
                            Layout.fillWidth: true
                            text: popupCard.modelData.notification.summary
                                || popupCard.modelData.notification.appName || "Notification"
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        AppText {
                            Layout.fillWidth: true
                            text: popupCard.modelData.notification.body
                            color: Theme.onSurfaceMuted
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            visible: popupCard.modelData.notification.actions.length > 0
                            Repeater {
                                model: popupCard.modelData.notification.actions
                                ActionPill {
                                    required property var modelData
                                    label: modelData.text
                                    onActivated: {
                                        modelData.invoke();
                                        root.dismiss(popupCard.modelData.id);
                                    }
                                }
                            }
                        }
                    }
                    IconButton {
                        icon: "close"
                        accessibleName: "Dismiss notification"
                        onActivated: root.dismiss(popupCard.modelData.id)
                    }
                }
            }
        }
    }

    Connections {
        target: NotificationService
        function onPopupRequested(notification) { root.showPopup(notification); }
        function onPopupsCleared() { root.popups = []; }
    }
    Timer {
        id: expiry
        property string popupId: ""
        onTriggered: root.dismiss(popupId)
    }
}
