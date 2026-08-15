import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../theme"

GlassSurface {
    id: root

    readonly property date today: new Date()
    property date shownMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: today
    property date pendingMonth: shownMonth
    property int navigationDirection: 1
    property bool editorOpen: false
    property bool yearly: false
    property int reminderDays: 0
    readonly property int mondayOffset: (shownMonth.getDay() + 6) % 7
    readonly property date gridStart: new Date(shownMonth.getFullYear(),
        shownMonth.getMonth(), 1 - mondayOffset)

    function navigateMonth(offset) {
        navigationDirection = offset < 0 ? -1 : 1;
        pendingMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + offset, 1);
        monthTransition.restart();
    }

    function returnToToday() {
        pendingMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        navigationDirection = pendingMonth < shownMonth ? -1
            : pendingMonth > shownMonth ? 1 : 0;
        selectedDate = today;
        monthTransition.restart();
    }

    function openEditor() {
        eventTitle.text = "";
        yearly = false;
        reminderDays = 0;
        editorOpen = true;
        Qt.callLater(() => eventTitle.forceActiveFocus());
    }

    function saveEvent() {
        if (EventStore.addEvent(eventTitle.text, selectedDate, yearly, reminderDays))
            editorOpen = false;
    }

    implicitHeight: calendarContent.implicitHeight + Theme.space32
    radius: Theme.radiusXLarge
    depth: 1
    clip: true

    ColumnLayout {
        id: calendarContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space16
        }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            AppText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.shownMonth, "MMMM yyyy")
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Bold
            }
            IconButton {
                icon: "chevron_left"
                accessibleName: "Previous month"
                onActivated: root.navigateMonth(-1)
            }
            ActionPill {
                label: "Today"
                onActivated: root.returnToToday()
            }
            IconButton {
                icon: "chevron_right"
                accessibleName: "Next month"
                onActivated: root.navigateMonth(1)
            }
        }

        GridLayout {
            id: calendarGrid
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Theme.space4
            columnSpacing: Theme.space4
            transform: Translate { id: monthSlide }

            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                AppText {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    text: modelData
                    color: Theme.outline
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: 42
                Rectangle {
                    id: dayCell
                    required property int index
                    readonly property date cellDate: new Date(root.gridStart.getFullYear(),
                        root.gridStart.getMonth(), root.gridStart.getDate() + index)
                    readonly property bool isToday: cellDate.toDateString()
                        === root.today.toDateString()
                    readonly property bool inMonth: cellDate.getMonth()
                        === root.shownMonth.getMonth()
                    readonly property bool selected: cellDate.toDateString()
                        === root.selectedDate.toDateString()
                    readonly property bool hasEvents: EventStore.eventsForDate(cellDate).length > 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: Theme.radiusPill
                    color: isToday ? Theme.accent
                        : selected ? Theme.accentSoft
                        : dayPointer.containsMouse ? Theme.glassHighest : "transparent"
                    border.width: selected && !isToday ? 1 : 0
                    border.color: Theme.accent

                    AppText {
                        anchors.centerIn: parent
                        text: dayCell.cellDate.getDate()
                        color: dayCell.isToday ? Theme.onAccent
                            : dayCell.inMonth ? Theme.onSurface : Theme.outline
                        font.family: Theme.numericFontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: dayCell.isToday ? Font.Bold : Font.Medium
                    }
                    Rectangle {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 2
                        }
                        visible: dayCell.hasEvents
                        width: 4
                        height: 4
                        radius: 2
                        color: dayCell.isToday ? Theme.onAccent : Theme.accent
                    }
                    MouseArea {
                        id: dayPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedDate = dayCell.cellDate;
                            root.editorOpen = false;
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                    scale: dayPointer.pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.motionQuick } }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.glassStroke
        }

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText {
                    Layout.fillWidth: true
                    text: Qt.formatDate(root.selectedDate, "dddd, d MMMM")
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                AppText {
                    text: EventStore.eventsForDate(root.selectedDate).length === 0
                        ? "No events for this day"
                        : EventStore.eventsForDate(root.selectedDate).length + " event"
                            + (EventStore.eventsForDate(root.selectedDate).length === 1 ? "" : "s")
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
            ActionPill {
                label: root.editorOpen ? "Cancel" : "Add event"
                symbol: root.editorOpen ? "×" : "+"
                primary: !root.editorOpen
                onActivated: {
                    if (root.editorOpen) root.editorOpen = false;
                    else root.openEditor();
                }
            }
        }

        Repeater {
            model: EventStore.eventsForDate(root.selectedDate)
            RowLayout {
                id: eventRow
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.space8
                Rectangle {
                    implicitWidth: 7
                    implicitHeight: 7
                    radius: 4
                    color: Theme.accent
                }
                AppText {
                    Layout.fillWidth: true
                    text: eventRow.modelData.title
                        + (eventRow.modelData.recurrence === "yearly" ? "  •  Yearly" : "")
                    elide: Text.ElideRight
                }
                IconButton {
                    icon: "delete"
                    accessibleName: "Remove event"
                    implicitWidth: 30
                    implicitHeight: 30
                    onActivated: EventStore.removeEvent(eventRow.modelData.id)
                }
            }
        }

        GlassSurface {
            Layout.fillWidth: true
            visible: root.editorOpen
            implicitHeight: visible ? editorContent.implicitHeight + Theme.space24 : 0
            radius: Theme.radiusLarge
            depth: 2
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.96

            ColumnLayout {
                id: editorContent
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Theme.space12
                }
                spacing: Theme.space8
                AppText {
                    text: "New event • " + Qt.formatDate(root.selectedDate, "d MMM yyyy")
                    font.weight: Font.Bold
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Theme.radiusPill
                    color: Theme.glassHighest
                    border.width: 1
                    border.color: eventTitle.activeFocus ? Theme.accent : Theme.glassStroke
                    TextInput {
                        id: eventTitle
                        anchors {
                            fill: parent
                            leftMargin: Theme.space16
                            rightMargin: Theme.space16
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        onAccepted: root.saveEvent()
                        AppText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: parent.text.length === 0
                            text: "Event title"
                            color: Theme.outline
                        }
                    }
                }
                SettingToggleRow {
                    Layout.fillWidth: true
                    icon: "event_repeat"
                    title: "Repeat yearly"
                    subtitle: "For birthdays and anniversaries"
                    checked: root.yearly
                    onToggled: checked => root.yearly = checked
                }
                RowLayout {
                    Layout.fillWidth: true
                    AppText { text: "Remind me"; color: Theme.onSurfaceMuted }
                    Repeater {
                        model: [
                            { label: "Same day", value: 0 },
                            { label: "1 day", value: 1 },
                            { label: "1 week", value: 7 }
                        ]
                        ActionPill {
                            required property var modelData
                            label: modelData.label
                            checked: root.reminderDays === modelData.value
                            onActivated: root.reminderDays = modelData.value
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ActionPill {
                        label: "Save"
                        primary: true
                        enabled: eventTitle.text.trim().length > 0
                        onActivated: root.saveEvent()
                    }
                }
            }

            Behavior on implicitHeight { NumberAnimation { duration: Theme.motionResponsive } }
            Behavior on opacity { NumberAnimation { duration: Theme.motionQuick } }
            Behavior on scale { NumberAnimation { duration: Theme.motionResponsive } }
        }
    }

    SequentialAnimation {
        id: monthTransition
        ParallelAnimation {
            NumberAnimation {
                target: monthSlide
                property: "x"
                to: -root.navigationDirection * 46
                duration: Theme.motionQuick
                easing.type: Theme.easeExit
            }
            NumberAnimation {
                target: calendarGrid
                property: "opacity"
                to: 0
                duration: Theme.motionQuick
            }
        }
        ScriptAction { script: root.shownMonth = root.pendingMonth }
        PropertyAction {
            target: monthSlide
            property: "x"
            value: root.navigationDirection * 46
        }
        ParallelAnimation {
            NumberAnimation {
                target: monthSlide
                property: "x"
                to: 0
                duration: Theme.motionResponsive
                easing.type: Theme.easeEnter
            }
            NumberAnimation {
                target: calendarGrid
                property: "opacity"
                to: 1
                duration: Theme.motionResponsive
            }
        }
    }
}
