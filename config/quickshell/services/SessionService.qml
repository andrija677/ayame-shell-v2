import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property bool gameMode: false
    property bool gameModeBusy: false
    readonly property string script: Quickshell.shellDir + "/../../scripts/ayame-gaming-mode"
    property Process statusProcess

    statusProcess: Process {
        command: ["bash", root.script, "status"]

        stdout: StdioCollector {
            onStreamFinished: root.gameMode = text.trim() === "1"
        }

    }

    property Process toggleProcess

    toggleProcess: Process {
        onExited: {
            root.gameModeBusy = false;
            root.refresh();
        }
    }

    property Timer timer

    timer: Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;

    }

    function toggleGameMode() {
        if (gameModeBusy)
            return ;

        gameModeBusy = true;
        toggleProcess.command = ["bash", script, "toggle"];
        toggleProcess.running = true;
    }

}
