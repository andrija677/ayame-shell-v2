pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property alias appearanceMode: values.appearanceMode
    property alias glassOpacity: values.glassOpacity
    property alias glassBlur: values.glassBlur
    property alias surfaceTint: values.surfaceTint
    property alias motionEnabled: values.motionEnabled
    property alias motionScale: values.motionScale
    property alias cornerScale: values.cornerScale
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
            property string appearanceMode: "dark"
            property real glassOpacity: 0.72
            property bool glassBlur: true
            property real surfaceTint: 0.18
            property bool motionEnabled: true
            property real motionScale: 1.0
            property real cornerScale: 1.0
            property bool previewVisible: true
        }
    }
}
