pragma Singleton

import QtQuick
import Quickshell

QtObject {
    readonly property string configuredDataDir: Quickshell.env("AYAME_V2_DATA_DIR")
    readonly property string dataDir: configuredDataDir.length > 0
        ? configuredDataDir : Quickshell.dataDir
}
