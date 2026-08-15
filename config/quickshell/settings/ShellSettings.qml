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
    property alias barEnabled: values.barEnabled
    property alias barStyle: values.barStyle
    property alias dockEnabled: values.dockEnabled
    property alias pinnedDockApps: values.pinnedDockApps
    property alias dockAppOrder: values.dockAppOrder
    property alias workspacesEnabled: values.workspacesEnabled
    property alias activeWindowEnabled: values.activeWindowEnabled
    property alias clockEnabled: values.clockEnabled
    property alias clockFormat: values.clockFormat
    property alias dashboardEnabled: values.dashboardEnabled
    property alias quickSettingsEnabled: values.quickSettingsEnabled
    property alias audioEnabled: values.audioEnabled
    property alias networkEnabled: values.networkEnabled
    property alias batteryEnabled: values.batteryEnabled
    property alias trayEnabled: values.trayEnabled
    property alias showPassiveTrayItems: values.showPassiveTrayItems
    property alias densityMode: values.densityMode
    property alias workspaceCount: values.workspaceCount
    property alias capturePillEnabled: values.capturePillEnabled
    property alias capturePillSide: values.capturePillSide
    property alias capturePillY: values.capturePillY
    property alias reducedMotion: values.reducedMotion
    property alias playfulMotion: values.playfulMotion
    property alias doNotDisturb: values.doNotDisturb
    property alias notificationServerEnabled: values.notificationServerEnabled
    property alias clipboardHistoryEnabled: values.clipboardHistoryEnabled
    property alias weatherEnabled: values.weatherEnabled
    property alias weatherLocationName: values.weatherLocationName
    property alias weatherLatitude: values.weatherLatitude
    property alias weatherLongitude: values.weatherLongitude
    property alias weatherTemperatureUnit: values.weatherTemperatureUnit
    property alias nightLightEnabled: values.nightLightEnabled
    property alias nightLightTemperature: values.nightLightTemperature
    property alias idleEnabled: values.idleEnabled
    property alias idleTimeoutSeconds: values.idleTimeoutSeconds
    property alias idleLockEnabled: values.idleLockEnabled
    property alias aiEnabled: values.aiEnabled
    property alias aiProvider: values.aiProvider
    property alias aiModel: values.aiModel
    property alias aiBaseUrl: values.aiBaseUrl
    property alias aiPersonality: values.aiPersonality
    property alias aiCustomPrompt: values.aiCustomPrompt
    property alias previewVisible: values.previewVisible

    function save() {
        saveTimer.restart();
    }

    function dockFavorites() {
        return pinnedDockApps.split("|").filter(id => id.length > 0);
    }

    function toggleDockFavorite(id) {
        if (!id) return;
        const favorites = dockFavorites();
        const index = favorites.indexOf(id);
        if (index >= 0) favorites.splice(index, 1);
        else favorites.push(id);
        pinnedDockApps = favorites.join("|");
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
            property bool barEnabled: true
            property string barStyle: "floating"
            property bool dockEnabled: true
            property string pinnedDockApps: "org.gnome.Nautilus.desktop|kitty.desktop|firefox.desktop"
            property string dockAppOrder: ""
            property bool workspacesEnabled: true
            property bool activeWindowEnabled: true
            property bool clockEnabled: true
            property string clockFormat: "24h"
            property bool dashboardEnabled: true
            property bool quickSettingsEnabled: true
            property bool audioEnabled: true
            property bool networkEnabled: true
            property bool batteryEnabled: true
            property bool trayEnabled: true
            property bool showPassiveTrayItems: true
            property string densityMode: "comfortable"
            property int workspaceCount: 5
            property bool capturePillEnabled: true
            property string capturePillSide: "right"
            property int capturePillY: 120
            property bool reducedMotion: false
            property bool playfulMotion: true
            property bool doNotDisturb: false
            property bool notificationServerEnabled: true
            property bool clipboardHistoryEnabled: false
            property bool weatherEnabled: false
            property string weatherLocationName: ""
            property real weatherLatitude: 0
            property real weatherLongitude: 0
            property string weatherTemperatureUnit: "celsius"
            property bool nightLightEnabled: false
            property int nightLightTemperature: 4500
            property bool idleEnabled: false
            property int idleTimeoutSeconds: 600
            property bool idleLockEnabled: true
            property bool aiEnabled: true
            property string aiProvider: "gemini"
            property string aiModel: "gemini-2.5-flash"
            property string aiBaseUrl: ""
            property string aiPersonality: "cat"
            property string aiCustomPrompt: ""
            property bool previewVisible: true
        }
    }
}
