import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../settings"
import "../../theme"

GlassSurface {
    id: root

    property var messages: []
    property bool historyLoaded: false
    property bool thinking: false
    property bool receiving: false
    property string error: ""
    signal closeRequested()
    signal settingsRequested()

    readonly property string basePrompt:
        "You are Ayame, an AI assistant living inside a Linux desktop shell. "
        + "Be concise, warm, honest, and technically accurate. Never claim you ran commands, "
        + "inspected files, or changed the system. Never execute commands. Respect privacy."
    readonly property string systemPrompt: basePrompt
        + (ShellSettings.aiPersonality === "custom"
            ? " " + ShellSettings.aiCustomPrompt
            : ShellSettings.aiPersonality === "cat"
            ? " Use a playful, affectionate cat-girl voice with gentle :3 energy, without emotional manipulation."
            : ShellSettings.aiPersonality === "fox"
                ? " Use a warm, clever, lightly mischievous fox-girl voice, while staying honest."
                : "")

    function append(role, content) {
        const copy = messages.slice();
        copy.push({ role: role, content: content });
        messages = copy;
        saveHistory();
        Qt.callLater(() => chatList.positionViewAtEnd());
    }

    function saveHistory() {
        if (!historyLoaded) return;
        historyAdapter.messages = messages.slice(-60);
        historySaveTimer.restart();
    }

    function clearHistory() {
        if (chatProcess.running) chatProcess.signal(15);
        messages = [];
        error = "";
        saveHistory();
    }

    function sendText(text) {
        const clean = String(text || "").trim();
        if (!clean || chatProcess.running) return;
        input.text = "";
        error = "";
        const copy = messages.slice();
        copy.push({ role: "user", content: clean });
        copy.push({ role: "assistant", content: "" });
        messages = copy;
        thinking = true;
        receiving = false;
        saveHistory();
        chatProcess.command = [
            "python3", Quickshell.shellDir + "/../../scripts/ayame-ai.py", "chat"
        ];
        chatProcess.running = true;
        Qt.callLater(() => chatList.positionViewAtEnd());
    }

    function acceptEvent(line) {
        if (!line.trim()) return;
        try {
            const event = JSON.parse(line);
            if (event.type === "delta") {
                thinking = false;
                receiving = true;
                const copy = messages.slice();
                const last = copy.length - 1;
                copy[last] = { role: "assistant", content: copy[last].content + event.text };
                messages = copy;
                Qt.callLater(() => chatList.positionViewAtEnd());
            } else if (event.type === "error") {
                thinking = false;
                receiving = false;
                error = event.message;
                const copy = messages.slice();
                copy[copy.length - 1] = { role: "assistant", content: "I couldn’t answer that yet. " + event.message };
                messages = copy;
                saveHistory();
            } else if (event.type === "done") {
                thinking = false;
                receiving = false;
                saveHistory();
            }
        } catch (exception) {
            error = "Ayame received an unreadable provider response";
        }
    }

    radius: Theme.radiusXLarge
    depth: 2

    Timer {
        id: historySaveTimer
        interval: 180
        onTriggered: historyFile.writeAdapter()
    }

    FileView {
        id: historyFile
        path: Quickshell.dataDir + "/ai-chat-history.json"
        preload: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.messages = (historyAdapter.messages || []).filter(item =>
                item.role === "user" || String(item.content || "").length > 0);
            root.historyLoaded = true;
        }
        JsonAdapter {
            id: historyAdapter
            property var messages: []
        }
    }

    Process {
        id: chatProcess
        stdinEnabled: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.acceptEvent(data)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0 && root.error.length === 0)
                    root.error = text.trim().split("\n").pop();
            }
        }
        onStarted: {
            write(JSON.stringify({
                provider: ShellSettings.aiProvider,
                model: ShellSettings.aiModel,
                baseUrl: ShellSettings.aiBaseUrl,
                systemPrompt: root.systemPrompt,
                history: root.messages.slice(0, -1)
            }) + "\n");
        }
        onExited: {
            root.thinking = false;
            root.receiving = false;
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space16 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            AppIcon {
                icon: "auto_awesome"
                backgroundColor: Theme.accent
                iconColor: Theme.onAccent
                implicitWidth: 44
                implicitHeight: 44
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                AppText { text: "Ayame AI"; font.pixelSize: Theme.fontTitle; font.weight: Font.ExtraBold }
                AppText {
                    text: ShellSettings.aiProvider + " • " + ShellSettings.aiPersonality
                    color: Theme.onSurfaceMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton { icon: "edit_square"; accessibleName: "New chat"; onActivated: root.clearHistory() }
            IconButton { icon: "settings"; accessibleName: "AI settings"; onActivated: root.settingsRequested() }
            IconButton { icon: "close"; accessibleName: "Close Ayame AI"; onActivated: root.closeRequested() }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.space32, 350)
                spacing: Theme.space12
                visible: root.messages.length === 0
                AppIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "temp_preferences_custom"
                    backgroundColor: Theme.accentSoft
                    iconColor: Theme.onAccentSoft
                    implicitWidth: 68
                    implicitHeight: 68
                    iconSize: 32
                }
                AppText {
                    Layout.fillWidth: true
                    text: "Hey twin, what are we making?"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                AppText {
                    Layout.fillWidth: true
                    text: "Ayame can think with you, but never touches the system on her own."
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.onSurfaceMuted
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    ActionPill { label: "Explain this shell"; onActivated: root.sendText(label) }
                    ActionPill { label: "Help me plan"; onActivated: root.sendText(label) }
                }
            }

            ListView {
                id: chatList
                anchors.fill: parent
                visible: root.messages.length > 0
                clip: true
                spacing: Theme.space8
                model: root.messages
                delegate: Item {
                    required property var modelData
                    width: ListView.view.width
                    height: bubble.implicitHeight
                    Rectangle {
                        id: bubble
                        anchors.right: parent.modelData.role === "user" ? parent.right : undefined
                        anchors.left: parent.modelData.role === "assistant" ? parent.left : undefined
                        width: Math.min(parent.width * 0.88,
                            Math.max(110, messageBody.implicitWidth + Theme.space24))
                        implicitHeight: messageBody.implicitHeight + Theme.space20
                        radius: Theme.radiusLarge
                        color: parent.modelData.role === "user" ? Theme.accentSoft : Theme.glassHighest
                        border.width: 1
                        border.color: parent.modelData.role === "user" ? Theme.accent : Theme.glassStroke
                        AppText {
                            id: messageBody
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space12 }
                            text: bubble.parent.modelData.content
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: bubble.parent.modelData.role === "user" ? Theme.onAccentSoft : Theme.onSurface
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(52, input.implicitHeight + Theme.space20)
            radius: Theme.radiusLarge
            color: Theme.glassHighest
            border.width: input.activeFocus ? 2 : 1
            border.color: input.activeFocus ? Theme.accent : Theme.glassStroke

            RowLayout {
                anchors { fill: parent; margins: Theme.space8 }
                TextArea {
                    id: input
                    Layout.fillWidth: true
                    placeholderText: chatProcess.running ? "Ayame is thinking…" : "Message Ayame…"
                    enabled: !chatProcess.running
                    color: Theme.onSurface
                    placeholderTextColor: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    wrapMode: TextEdit.Wrap
                    background: null
                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                            root.sendText(text);
                            event.accepted = true;
                        }
                    }
                }
                IconButton {
                    icon: chatProcess.running ? "stop" : "arrow_upward"
                    accessibleName: chatProcess.running ? "Stop response" : "Send message"
                    checked: true
                    enabled: chatProcess.running || input.text.trim().length > 0
                    onActivated: chatProcess.running ? chatProcess.signal(15) : root.sendText(input.text)
                }
            }
        }

        AppText {
            Layout.fillWidth: true
            text: ShellSettings.aiProvider === "ollama"
                ? "Local provider • no automatic system access"
                : "Messages go to " + ShellSettings.aiProvider + " • no automatic system access"
            color: root.error.length > 0 ? Theme.danger : Theme.outline
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
