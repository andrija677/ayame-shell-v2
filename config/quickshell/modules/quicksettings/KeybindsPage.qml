import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

Flickable {
    id: root

    signal backRequested()
    signal titleTeased(string message)

    property int titleClicks: 0
    property int titleTeaseStage: 0

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
        const message = titleTeases[Math.min(titleTeaseStage, titleTeases.length - 1)];
        titleTeaseStage = Math.min(titleTeaseStage + 1, titleTeases.length - 1);
        titleTeased(message);
    }

    function resetTitleTease() {
        titleClicks = 0;
        titleTeaseStage = 0;
    }

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    onVisibleChanged: if (!visible) resetTitleTease()

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

            Item {
                Layout.fillWidth: true
                implicitHeight: titleContent.implicitHeight

                ColumnLayout {
                    id: titleContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 0

                    AppText {
                        Layout.fillWidth: true
                        text: "Keybinds"
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                    }

                    AppText {
                        text: "Ayame and Hyprland shortcuts"
                        color: Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontSmall
                    }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.teaseTitle()
                }
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
