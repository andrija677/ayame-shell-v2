pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property alias appearanceMode: values.appearanceMode
    property alias dynamicColorsEnabled: values.dynamicColorsEnabled
    property alias dynamicColorStyle: values.dynamicColorStyle
    property alias wallpaperPath: values.wallpaperPath
    property alias glassOpacity: values.glassOpacity
    property alias glassBlur: values.glassBlur
    property alias surfaceTint: values.surfaceTint
    property alias motionEnabled: values.motionEnabled
    property alias motionScale: values.motionScale
    property alias cornerScale: values.cornerScale
    property alias dockAutoHide: values.dockAutoHide
    property alias aiEnabled: values.aiEnabled
    property alias aiProvider: values.aiProvider
    property alias aiModel: values.aiModel
    property alias aiBaseUrl: values.aiBaseUrl
    property alias aiPersonality: values.aiPersonality
    property alias previewVisible: values.previewVisible

    function save() {
        saveTimer.restart();
    }

    property Timer saveTimer: Timer {
        interval: 160
        onTriggered: settingsFile.writeAdapter()
    }

    property FileView settingsFile: FileView {
        id: settingsFile
        path: Quickshell.dataDir + "/settings.json"
        preload: true
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onAdapterUpdated: root.save()

        JsonAdapter {
            id: values
            property string appearanceMode: "automatic"
            property bool dynamicColorsEnabled: true
            property string dynamicColorStyle: "tonal"
            property string wallpaperPath: ""
            property real glassOpacity: 0.72
            property bool glassBlur: true
            property real surfaceTint: 0.18
            property bool motionEnabled: true
            property real motionScale: 1.0
            property real cornerScale: 1.0
            property bool dockAutoHide: true
            property bool aiEnabled: true
            property string aiProvider: "gemini"
            property string aiModel: "gemini-2.5-flash"
            property string aiBaseUrl: ""
            property string aiPersonality: "cat"
            property bool previewVisible: true
        }
    }
}
