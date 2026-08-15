import "../settings"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property string error: ""
    readonly property bool live: Quickshell.env("AYAME_V2_RUNTIME") === "1"
    readonly property string effectiveMode: ShellSettings.appearanceMode === "automatic" ? PaletteService.recommendedAppearance : ShellSettings.appearanceMode
    property Process ruleProcess

    ruleProcess: Process {

        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }

    }

    property Process appearanceProcess

    appearanceProcess: Process {

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root.error = "App appearance: " + text.trim().split("\n").pop();
                }
            }
        }

    }

    property Timer appearanceRetry

    appearanceRetry: Timer {
        interval: 120
        onTriggered: root.applyColorScheme()
    }

    property Connections settingsConnections

    settingsConnections: Connections {
        function onGlassBlurChanged() {
            root.applyBlur();
        }

        function onAppearanceModeChanged() {
            root.applyColorScheme();
        }

        target: ShellSettings
    }

    property Connections paletteConnections

    paletteConnections: Connections {
        function onRecommendedAppearanceChanged() {
            if (ShellSettings.appearanceMode === "automatic")
                root.applyColorScheme();

        }

        target: PaletteService
    }

    function applyColorScheme() {
        if (!live)
            return ;

        if (appearanceProcess.running) {
            appearanceRetry.restart();
            return ;
        }
        appearanceProcess.command = [Quickshell.shellDir + "/../../scripts/ayame-appearance-mode", effectiveMode];
        appearanceProcess.running = true;
    }

    function applyBlur() {
        if (!live || ruleProcess.running)
            return ;

        error = "";
        ruleProcess.command = ["hyprctl", "eval", ShellSettings.glassBlur ? "if ayame_v2_blur_rule then ayame_v2_blur_rule:set_enabled(true) else " + "ayame_v2_blur_rule=hl.layer_rule({match={namespace=\"ayame-shell-v2-.*\"}," + "blur=true,blur_popups=true,ignore_alpha=0.2}) end" : "if ayame_v2_blur_rule then ayame_v2_blur_rule:set_enabled(false) end"];
        ruleProcess.running = true;
    }

    Component.onCompleted: {
        applyBlur();
        applyColorScheme();
    }
}
