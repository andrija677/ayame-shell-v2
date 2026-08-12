import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../settings"
import "../../services"
import "../../theme"

FloatingWindow {
    id: root

    property bool livelyMotion: true
    property bool wifiDemoEnabled: true
    property bool bluetoothDemoEnabled: false

    title: "Ayame Shell V2 — Design Preview"
    implicitWidth: 820
    implicitHeight: 540
    minimumSize: Qt.size(680, 480)
    color: Theme.background
    visible: ShellSettings.previewVisible

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: -100
                topMargin: -130
            }
            width: 440
            height: 440
            radius: 220
            color: Theme.alpha(Theme.accent, 0.12)
        }

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: Theme.space32
            }
            spacing: Theme.space20

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space4
                    AppText {
                        text: "Ayame Shell V2"
                        font.pixelSize: Theme.fontDisplay
                        font.weight: Font.ExtraBold
                    }
                    AppText {
                        text: "A separate, safe design laboratory"
                        color: Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontBody
                    }
                }

                ActionPill {
                    label: ShellSettings.appearanceMode === "automatic"
                        ? "Auto " + (Theme.light ? "light" : "dark")
                        : ShellSettings.appearanceMode[0].toUpperCase()
                            + ShellSettings.appearanceMode.slice(1)
                    symbol: ShellSettings.appearanceMode === "automatic" ? "◐"
                        : Theme.light ? "☀" : "☾"
                    onActivated: {
                        const modes = ["automatic", "light", "dark"];
                        const index = modes.indexOf(ShellSettings.appearanceMode);
                        ShellSettings.appearanceMode = modes[(index + 1) % modes.length];
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                Layout.minimumHeight: 250
                Layout.maximumHeight: 250
                columns: 2
                rowSpacing: Theme.space16
                columnSpacing: Theme.space16

                GlassSurface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    depth: 1

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.space20 }
                        spacing: Theme.space12
                        AppText {
                            text: "Semantic glass"
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Bold
                        }
                        AppText {
                            Layout.fillWidth: true
                            text: PaletteService.active
                                ? "Live colors from your current wallpaper flow through every semantic role."
                                : "Depth, tint, contrast, and motion are system roles—not colors copied into components."
                            color: Theme.onSurfaceMuted
                            wrapMode: Text.WordWrap
                        }
                        Row {
                            spacing: Theme.space8
                            Repeater {
                                model: [Theme.accent, Theme.accentSoft,
                                    Theme.surfaceRaisedBase, Theme.background]
                                Rectangle {
                                    required property color modelData
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.glassStroke
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            spacing: Theme.space8
                            ActionPill {
                                label: "Quiet"
                                checked: !root.livelyMotion
                                onActivated: root.livelyMotion = false
                            }
                            ActionPill {
                                label: "Alive"
                                checked: root.livelyMotion
                                onActivated: root.livelyMotion = true
                            }
                        }
                    }
                }

                GlassSurface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    depth: 2

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.space20 }
                        spacing: Theme.space12
                        AppText {
                            text: "Preview-safe"
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Bold
                        }
                        AppText {
                            Layout.fillWidth: true
                            text: "This window owns no bar edge, notifications, wallpaper, shortcuts, or session controls. V1 stays in charge."
                            color: Theme.onSurfaceMuted
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            spacing: Theme.space8
                            ActionPill {
                                label: "Wi-Fi"
                                symbol: "◉"
                                checked: root.wifiDemoEnabled
                                onActivated: root.wifiDemoEnabled = !root.wifiDemoEnabled
                            }
                            ActionPill {
                                label: "Bluetooth"
                                symbol: "B"
                                checked: root.bluetoothDemoEnabled
                                onActivated: root.bluetoothDemoEnabled = !root.bluetoothDemoEnabled
                            }
                        }
                        Item { Layout.fillHeight: true }
                        GlassSurface {
                            Layout.fillWidth: true
                            implicitHeight: 72
                            active: true
                            radius: Theme.radiusMedium
                            RowLayout {
                                anchors { fill: parent; margins: Theme.space16 }
                                spacing: Theme.space12
                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: Theme.radiusMedium
                                    color: Theme.accent
                                    AppText {
                                        anchors.centerIn: parent
                                        text: "A"
                                        color: Theme.onAccent
                                        font.weight: Font.ExtraBold
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    AppText { text: "V2 runtime isolated"; font.weight: Font.Bold }
                                    AppText {
                                        text: PaletteService.generating
                                            ? "Generating wallpaper palette…"
                                            : PaletteService.error.length > 0
                                                ? PaletteService.error
                                                : PaletteService.active
                                                    ? "Wallpaper palette active"
                                                    : Quickshell.dataDir
                                        color: Theme.onAccentSoft
                                        font.pixelSize: Theme.fontSmall
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            AppText {
                Layout.fillWidth: true
                text: "Foundation preview • no desktop ownership"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.outline
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
