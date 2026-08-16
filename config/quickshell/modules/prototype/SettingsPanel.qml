import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"
import "../settings"

GlassSurface {
    id: root
    property int currentPage: 0
    property bool wallpaperPickerOpen: false
    signal closeRequested()

    readonly property var pages: [
        { icon:"palette", title:"Appearance", description:"Color, wallpaper, glass and motion" },
        { icon:"view_quilt", title:"Interface", description:"Bar, dock, modules and density" },
        { icon:"hub", title:"Services", description:"Notifications, clipboard and weather" },
        { icon:"devices", title:"System", description:"Night light, idle, health and updates" },
        { icon:"auto_awesome", title:"Ayame AI", description:"Provider, personality and secure keys" }
    ]

    radius: Theme.radiusXLarge
    depth: 2

    RowLayout {
        anchors { fill: parent; margins: Theme.space16 }
        spacing: Theme.space16

        GlassSurface {
            Layout.preferredWidth: 224
            Layout.fillHeight: true
            radius: Theme.radiusLarge
            depth: 1
            ColumnLayout {
                anchors { fill: parent; margins: Theme.space16 }
                spacing: Theme.space8
                RowLayout {
                    Layout.fillWidth: true
                    AppIcon { icon:"auto_awesome"; backgroundColor:Theme.accent; iconColor:Theme.onAccent; implicitWidth:44; implicitHeight:44 }
                    ColumnLayout { Layout.fillWidth:true; spacing:0; AppText{text:"Ayame";font.weight:Font.ExtraBold}AppText{text:"Settings";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall} }
                }
                Item { implicitHeight:Theme.space12 }
                Repeater {
                    model:root.pages
                    Rectangle {
                        id:navRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth:true; implicitHeight:54; radius:Theme.radiusMedium
                        color:root.currentPage===index?Theme.accentSoft:navMouse.containsMouse?Theme.glassHighest:"transparent"
                        RowLayout { anchors{fill:parent;leftMargin:Theme.space12;rightMargin:Theme.space12}spacing:Theme.space12;AppIcon{icon:navRow.modelData.icon;implicitWidth:28;implicitHeight:28;iconSize:19;iconColor:root.currentPage===navRow.index?Theme.onAccentSoft:Theme.onSurfaceMuted}ColumnLayout{Layout.fillWidth:true;spacing:0;AppText{text:navRow.modelData.title;color:root.currentPage===navRow.index?Theme.onAccentSoft:Theme.onSurface;font.weight:root.currentPage===navRow.index?Font.Bold:Font.Medium}AppText{Layout.fillWidth:true;text:navRow.modelData.description;color:Theme.onSurfaceMuted;font.pixelSize:9;elide:Text.ElideRight}} }
                        MouseArea{id:navMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.currentPage=navRow.index}
                        Behavior on color{ColorAnimation{duration:Theme.motionQuick}}
                    }
                }
                Item { Layout.fillHeight:true }
                AppText { Layout.fillWidth:true; text:"Ayame Shell V2\nAll controls use live backends"; color:Theme.outline; font.pixelSize:Theme.fontSmall; wrapMode:Text.WordWrap }
            }
        }

        ColumnLayout {
            Layout.fillWidth:true
            Layout.fillHeight:true
            spacing:Theme.space16
            Item {
                Layout.fillWidth: true
                implicitHeight: 54

                ColumnLayout {
                    anchors {
                        left: parent.left
                        right: settingsClose.left
                        verticalCenter: parent.verticalCenter
                        rightMargin: Theme.space12
                    }
                    spacing: 2

                    AppText {
                        Layout.fillWidth: true
                        text: root.pages[root.currentPage].title
                        font.pixelSize: Theme.fontDisplay
                        font.weight: Font.ExtraBold
                    }

                    AppText {
                        Layout.fillWidth: true
                        text: root.pages[root.currentPage].description
                        color: Theme.onSurfaceMuted
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    id: settingsClose
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    icon: "close"
                    accessibleName: "Close Settings"
                    onActivated: root.closeRequested()
                }
            }
            StackLayout {
                Layout.fillWidth:true
                Layout.fillHeight:true
                currentIndex:root.currentPage
                AppearancePage { onWallpaperRequested:{root.wallpaperPickerOpen=true;wallpaperPicker.open();} }
                InterfacePage {}
                ServicesPage { onAiConfigureRequested:root.currentPage=4 }
                SystemPage {}
                AiSettingsPage {}
            }
        }
    }

    WallpaperPicker {
        id:wallpaperPicker
        anchors.fill:parent
        z:30
        visible:root.wallpaperPickerOpen
        enabled:visible
        opacity:visible?1:0
        onCloseRequested:root.wallpaperPickerOpen=false
        Behavior on opacity{NumberAnimation{duration:Theme.motionQuick}}
    }
}
