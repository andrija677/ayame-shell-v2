import "../settings"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property bool applying: false
    property string error: ""
    property string lastApplied: ""
    property Process setter

    setter: Process {
        onExited: (exitCode, exitStatus) => {
            root.applying = false;
            if (exitCode !== 0 && !root.error)
                root.error = "Could not set that wallpaper";

        }

        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }

    }

    function apply(path) {
        const clean = String(path || "").trim();
        if (!clean || applying)
            return ;

        applying = true;
        error = "";
        lastApplied = clean;
        ShellSettings.wallpaperPath = clean;
        setter.command = ["bash", Quickshell.shellDir + "/../../scripts/ayame-wallpaper", "set", clean];
        setter.running = true;
    }

}
