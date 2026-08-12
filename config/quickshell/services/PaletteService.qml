pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root

    property var colors: paletteCache.colors
    property bool generating: false
    property string error: ""
    property string outputBuffer: ""
    property string sourcePath: ""
    property string pendingPath: ""
    property string detectedWallpaper: ""
    property real wallpaperLuminance: paletteCache.luminance

    readonly property bool available: colors !== null
    readonly property bool active: ShellSettings.dynamicColorsEnabled && available
    readonly property string recommendedAppearance:
        wallpaperLuminance >= 0.58 ? "light" : "dark"

    function schemeForStyle(style) {
        if (style === "vibrant") return "scheme-vibrant";
        if (style === "expressive") return "scheme-expressive";
        if (style === "content") return "scheme-content";
        return "scheme-tonal-spot";
    }

    function modeColor(name, mode, fallback) {
        const entry = colors?.[name];
        return entry?.[mode]?.color ?? entry?.default?.color ?? fallback;
    }

    function colorLuminance(hexColor) {
        const value = String(hexColor || "").replace("#", "");
        if (value.length !== 6) return 0.3;
        function channel(offset) {
            const component = parseInt(value.slice(offset, offset + 2), 16) / 255;
            return component <= 0.04045
                ? component / 12.92
                : Math.pow((component + 0.055) / 1.055, 2.4);
        }
        return 0.2126 * channel(0) + 0.7152 * channel(2)
            + 0.0722 * channel(4);
    }

    function generate(path) {
        const clean = String(path || "").trim();
        if (clean.length === 0) return;
        detectedWallpaper = clean;

        if (generator.running) {
            pendingPath = clean;
            generating = true;
            return;
        }

        if (paletteCache.wallpaper === clean
                && paletteCache.style === ShellSettings.dynamicColorStyle
                && paletteCache.colors !== null) {
            colors = paletteCache.colors;
            wallpaperLuminance = paletteCache.luminance;
            error = "";
            return;
        }

        error = "";
        outputBuffer = "";
        sourcePath = clean;
        generating = true;
        generator.command = [
            "matugen", "image", clean,
            "--dry-run", "-j", "hex", "-m", "dark",
            "-t", schemeForStyle(ShellSettings.dynamicColorStyle),
            "--source-color-index", "0"
        ];
        generator.running = true;
    }

    function useDetectedWallpaper(path) {
        const clean = String(path || "").trim();
        if (clean.length === 0 || ShellSettings.wallpaperPath.length > 0)
            return;
        generate(clean);
    }

    property Process generator: Process {
        id: generator

        stdout: StdioCollector {
            onStreamFinished: root.outputBuffer = text
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.error = text.trim().split("\n").pop();
            }
        }

        onRunningChanged: {
            if (running) return;

            if (root.outputBuffer.length > 0) {
                try {
                    const result = JSON.parse(root.outputBuffer);
                    if (!result.colors) throw new Error("missing colors");
                    root.colors = result.colors;
                    paletteCache.colors = result.colors;
                    paletteCache.wallpaper = root.sourcePath;
                    paletteCache.style = ShellSettings.dynamicColorStyle;

                    const sourceColor = result.colors.source_color?.default?.color;
                    root.wallpaperLuminance = root.colorLuminance(sourceColor);
                    paletteCache.luminance = root.wallpaperLuminance;
                    paletteFile.writeAdapter();

                    luminanceProbe.command = [
                        "magick", root.sourcePath, "-resize", "1x1!",
                        "-colorspace", "gray", "-format", "%[fx:mean]", "info:"
                    ];
                    luminanceProbe.running = true;
                    root.error = "";
                } catch (exception) {
                    root.error = "Matugen returned an invalid palette";
                }
            } else if (root.error.length === 0) {
                root.error = "Could not generate colors from this wallpaper";
            }

            root.generating = false;
            if (root.pendingPath.length > 0) {
                const next = root.pendingPath;
                root.pendingPath = "";
                queuedGenerate.nextPath = next;
                queuedGenerate.restart();
            }
        }
    }

    property Process luminanceProbe: Process {
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const measured = Number(text.trim());
                if (Number.isFinite(measured) && measured >= 0 && measured <= 1) {
                    root.wallpaperLuminance = measured;
                    paletteCache.luminance = measured;
                    paletteFile.writeAdapter();
                }
            }
        }
    }

    property Timer queuedGenerate: Timer {
        property string nextPath: ""
        interval: 1
        onTriggered: {
            const next = nextPath;
            nextPath = "";
            root.generate(next);
        }
    }

    property Timer regenerate: Timer {
        interval: 280
        onTriggered: root.generate(root.detectedWallpaper)
    }

    property FileView v2WallpaperFile: FileView {
        path: (Quickshell.env("XDG_STATE_HOME")
            || Quickshell.env("HOME") + "/.local/state")
            + "/ayame-shell-v2/wallpaper.path"
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: root.useDetectedWallpaper(text())
        onFileChanged: reload()
    }

    // Read-only development fallback: V1 keeps wallpaper ownership while the
    // V2 preview is running. This is removable once V2 becomes the active shell.
    property FileView v1WallpaperFile: FileView {
        path: (Quickshell.env("XDG_STATE_HOME")
            || Quickshell.env("HOME") + "/.local/state")
            + "/ayame-shell/wallpaper.path"
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: root.useDetectedWallpaper(text())
        onFileChanged: reload()
    }

    property FileView paletteFile: FileView {
        id: paletteFile
        path: Quickshell.cacheDir + "/dynamic-palette.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: paletteCache
            property var colors: null
            property string wallpaper: ""
            property string style: ""
            property real luminance: 0.3
        }
    }

    Component.onCompleted: {
        if (ShellSettings.wallpaperPath.length > 0)
            generate(ShellSettings.wallpaperPath);
    }

    property Connections settingConnections: Connections {
        target: ShellSettings
        function onWallpaperPathChanged() {
            if (ShellSettings.wallpaperPath.length > 0)
                root.generate(ShellSettings.wallpaperPath);
        }
        function onDynamicColorStyleChanged() {
            if (root.detectedWallpaper.length > 0)
                root.regenerate.restart();
        }
    }
}
