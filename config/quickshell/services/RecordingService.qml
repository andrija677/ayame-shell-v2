import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property bool recording: false
    property string outputPath: ""
    property double startedAt: 0
    property int elapsedSeconds: 0
    property string status: ""
    property string error: ""
    readonly property string elapsedText: {
        const minutes = Math.floor(elapsedSeconds / 60).toString().padStart(2, "0");
        const seconds = (elapsedSeconds % 60).toString().padStart(2, "0");
        return minutes + ":" + seconds;
    }
    readonly property string script: Quickshell.shellDir + "/../../scripts/ayame-record"
    property Process statusProcess

    statusProcess: Process {
        command: ["bash", root.script, "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("|");
                root.recording = fields[0] === "recording";
                root.outputPath = fields[1] ?? "";
                root.startedAt = Number(fields[2] ?? 0);
                if (fields[0] === "failed")
                    root.error = fields[1] || "Screen recording failed";

                root.elapsedSeconds = root.recording && root.startedAt > 0 ? Math.max(0, Math.floor(Date.now() / 1000 - root.startedAt)) : 0;
            }
        }

    }

    property Process controlProcess

    controlProcess: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && !root.error)
                root.error = "Screen recording failed";

            refreshDelay.restart();
            root.controlFinished();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root.status = text.trim();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }

    }

    property Timer refreshDelay

    refreshDelay: Timer {
        interval: 180
        onTriggered: root.refresh()
    }

    property Timer poller

    poller: Timer {
        interval: root.recording ? 500 : 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property Timer elapsedTicker

    elapsedTicker: Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsedSeconds++
    }

    signal controlFinished()
    signal capturePillRequested()

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;

    }

    function start(mode, audio, monitor, delay) {
        if (controlProcess.running || recording)
            return ;

        error = "";
        status = mode === "area" ? "Select the recording area…" : "Starting recording…";
        controlProcess.command = ["bash", script, "start", mode, audio, monitor || "AUTO", String(delay || 0)];
        controlProcess.running = true;
    }

    function stop() {
        if (controlProcess.running || !recording)
            return ;

        status = "Saving recording…";
        controlProcess.command = ["bash", script, "stop"];
        controlProcess.running = true;
    }

    function showCapturePill() {
        capturePillRequested();
    }

}
