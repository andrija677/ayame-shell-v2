import "../settings"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property var entries: []
    property bool busy: false
    readonly property bool live: Quickshell.env("AYAME_V2_RUNTIME") === "1"
    readonly property string script: Quickshell.shellDir + "/../../scripts/ayame-clipboard"
    property Process watchProcess

    watchProcess: Process {
        command: ["bash", root.script, "watch"]
    }

    property Process listProcess

    listProcess: Process {
        command: ["bash", root.script, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const f = line.split("|");
                    if (f.length >= 4)
                        result.push({
                        "id": f[0],
                        "kind": f[1],
                        "preview": f[2],
                        "path": f.slice(3).join("|")
                    });

                }
                root.entries = result;
            }
        }

    }

    property Process actionProcess

    actionProcess: Process {
        onRunningChanged: {
            if (!running) {
                root.busy = false;
                root.refresh();
            }
        }
    }

    property Connections settingsConnection

    settingsConnection: Connections {
        function onClipboardHistoryEnabledChanged() {
            root.applyEnabled();
        }

        target: ShellSettings
    }

    property Timer refreshTimer

    refreshTimer: Timer {
        interval: 1500
        repeat: true
        running: ShellSettings.clipboardHistoryEnabled
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!ShellSettings.clipboardHistoryEnabled || listProcess.running) {
            if (!ShellSettings.clipboardHistoryEnabled)
                entries = [];

            return ;
        }
        listProcess.running = true;
    }

    function run(action, id) {
        if (actionProcess.running)
            return ;

        busy = true;
        actionProcess.command = id === undefined ? ["bash", script, action] : ["bash", script, action, String(id)];
        actionProcess.running = true;
    }

    function applyEnabled() {
        if (ShellSettings.clipboardHistoryEnabled) {
            if (live && !watchProcess.running)
                watchProcess.running = true;

            refresh();
        } else {
            if (watchProcess.running)
                watchProcess.signal(15);

            entries = [];
        }
    }

    Component.onCompleted: applyEnabled()
}
