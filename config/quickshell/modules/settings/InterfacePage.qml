import "../../components"
import "../../settings"
import "../../theme"
import QtQuick
import QtQuick.Layouts

Flickable {
    id: root

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: content

        width: root.width
        spacing: Theme.space12

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Top-bar style"
            subtitle: "Floating islands, edge bar, or a minimal strip"
            options: [{
                "label": "Float",
                "value": "floating"
            }, {
                "label": "Edge",
                "value": "edge"
            }, {
                "label": "Minimal",
                "value": "minimal"
            }]
            value: ShellSettings.barStyle
            onChosen: (value) => {
                return ShellSettings.barStyle = value;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "web_asset"
            title: "Top bar"
            subtitle: checked ? "Visible" : "Hidden"
            checked: ShellSettings.barEnabled
            onToggled: (checked) => {
                return ShellSettings.barEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "view_week"
            title: "Workspaces"
            subtitle: checked ? "Visible in bar" : "Hidden from bar"
            checked: ShellSettings.workspacesEnabled
            onToggled: (checked) => {
                return ShellSettings.workspacesEnabled = checked;
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Workspace count"
            subtitle: "Buttons shown in the workspace island"
            options: [{
                "label": "4",
                "value": 4
            }, {
                "label": "5",
                "value": 5
            }, {
                "label": "6",
                "value": 6
            }, {
                "label": "8",
                "value": 8
            }]
            value: ShellSettings.workspaceCount
            onChosen: (value) => {
                return ShellSettings.workspaceCount = value;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "title"
            title: "Window title"
            subtitle: checked ? "Visible in bar" : "Hidden from bar"
            checked: ShellSettings.activeWindowEnabled
            onToggled: (checked) => {
                return ShellSettings.activeWindowEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "schedule"
            title: "Clock"
            subtitle: checked ? "Visible in bar" : "Hidden from bar"
            checked: ShellSettings.clockEnabled
            onToggled: (checked) => {
                return ShellSettings.clockEnabled = checked;
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Clock format"
            subtitle: "Choose 24-hour or AM/PM"
            options: [{
                "label": "24-hour",
                "value": "24h"
            }, {
                "label": "12-hour AM/PM",
                "value": "12h"
            }]
            value: ShellSettings.clockFormat
            onChosen: (value) => {
                return ShellSettings.clockFormat = value;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "dashboard"
            title: "Dashboard"
            subtitle: checked ? "Clock opens dashboard" : "Dashboard hidden"
            checked: ShellSettings.dashboardEnabled
            onToggled: (checked) => {
                return ShellSettings.dashboardEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "cloud"
            title: "Weather"
            subtitle: checked ? "Visible in bar" : "Hidden from bar"
            checked: ShellSettings.weatherEnabled
            onToggled: (checked) => {
                return ShellSettings.weatherEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "volume_up"
            title: "Audio"
            subtitle: checked ? "Volume shown" : "Hidden from bar"
            checked: ShellSettings.audioEnabled
            onToggled: (checked) => {
                return ShellSettings.audioEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "wifi"
            title: "Network"
            subtitle: checked ? "Connection shown" : "Hidden from bar"
            checked: ShellSettings.networkEnabled
            onToggled: (checked) => {
                return ShellSettings.networkEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "battery_full"
            title: "Battery"
            subtitle: checked ? "Shown when available" : "Hidden from bar"
            checked: ShellSettings.batteryEnabled
            onToggled: (checked) => {
                return ShellSettings.batteryEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "apps"
            title: "System tray"
            subtitle: checked ? "App indicators shown" : "Hidden from bar"
            checked: ShellSettings.trayEnabled
            onToggled: (checked) => {
                return ShellSettings.trayEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "tune"
            title: "Quick settings"
            subtitle: checked ? "Control button shown" : "Hidden from bar"
            checked: ShellSettings.quickSettingsEnabled
            onToggled: (checked) => {
                return ShellSettings.quickSettingsEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "dock_to_bottom"
            title: "Dock"
            subtitle: checked ? "Visible" : "Hidden"
            checked: ShellSettings.dockEnabled
            onToggled: (checked) => {
                return ShellSettings.dockEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "vertical_align_bottom"
            title: "Intelligent dock hide"
            subtitle: checked ? "Reveal at the bottom edge" : "Dock stays visible"
            checked: ShellSettings.dockAutoHide
            onToggled: (checked) => {
                return ShellSettings.dockAutoHide = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "visibility"
            title: "Passive tray icons"
            subtitle: checked ? "Included in tray" : "Active icons only"
            checked: ShellSettings.showPassiveTrayItems
            onToggled: (checked) => {
                return ShellSettings.showPassiveTrayItems = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "screenshot"
            title: "Capture pill"
            subtitle: checked ? "Available on the desktop" : "Hidden"
            checked: ShellSettings.capturePillEnabled
            onToggled: (checked) => {
                return ShellSettings.capturePillEnabled = checked;
            }
        }

    }

}
