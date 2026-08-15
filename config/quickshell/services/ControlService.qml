pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "../settings"

QtObject {
    id: root

    readonly property string controlScript: Quickshell.shellDir
        + "/../../scripts/ayame-v2-controls"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property bool bluetoothEnabled: bluetoothAdapter?.enabled ?? false
    readonly property var connectedWifi: {
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wifi)
                continue;
            for (const network of device.networks.values) {
                if (network.connected)
                    return network;
            }
        }
        return null;
    }
    readonly property var wifiDevice: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi) return device;
        }
        return null;
    }
    readonly property bool wifiAvailable: Networking.wifiHardwareEnabled
    readonly property string networkName: connectedWifi?.name || ""
    readonly property bool audioAvailable: audio !== null
    readonly property real volume: audio?.volume ?? 0
    readonly property bool muted: audio?.muted ?? false

    property bool networkingAvailable: false
    property bool networkingEnabled: false
    property bool networkingBusy: false
    property bool nightLightAvailable: false
    property bool nightLightBusy: false
    property bool brightnessAvailable: false
    property bool keyboardBacklightAvailable: false
    property bool idleAvailable: false
    property bool displaysAvailable: false
    property int brightness: 50
    property int keyboardBrightness: 0
    property var displays: []
    property bool ready: false
    property string lastError: ""

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function toggleNetworking() {
        if (!networkingAvailable || networkingBusy)
            return;
        networkingBusy = true;
        networkProcess.command = ["bash", controlScript, "network",
            networkingEnabled ? "off" : "on"];
        networkProcess.running = true;
    }

    function toggleBluetooth() {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function setVolume(value) {
        if (audio)
            audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (audio)
            audio.muted = !audio.muted;
    }

    function toggleNightLight() {
        if (!nightLightAvailable || nightLightBusy)
            return;
        ShellSettings.nightLightEnabled = !ShellSettings.nightLightEnabled;
        applyNightLight();
    }

    function applyNightLight() {
        if (!nightLightAvailable || nightLightBusy)
            return;
        nightLightBusy = true;
        nightLightProcess.command = ["bash", controlScript, "nightlight",
            ShellSettings.nightLightEnabled ? "on" : "off",
            String(ShellSettings.nightLightTemperature)];
        nightLightProcess.running = true;
    }

    function toggleDoNotDisturb() {
        ShellSettings.doNotDisturb = !ShellSettings.doNotDisturb;
    }

    function runAction(args) {
        if (systemAction.running) return;
        systemAction.command = ["bash", controlScript].concat(args.map(String));
        systemAction.running = true;
    }

    function setBrightness(value) {
        brightness = Math.round(Math.max(1, Math.min(100, value)));
        runAction(["brightness", brightness]);
    }

    function setKeyboardBrightness(value) {
        keyboardBrightness = Math.round(Math.max(0, Math.min(100, value)));
        runAction(["keyboard", keyboardBrightness]);
    }

    function applyIdle() {
        if (!idleAvailable) return;
        runAction(["idle", ShellSettings.idleEnabled ? 1 : 0,
            ShellSettings.idleTimeoutSeconds, ShellSettings.idleLockEnabled ? 1 : 0]);
    }

    function refreshDisplays() {
        if (!displayProcess.running) displayProcess.running = true;
    }

    property PwObjectTracker audioTracker: PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property Process statusProcess: Process {
        command: ["bash", root.controlScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const fields = line.split("|");
                    if (fields[0] === "network") {
                        root.networkingAvailable = fields[1] === "1";
                        root.networkingEnabled = fields[2] === "1";
                    } else if (fields[0] === "nightlight") {
                        root.nightLightAvailable = fields[1] === "1";
                    } else if (fields[0] === "brightness") {
                        root.brightnessAvailable = fields[1] === "1";
                        root.brightness = Number(fields[2]);
                    } else if (fields[0] === "keyboard") {
                        root.keyboardBacklightAvailable = fields[1] === "1";
                        root.keyboardBrightness = Number(fields[2]);
                    } else if (fields[0] === "idle") {
                        root.idleAvailable = fields[1] === "1";
                    } else if (fields[0] === "display") {
                        root.displaysAvailable = fields[1] === "1";
                    }
                }
                root.ready = true;
                if (Quickshell.env("AYAME_V2_RUNTIME") === "1"
                        && root.nightLightAvailable && ShellSettings.nightLightEnabled)
                    root.applyNightLight();
                if (Quickshell.env("AYAME_V2_RUNTIME") === "1"
                        && root.idleAvailable && ShellSettings.idleEnabled)
                    root.applyIdle();
                root.refreshDisplays();
            }
        }
    }

    property Process networkProcess: Process {
        onExited: (exitCode, exitStatus) => {
            root.networkingBusy = false;
            root.lastError = exitCode === 0 ? "" : "Could not change networking";
            root.refresh();
        }
    }

    property Process nightLightProcess: Process {
        onExited: (exitCode, exitStatus) => {
            root.nightLightBusy = false;
            if (exitCode !== 0) {
                ShellSettings.nightLightEnabled = false;
                root.lastError = "Could not change night light";
            } else {
                root.lastError = "";
            }
        }
    }

    property Process systemAction: Process {
        onExited: (exitCode, exitStatus) => {
            root.lastError = exitCode === 0 ? "" : "System control action failed";
        }
    }

    property Process displayProcess: Process {
        command: ["bash", root.controlScript, "displays"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const field = line.split("|");
                    if (field.length >= 8)
                        result.push({ name: field[0], description: field[1],
                            width: Number(field[2]), height: Number(field[3]),
                            rate: Number(field[4]), scale: Number(field[5]),
                            x: Number(field[6]), y: Number(field[7]) });
                }
                root.displays = result;
            }
        }
    }

    property Connections idleSettings: Connections {
        target: ShellSettings
        function onIdleEnabledChanged() { root.applyIdle(); }
        function onIdleTimeoutSecondsChanged() { if (ShellSettings.idleEnabled) root.applyIdle(); }
        function onIdleLockEnabledChanged() { if (ShellSettings.idleEnabled) root.applyIdle(); }
    }

    property Timer refreshTimer: Timer {
        interval: 4000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
