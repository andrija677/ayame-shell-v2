import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

GlassSurface {
    id: root

    property int currentPage: 0
    signal closeRequested()

    radius: Theme.radiusXLarge
    depth: 2

    RowLayout {
        anchors { fill: parent; margins: Theme.space16 }
        spacing: Theme.space16

        GlassSurface {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            radius: Theme.radiusLarge
            depth: 1

            ColumnLayout {
                anchors { fill: parent; margins: Theme.space16 }
                spacing: Theme.space8

                RowLayout {
                    Layout.fillWidth: true
                    AppIcon {
                        icon: "auto_awesome"
                        backgroundColor: Theme.accent
                        iconColor: Theme.onAccent
                        implicitWidth: 42
                        implicitHeight: 42
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        AppText { text: "Ayame"; font.weight: Font.ExtraBold }
                        AppText { text: "Settings"; color: Theme.onSurfaceMuted; font.pixelSize: Theme.fontSmall }
                    }
                }

                Item { implicitHeight: Theme.space12 }

                Repeater {
                    model: [
                        { icon: "palette", title: "Appearance" },
                        { icon: "view_quilt", title: "Shell layout" },
                        { icon: "motion_photos_on", title: "Motion" },
                        { icon: "devices", title: "Hardware" },
                        { icon: "auto_awesome", title: "Ayame AI" }
                    ]
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: Theme.radiusMedium
                        color: root.currentPage === index ? Theme.accentSoft
                            : navPointer.containsMouse ? Theme.glassHighest : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                            AppIcon {
                                icon: parent.parent.modelData.icon
                                implicitWidth: 28
                                implicitHeight: 28
                                iconSize: 19
                                iconColor: root.currentPage === parent.parent.index
                                    ? Theme.onAccentSoft : Theme.onSurfaceMuted
                            }
                            AppText {
                                Layout.fillWidth: true
                                text: parent.parent.modelData.title
                                color: root.currentPage === parent.parent.index
                                    ? Theme.onAccentSoft : Theme.onSurface
                                font.weight: root.currentPage === parent.parent.index ? Font.Bold : Font.Medium
                            }
                        }

                        MouseArea {
                            id: navPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = parent.index
                        }
                    }
                }

                Item { Layout.fillHeight: true }
                AppText {
                    Layout.fillWidth: true
                    text: "V2 design laboratory\nNothing here changes V1"
                    color: Theme.outline
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors { fill: parent; margins: Theme.space12 }
                spacing: Theme.space16

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        AppText {
                            text: ["Appearance", "Shell layout", "Motion", "Hardware", "Ayame AI"][root.currentPage]
                            font.pixelSize: Theme.fontDisplay
                            font.weight: Font.ExtraBold
                        }
                        AppText {
                            text: [
                                "Let the wallpaper set the mood—or tune it yourself.",
                                "Choose what belongs in your everyday space.",
                                "Movement with character, always under your control.",
                                "Capabilities appear when your system supports them.",
                                "Choose how your desktop companion thinks and speaks."
                            ][root.currentPage]
                            color: Theme.onSurfaceMuted
                        }
                    }
                    IconButton {
                        icon: "close"
                        accessibleName: "Close Settings"
                        onActivated: root.closeRequested()
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: settingsContent.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: settingsContent
                        width: parent.width
                        spacing: Theme.space12

                        GlassSurface {
                            Layout.fillWidth: true
                            implicitHeight: root.currentPage === 0 ? 164
                                : root.currentPage === 4 ? 178 : 116
                            radius: Theme.radiusLarge
                            depth: 1

                            ColumnLayout {
                                anchors { fill: parent; margins: Theme.space16 }
                                spacing: Theme.space12
                                SectionTitle {
                                    Layout.fillWidth: true
                                    title: root.currentPage === 0 ? "Color and light"
                                        : root.currentPage === 1 ? "Desktop pieces"
                                        : root.currentPage === 2 ? "Motion character"
                                        : root.currentPage === 3 ? "Detected capabilities"
                                        : "Provider and personality"
                                    detail: root.currentPage === 0 && PaletteService.active
                                        ? "Wallpaper palette active" : ""
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.space8
                                    visible: root.currentPage === 0
                                    Repeater {
                                        model: ["automatic", "light", "dark"]
                                        ActionPill {
                                            required property string modelData
                                            label: modelData[0].toUpperCase() + modelData.slice(1)
                                            checked: ShellSettings.appearanceMode === modelData
                                            onActivated: ShellSettings.appearanceMode = modelData
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Repeater {
                                        model: [Theme.accent, Theme.secondary, Theme.tertiary]
                                        Rectangle {
                                            required property color modelData
                                            width: 28; height: 28; radius: 14; color: modelData
                                            border.width: 1; border.color: Theme.glassStroke
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: root.currentPage === 4
                                    spacing: Theme.space8
                                    Repeater {
                                        model: ["gemini", "openai", "ollama"]
                                        ActionPill {
                                            required property string modelData
                                            label: modelData === "openai" ? "OpenAI" : modelData[0].toUpperCase() + modelData.slice(1)
                                            checked: ShellSettings.aiProvider === modelData
                                            onActivated: {
                                                ShellSettings.aiProvider = modelData;
                                                if (modelData === "gemini") ShellSettings.aiModel = "gemini-2.5-flash";
                                                else if (modelData === "openai") ShellSettings.aiModel = "gpt-4.1-mini";
                                                else ShellSettings.aiModel = "llama3.2";
                                            }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: root.currentPage === 4
                                    spacing: Theme.space8
                                    AppText { text: "Personality"; color: Theme.onSurfaceMuted }
                                    Repeater {
                                        model: ["assistant", "cat", "fox"]
                                        ActionPill {
                                            required property string modelData
                                            label: modelData[0].toUpperCase() + modelData.slice(1)
                                            checked: ShellSettings.aiPersonality === modelData
                                            onActivated: ShellSettings.aiPersonality = modelData
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: root.currentPage !== 0
                                    AppText {
                                        Layout.fillWidth: true
                                        text: root.currentPage === 1 ? "Top bar, dock, and screenshot pill"
                                            : root.currentPage === 2 ? "Expressive transitions"
                                            : "Wi-Fi • Bluetooth • Audio • Display"
                                        color: Theme.onSurfaceMuted
                                    }
                                    AppIcon {
                                        icon: root.currentPage === 3 ? "check_circle" : "auto_awesome"
                                        iconColor: Theme.success
                                        implicitWidth: 32; implicitHeight: 32; iconSize: 24
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: root.currentPage === 0 ? [
                                { title: "Wallpaper colors", subtitle: "Adapt every surface together", key: "colors" },
                                { title: "Glass blur", subtitle: "Soften what moves underneath", key: "blur" },
                                { title: "Surface tint", subtitle: "Let the wallpaper color breathe through", key: "tint" }
                            ] : root.currentPage === 1 ? [
                                { title: "Floating top bar", subtitle: "Three calm, independent islands", key: "demo" },
                                { title: "Auto-hide dock", subtitle: "Slides away and springs back when you arrive", key: "dockAutoHide" },
                                { title: "Capture pill", subtitle: "Snaps away when you are finished", key: "demo" }
                            ] : root.currentPage === 2 ? [
                                { title: "Animations", subtitle: "Responsive and expressive", key: "motion" },
                                { title: "Reduced motion", subtitle: "Available without losing clarity", key: "demo" },
                                { title: "Playfulness", subtitle: "Warm, never distracting", key: "demo" }
                            ] : root.currentPage === 3 ? [
                                { title: "Network", subtitle: "NetworkManager available", key: "demo" },
                                { title: "Bluetooth", subtitle: "BlueZ capability detected", key: "demo" },
                                { title: "Audio", subtitle: "PipeWire capability detected", key: "demo" }
                            ] : [
                                { title: "Ayame AI", subtitle: "Show the companion in the dock", key: "aiEnabled" },
                                { title: "Model", subtitle: ShellSettings.aiModel, key: "demo" },
                                { title: "Secure API keys", subtitle: "Reuses your protected Ayame V1 keyring entries", key: "demo" }
                            ]

                            GlassSurface {
                                id: settingRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 74
                                radius: Theme.radiusLarge
                                depth: 1

                                RowLayout {
                                    anchors { fill: parent; margins: Theme.space16 }
                                    spacing: Theme.space12
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        AppText { text: settingRow.modelData.title; font.weight: Font.Bold }
                                        AppText {
                                            text: settingRow.modelData.subtitle
                                            color: Theme.onSurfaceMuted
                                            font.pixelSize: Theme.fontSmall
                                        }
                                    }
                                    ToggleSwitch {
                                        accessibleName: settingRow.modelData.title
                                        checked: settingRow.modelData.key === "colors"
                                            ? ShellSettings.dynamicColorsEnabled
                                            : settingRow.modelData.key === "blur"
                                                ? ShellSettings.glassBlur
                                                : settingRow.modelData.key === "motion"
                                                    ? ShellSettings.motionEnabled
                                                    : settingRow.modelData.key === "dockAutoHide"
                                                        ? ShellSettings.dockAutoHide
                                                        : settingRow.modelData.key === "aiEnabled"
                                                            ? ShellSettings.aiEnabled : true
                                        enabled: settingRow.modelData.key !== "demo"
                                            && settingRow.modelData.key !== "tint"
                                        onToggled: checked => {
                                            const key = settingRow.modelData.key;
                                            if (key === "colors") ShellSettings.dynamicColorsEnabled = checked;
                                            else if (key === "blur") ShellSettings.glassBlur = checked;
                                            else if (key === "motion") ShellSettings.motionEnabled = checked;
                                            else if (key === "dockAutoHide") ShellSettings.dockAutoHide = checked;
                                            else if (key === "aiEnabled") ShellSettings.aiEnabled = checked;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
