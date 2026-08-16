import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

Flickable {
    id: root

    signal backRequested()

    property int titleClicks: 0
    property int titleTeaseStage: 0
    property string titleTeaseText: ""

    readonly property var titleTeases: [
        "Nyaah, stop clicking me!",
        "Owie, that hurts—stop it >:(",
        "You really are curious, huh? :3",
        "The Keybinds title is not a button…",
        "Still clicking? I admire the dedication.",
        "Okay, you win. Have a tiny headpat ♡",
        "No more secrets here—promise!",
        "*purrs* Mmh, keep petting me—or, in this situation, clicking me."
    ]
    readonly property var groups: [
        {
            title: "Shell & Apps",
            entries: [
                { keys: "SUPER", action: "Open application launcher" },
                { keys: "SUPER + ENTER", action: "Open terminal" },
                { keys: "SUPER + .", action: "Open emoji picker" }
            ]
        },
        {
            title: "Windows",
            entries: [
                { keys: "SUPER + Q", action: "Close active window" },
                { keys: "SUPER + F", action: "Toggle fullscreen" },
                { keys: "SUPER + SHIFT + F", action: "Toggle floating" },
                { keys: "SUPER + DRAG", action: "Move or resize window" }
            ]
        },
        {
            title: "Workspaces",
            entries: [
                { keys: "SUPER + 1…5", action: "Switch workspace" },
                { keys: "SUPER + SHIFT + 1…5", action: "Move window" }
            ]
        },
        {
            title: "Quick Capture",
            entries: [
                { keys: "PRINT", action: "Capture desktop" },
                { keys: "SHIFT + PRINT", action: "Select an area" },
                { keys: "SUPER + PRINT", action: "Capture monitor" },
                { keys: "SUPER + SHIFT + R", action: "Toggle recording" }
            ]
        }
    ]

    function teaseTitle() {
        titleClicks++;
        if (titleClicks < 7)
            return;

        titleClicks = 0;
        titleTeaseText = titleTeases[Math.min(titleTeaseStage, titleTeases.length - 1)];
        titleTeaseStage = Math.min(titleTeaseStage + 1, titleTeases.length - 1);
        titleTeaseTimer.restart();
    }

    function resetTitleTease() {
        titleClicks = 0;
        titleTeaseStage = 0;
        titleTeaseText = "";
        titleTeaseTimer.stop();
    }

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    onVisibleChanged: if (!visible) resetTitleTease()

    Timer {
        id: titleTeaseTimer
        interval: 4000
        onTriggered: root.titleTeaseText = ""
    }

    ColumnLayout {
        id: content
        width: root.width
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true

            IconButton {
                icon: "arrow_back"
                accessibleName: "Back"
                onActivated: root.backRequested()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                AppText {
                    Layout.fillWidth: true
                    text: "Keybinds"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold

                    MouseArea {
                        anchors {
                            fill: parent
                            margins: -Theme.space4
                        }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.teaseTitle()
                    }
                }

                AppText {
                    text: "Ayame and Hyprland shortcuts"
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        GlassSurface {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - Theme.space24
            implicitWidth: Math.min(root.width - Theme.space24,
                titleTeaseLabel.implicitWidth + Theme.space32)
            implicitHeight: titleTeaseLabel.implicitHeight + Theme.space16
            radius: Theme.radiusPill
            active: true
            visible: opacity > 0
            opacity: root.titleTeaseText.length > 0 ? 1 : 0
            scale: root.titleTeaseText.length > 0 ? 1 : 0.88

            Behavior on opacity {
                NumberAnimation { duration: Theme.motionResponsive }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.motionResponsive
                    easing.type: Theme.easeEnter
                }
            }

            AppText {
                id: titleTeaseLabel
                anchors {
                    fill: parent
                    leftMargin: Theme.space16
                    rightMargin: Theme.space16
                }
                text: root.titleTeaseText
                color: Theme.onAccentSoft
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: root.groups

            GlassSurface {
                id: groupCard
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: groupContent.implicitHeight + Theme.space24
                radius: Theme.radiusLarge
                depth: 1

                ColumnLayout {
                    id: groupContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.space12
                    }
                    spacing: Theme.space8

                    SectionTitle { title: groupCard.modelData.title }

                    Repeater {
                        model: groupCard.modelData.entries

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true

                            AppText {
                                text: modelData.keys
                                color: Theme.accent
                                font.family: Theme.numericFontFamily
                                font.weight: Font.Bold
                            }

                            Item { Layout.fillWidth: true }

                            AppText {
                                text: modelData.action
                                color: Theme.onSurfaceMuted
                            }
                        }
                    }
                }
            }
        }
    }
}
