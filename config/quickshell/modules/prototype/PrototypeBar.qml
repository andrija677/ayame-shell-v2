import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

Item {
    id: root

    property var hostWindow: null
    property string activeOverlay: ""
    property int activeWorkspace: 1
    property string activeWindowTitle: ""
    property date currentTime: new Date()
    property bool trayExpanded: false
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery?.isPresent
        && battery?.isLaptopBattery
    readonly property int batteryPercent: Math.round(
        Math.max(0, Math.min(1, battery?.percentage ?? 0)) * 100)
    readonly property bool compact: ShellSettings.densityMode === "compact"

    signal overlayRequested(string name)
    signal workspaceRequested(int workspace)

    implicitHeight: compact ? 46 : 52

    GlassSurface {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        visible: ShellSettings.workspacesEnabled
            || (ShellSettings.activeWindowEnabled && root.activeWindowTitle.length > 0)
        width: leftContent.implicitWidth + Theme.space20
        height: root.compact ? 40 : 46
        radius: ShellSettings.barStyle === "edge" ? Theme.radiusMedium : Theme.radiusPill
        depth: ShellSettings.barStyle === "minimal" ? 0 : 1
        color: ShellSettings.barStyle === "minimal" ? "transparent" : Theme.glassRaised
        border.width: ShellSettings.barStyle === "minimal" ? 0 : 1

        RowLayout {
            id: leftContent
            anchors.centerIn: parent
            spacing: Theme.space4

            Repeater {
                model: ShellSettings.workspacesEnabled ? ShellSettings.workspaceCount : 0
                Rectangle {
                    id: workspace
                    required property int index
                    width: root.activeWorkspace === index + 1 ? 34 : 28
                    height: 34
                    radius: Theme.radiusPill
                    color: root.activeWorkspace === index + 1 ? Theme.accent
                        : workspacePointer.containsMouse ? Theme.accentSoft : "transparent"
                    AppText {
                        anchors.centerIn: parent
                        text: workspace.index + 1
                        color: root.activeWorkspace === workspace.index + 1
                            ? Theme.onAccent : Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontLabel
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: workspacePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.workspaceRequested(workspace.index + 1)
                    }
                    Behavior on width { NumberAnimation { duration: Theme.motionResponsive } }
                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                }
            }

            Rectangle {
                visible: ShellSettings.workspacesEnabled && ShellSettings.activeWindowEnabled
                    && root.activeWindowTitle.length > 0
                width: 1; height: 18; color: Theme.outlineSoft
            }
            AppText {
                visible: ShellSettings.activeWindowEnabled && root.activeWindowTitle.length > 0
                Layout.maximumWidth: 210
                text: root.activeWindowTitle
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }
    }

    GlassSurface {
        anchors.centerIn: parent
        visible: ShellSettings.clockEnabled
        width: clockContent.implicitWidth + Theme.space24
        height: root.compact ? 40 : 46
        radius: ShellSettings.barStyle === "edge" ? Theme.radiusMedium : Theme.radiusPill
        depth: ShellSettings.barStyle === "minimal" ? 0 : 1
        active: root.activeOverlay === "hub"
        color: active ? Theme.accentSoft
            : ShellSettings.barStyle === "minimal" ? "transparent" : Theme.glassRaised
        border.width: ShellSettings.barStyle === "minimal" && !active ? 0 : 1

        RowLayout {
            id: clockContent
            anchors.centerIn: parent
            spacing: Theme.space8
            AppIcon {
                visible: ShellSettings.dashboardEnabled
                icon: "auto_awesome"
                implicitWidth: 20; implicitHeight: 20; iconSize: 16
                iconColor: Theme.accent
            }
            AppText {
                text: Qt.formatTime(root.currentTime,
                    ShellSettings.clockFormat === "12h" ? "h:mm AP" : "HH:mm")
                font.family: Theme.numericFontFamily
                font.weight: Font.Bold
            }
            Rectangle { width: 4; height: 4; radius: 2; color: Theme.outline }
            AppText {
                text: Qt.formatDate(root.currentTime, "ddd d MMM")
                color: Theme.onSurfaceMuted
                font.pixelSize: Theme.fontLabel
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: ShellSettings.dashboardEnabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.overlayRequested("hub")
        }
    }

    GlassSurface {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: ShellSettings.networkEnabled || ShellSettings.audioEnabled
            || ShellSettings.batteryEnabled || ShellSettings.trayEnabled
            || ShellSettings.quickSettingsEnabled || WeatherService.configured
        width: statusContent.implicitWidth + Theme.space16
        height: root.compact ? 40 : 46
        radius: ShellSettings.barStyle === "edge" ? Theme.radiusMedium : Theme.radiusPill
        depth: ShellSettings.barStyle === "minimal" ? 0 : 1
        active: root.activeOverlay === "hub"
        color: active ? Theme.accentSoft
            : ShellSettings.barStyle === "minimal" ? "transparent" : Theme.glassRaised
        border.width: ShellSettings.barStyle === "minimal" && !active ? 0 : 1

        RowLayout {
            id: statusContent
            anchors.centerIn: parent
            spacing: Theme.space4

            AppIcon {
                visible: ShellSettings.networkEnabled
                icon: ControlService.networkingEnabled ? "wifi" : "wifi_off"
                implicitWidth: 30; implicitHeight: 30; iconSize: 17
                iconColor: Theme.onSurfaceMuted
            }
            AppIcon {
                visible: ShellSettings.audioEnabled
                icon: ControlService.muted || ControlService.volume === 0
                    ? "volume_off" : "volume_up"
                implicitWidth: 30; implicitHeight: 30; iconSize: 17
                iconColor: Theme.onSurfaceMuted
            }
            AppText {
                visible: WeatherService.configured
                text: WeatherService.hasData
                    ? Math.round(WeatherService.forecast.current.temperature_2m) + "°"
                    : WeatherService.loading ? "…" : "Weather"
                color: WeatherService.error.length > 0 ? Theme.warning : Theme.onSurfaceMuted
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Bold
            }
            AppText {
                visible: ShellSettings.batteryEnabled && root.batteryAvailable
                text: root.batteryPercent + "%"
                color: root.batteryPercent <= 15 ? Theme.danger : Theme.onSurfaceMuted
                font.family: Theme.numericFontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Bold
            }
            AppIcon {
                visible: ControlService.bluetoothEnabled
                icon: "bluetooth"
                implicitWidth: 30; implicitHeight: 30; iconSize: 17
                iconColor: Theme.onSurfaceMuted
            }

            IconButton {
                visible: ShellSettings.trayEnabled && SystemTray.items.values.length > 0
                icon: root.trayExpanded ? "expand_less" : "more_horiz"
                accessibleName: root.trayExpanded ? "Hide tray icons" : "Show tray icons"
                implicitWidth: 32; implicitHeight: 32
                onActivated: root.trayExpanded = !root.trayExpanded
            }
            Item {
                visible: ShellSettings.trayEnabled && root.trayExpanded
                Layout.preferredWidth: visible ? trayItems.implicitWidth : 0
                Layout.preferredHeight: 30
                Row {
                    id: trayItems
                    spacing: Theme.space4
                    Repeater {
                        model: ShellSettings.trayEnabled ? SystemTray.items : null
                        TrayItemButton {
                            required property var modelData
                            trayItem: modelData
                            hostWindow: root.hostWindow
                        }
                    }
                }
            }
            IconButton {
                visible: ShellSettings.quickSettingsEnabled
                icon: root.activeOverlay === "hub" ? "close" : "tune"
                accessibleName: "Open control and notification hub"
                checked: root.activeOverlay === "hub"
                implicitWidth: 36; implicitHeight: 36
                onActivated: root.overlayRequested("hub")
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentTime = new Date()
    }
}
