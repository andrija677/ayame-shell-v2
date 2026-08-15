import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../theme"

GlassSurface {
    id: root

    readonly property var upcoming: EventStore.upcomingEvents(30)

    visible: upcoming.length > 0
    implicitHeight: visible ? eventContent.implicitHeight + Theme.space24 : 0
    radius: Theme.radiusLarge
    depth: 1

    ColumnLayout {
        id: eventContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space12
        }
        spacing: Theme.space8

        SectionTitle {
            title: "Upcoming"
            detail: "Next 30 days"
        }

        Repeater {
            model: root.upcoming.slice(0, 4)
            RowLayout {
                id: eventRow
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.space12

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: Theme.radiusMedium
                    color: eventRow.modelData.daysUntil <= eventRow.modelData.reminderDays
                        ? Theme.accent : Theme.accentSoft
                    AppText {
                        anchors.centerIn: parent
                        text: eventRow.modelData.occurrence.getDate()
                        color: eventRow.modelData.daysUntil <= eventRow.modelData.reminderDays
                            ? Theme.onAccent : Theme.onAccentSoft
                        font.family: Theme.numericFontFamily
                        font.weight: Font.Bold
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    AppText {
                        Layout.fillWidth: true
                        text: eventRow.modelData.title
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    AppText {
                        text: eventRow.modelData.daysUntil === 0 ? "Today"
                            : eventRow.modelData.daysUntil === 1 ? "Tomorrow"
                            : "In " + eventRow.modelData.daysUntil + " days"
                        color: Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontSmall
                    }
                }
                AppText {
                    text: Qt.formatDate(eventRow.modelData.occurrence, "d MMM")
                    color: Theme.outline
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
