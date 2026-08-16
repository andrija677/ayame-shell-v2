import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

GlassSurface {
    id: root

    signal closeRequested()
    property date currentTime: new Date()

    radius: Theme.radiusXLarge
    depth: 2
    clip: true

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space16 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            AppIcon {
                icon: "calendar_month"
                backgroundColor: Theme.accent
                iconColor: Theme.onAccent
                implicitWidth: 44
                implicitHeight: 44
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText {
                    text: Qt.formatDate(root.currentTime, "dddd, d MMMM")
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.ExtraBold
                }
                AppText {
                    text: Qt.formatTime(root.currentTime,
                        ShellSettings.clockFormat === "12h" ? "h:mm AP" : "HH:mm")
                    color: Theme.onSurfaceMuted
                    font.family: Theme.numericFontFamily
                    font.weight: Font.Bold
                }
            }
            IconButton {
                icon: "close"
                accessibleName: "Close dashboard"
                onActivated: root.closeRequested()
            }
        }

        Flickable {
            id: dashboardScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: dashboardContent.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: dashboardContent
                width: dashboardScroll.width
                spacing: Theme.space12

                MediaCard { Layout.fillWidth: true }

                GlassSurface {
                    Layout.fillWidth: true
                    visible: WeatherService.configured
                    implicitHeight: visible ? weatherContent.implicitHeight + Theme.space24 : 0
                    radius: Theme.radiusLarge
                    depth: 1
                    ColumnLayout {
                        id: weatherContent
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: Theme.space12
                        }
                        spacing: Theme.space8
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                AppText {
                                    Layout.fillWidth: true
                                    text: ShellSettings.weatherLocationName
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                AppText {
                                    text: WeatherService.hasData
                                        ? WeatherService.weatherLabel(
                                            WeatherService.forecast.current.weather_code)
                                        : WeatherService.loading ? "Updating forecast…"
                                        : WeatherService.error || "Waiting for weather"
                                    color: Theme.onSurfaceMuted
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                            AppText {
                                text: WeatherService.hasData
                                    ? Math.round(WeatherService.forecast.current.temperature_2m)
                                        + (ShellSettings.weatherTemperatureUnit === "celsius" ? "°C" : "°F")
                                    : "--°"
                                font.family: Theme.numericFontFamily
                                font.pixelSize: Theme.fontDisplay
                                font.weight: Font.Bold
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            visible: WeatherService.hasData
                            AppText {
                                text: "Feels " + Math.round(
                                    WeatherService.forecast?.current?.apparent_temperature ?? 0) + "°"
                                color: Theme.onSurfaceMuted
                                font.pixelSize: Theme.fontSmall
                            }
                            AppText {
                                text: "Wind " + Math.round(
                                    WeatherService.forecast?.current?.wind_speed_10m ?? 0) + " "
                                    + (WeatherService.forecast?.current_units?.wind_speed_10m || "km/h")
                                color: Theme.onSurfaceMuted
                                font.pixelSize: Theme.fontSmall
                            }
                            Item { Layout.fillWidth: true }
                            ActionPill {
                                label: "Refresh"
                                enabled: !WeatherService.loading
                                onActivated: WeatherService.refresh()
                            }
                        }
                    }
                }

                CalendarCard { Layout.fillWidth: true }
                UpcomingEventsCard { Layout.fillWidth: true }

                GlassSurface {
                    Layout.fillWidth: true
                    implicitHeight: notificationContent.implicitHeight + Theme.space24
                    radius: Theme.radiusLarge
                    depth: 1
                    ColumnLayout {
                        id: notificationContent
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: Theme.space12
                        }
                        spacing: Theme.space8
                        RowLayout {
                            Layout.fillWidth: true
                            SectionTitle {
                                Layout.fillWidth: true
                                title: "Notification center"
                                detail: NotificationService.count + " saved"
                            }
                            RowLayout {
                                spacing: Theme.space8

                                AppText {
                                    text: ShellSettings.doNotDisturb
                                        ? "Notifications muted" : "Mute notifications"
                                    color: ShellSettings.doNotDisturb
                                        ? Theme.accent : Theme.onSurfaceMuted
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.DemiBold
                                }

                                ToggleSwitch {
                                    accessibleName: "Mute notifications"
                                    checked: ShellSettings.doNotDisturb
                                    onToggled: checked => ShellSettings.doNotDisturb = checked
                                }
                            }
                            ActionPill {
                                label: "Clear"
                                visible: NotificationService.count > 0
                                onActivated: NotificationService.clearAll()
                            }
                        }
                        AppText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            visible: NotificationService.count === 0
                            text: ShellSettings.doNotDisturb
                                ? "Peace and quiet" : "You’re all caught up"
                            color: Theme.onSurfaceMuted
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Repeater {
                            model: NotificationService.history.slice().reverse().slice(0, 3)
                            RowLayout {
                                id: notificationRow
                                required property var modelData
                                Layout.fillWidth: true
                                AppIcon {
                                    icon: "notifications"
                                    backgroundColor: Theme.accentSoft
                                    iconColor: Theme.onAccentSoft
                                    implicitWidth: 34
                                    implicitHeight: 34
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    AppText {
                                        Layout.fillWidth: true
                                        text: notificationRow.modelData.summary
                                            || notificationRow.modelData.appName || "Notification"
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                    AppText {
                                        Layout.fillWidth: true
                                        text: NotificationService.displayBody(
                                            notificationRow.modelData)
                                        color: Theme.onSurfaceMuted
                                        font.pixelSize: Theme.fontSmall
                                        elide: Text.ElideRight
                                    }
                                }
                                IconButton {
                                    icon: "close"
                                    accessibleName: "Dismiss notification"
                                    onActivated: NotificationService.dismiss(
                                        notificationRow.modelData.id)
                                }
                            }
                        }
                    }
                }
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
