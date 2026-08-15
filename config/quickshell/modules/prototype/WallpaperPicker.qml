import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

GlassSurface {
    id: root

    property var wallpapers: []
    signal closeRequested()

    function open() { scanner.running = true; }

    radius: Theme.radiusXLarge
    depth: 3

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space20 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText { text: "Wallpaper & colors"; font.pixelSize: Theme.fontTitle; font.weight: Font.Bold }
                AppText { text: "Pick an image and Ayame remixes every surface"; color: Theme.onSurfaceMuted }
            }
            IconButton { icon: "close"; accessibleName: "Close wallpaper picker"; onActivated: root.closeRequested() }
        }

        GlassSurface {
            Layout.fillWidth: true
            implicitHeight: 60
            radius: Theme.radiusLarge
            depth: 1
            RowLayout {
                anchors { fill: parent; margins: Theme.space12 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    AppText {
                        text: WallpaperService.applying ? "Applying wallpaper…"
                            : PaletteService.generating ? "Creating its palette…"
                            : PaletteService.active ? "Wallpaper colors active" : "Ayame palette"
                        font.weight: Font.Bold
                    }
                    AppText {
                        Layout.fillWidth: true
                        text: WallpaperService.error || PaletteService.error
                            || "Generated locally with Matugen"
                        color: WallpaperService.error || PaletteService.error ? Theme.danger : Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }
                AppIcon { icon: PaletteService.active ? "palette" : "image"; backgroundColor: Theme.accentSoft; iconColor: Theme.onAccentSoft; implicitWidth: 38; implicitHeight: 38 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            AppText { text: "Palette style"; color: Theme.onSurfaceMuted; font.weight: Font.Bold }
            Repeater {
                model: ["tonal", "vibrant", "expressive"]
                ActionPill {
                    required property string modelData
                    label: modelData[0].toUpperCase() + modelData.slice(1)
                    checked: ShellSettings.dynamicColorStyle === modelData
                    onActivated: ShellSettings.dynamicColorStyle = modelData
                }
            }
            Item { Layout.fillWidth: true }
        }

        GridView {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 2
            cellHeight: 136
            model: root.wallpapers
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: wallpaperItem
                required property string modelData
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight
                GlassSurface {
                    anchors { fill: parent; rightMargin: Theme.space8; bottomMargin: Theme.space8 }
                    radius: Theme.radiusLarge
                    depth: 1
                    active: ShellSettings.wallpaperPath === wallpaperItem.modelData
                    clip: true
                    Image {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: parent.height - 30
                        source: "file://" + wallpaperItem.modelData
                        sourceSize: Qt.size(280, 180)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    AppText {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space8 }
                        text: wallpaperItem.modelData.substring(wallpaperItem.modelData.lastIndexOf("/") + 1)
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideMiddle
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !WallpaperService.applying
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: WallpaperService.apply(wallpaperItem.modelData)
                    }
                }
            }
            AppText {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: scanner.running ? "Finding wallpapers…" : "No PNG, JPEG, or WebP images found"
                color: Theme.outline
            }
        }
    }

    Process {
        id: scanner
        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/Downloads\" -maxdepth 4 -type f "
            + "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) "
            + "-print 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const clean = text.trim();
                root.wallpapers = clean ? clean.split("\n") : [];
            }
        }
    }
}
