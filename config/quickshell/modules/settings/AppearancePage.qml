import "../../components"
import "../../services"
import "../../settings"
import "../../theme"
import QtQuick
import QtQuick.Layouts

Flickable {
    id: root

    signal wallpaperRequested()

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: content

        width: root.width
        spacing: Theme.space12

        GlassSurface {
            Layout.fillWidth: true
            implicitHeight: 112
            radius: Theme.radiusXLarge
            depth: 1

            RowLayout {
                spacing: Theme.space16

                anchors {
                    fill: parent
                    margins: Theme.space16
                }

                AppIcon {
                    icon: "palette"
                    backgroundColor: Theme.accent
                    iconColor: Theme.onAccent
                    implicitWidth: 56
                    implicitHeight: 56
                    iconSize: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    AppText {
                        text: "Wallpaper-powered color"
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                    }

                    AppText {
                        text: PaletteService.generating ? "Creating a fresh palette…" : PaletteService.active ? "Every surface follows your wallpaper" : "Ayame’s fallback palette is active"
                        color: Theme.onSurfaceMuted
                    }

                }

                ActionPill {
                    label: "Wallpaper & colors"
                    symbol: "▧"
                    primary: true
                    onActivated: root.wallpaperRequested()
                }

            }

        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Color scheme"
            subtitle: "Automatic follows wallpaper brightness"
            options: [{
                "label": "Automatic",
                "value": "automatic"
            }, {
                "label": "Dark",
                "value": "dark"
            }, {
                "label": "Light",
                "value": "light"
            }]
            value: ShellSettings.appearanceMode
            onChosen: (value) => {
                return ShellSettings.appearanceMode = value;
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Palette style"
            subtitle: "Change the character without losing wallpaper matching"
            options: [{
                "label": "Tonal",
                "value": "tonal"
            }, {
                "label": "Vibrant",
                "value": "vibrant"
            }, {
                "label": "Expressive",
                "value": "expressive"
            }]
            value: ShellSettings.dynamicColorStyle
            onChosen: (value) => {
                return ShellSettings.dynamicColorStyle = value;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "colorize"
            title: "Wallpaper colors"
            subtitle: checked ? "Dynamic palette enabled" : "Use Ayame’s fallback palette"
            checked: ShellSettings.dynamicColorsEnabled
            onToggled: (checked) => {
                return ShellSettings.dynamicColorsEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "format_color_fill"
            title: "Wallpaper tint"
            subtitle: checked ? "Color-rich glass surfaces" : "Neutral glass surfaces"
            checked: ShellSettings.surfaceTint > 0
            onToggled: (checked) => {
                return ShellSettings.surfaceTint = checked ? 0.18 : 0;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "blur_on"
            title: "Background blur"
            subtitle: checked ? "Translucent glass" : "Solid surfaces"
            checked: ShellSettings.glassBlur
            onToggled: (checked) => {
                return ShellSettings.glassBlur = checked;
            }
        }

        SettingSliderRow {
            Layout.fillWidth: true
            title: "Glass opacity"
            subtitle: "Balance wallpaper visibility and readability"
            from: 0.42
            to: 0.96
            value: ShellSettings.glassOpacity
            valueText: Math.round(value * 100) + "%"
            onMoved: (value) => {
                return ShellSettings.glassOpacity = value;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "motion_photos_on"
            title: "Animations"
            subtitle: checked ? "Expressive motion" : "Motion disabled"
            checked: ShellSettings.motionEnabled
            onToggled: (checked) => {
                return ShellSettings.motionEnabled = checked;
            }
        }

        SettingToggleRow {
            Layout.fillWidth: true
            icon: "speed"
            title: "Reduced motion"
            subtitle: checked ? "Faster, calmer transitions" : "Full movement"
            checked: ShellSettings.reducedMotion
            onToggled: (checked) => {
                return ShellSettings.reducedMotion = checked;
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Layout density"
            subtitle: "Choose comfortable or compact spacing"
            options: [{
                "label": "Comfortable",
                "value": "comfortable"
            }, {
                "label": "Compact",
                "value": "compact"
            }]
            value: ShellSettings.densityMode
            onChosen: (value) => {
                return ShellSettings.densityMode = value;
            }
        }

    }

}
