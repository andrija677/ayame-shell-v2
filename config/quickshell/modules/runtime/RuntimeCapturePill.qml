import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

PanelWindow {
    id: root

    property string captureMode: "area"
    property string audioMode: "none"
    property int countdown: 0
    property int offsetX: 28
    property int offsetY: ShellSettings.capturePillY
    property real displayX: offsetX
    property real dragBaseX: 0
    property real dragBaseY: 0
    property real dragReleaseX: 0
    property real pointerStartX: 0
    property real pointerStartY: 0
    property bool cursorPrimed: false
    property bool tucked: false
    property string dragStartSide: ""
    property string snappedSide: ShellSettings.capturePillSide
    property bool dragging: false
    property bool suppressVisibility: false
    property string status: ""
    property string error: ""
    property bool selectionMode: false
    property bool selectionDragging: false
    property real selectionStartX: 0
    property real selectionStartY: 0
    property real selectionCurrentX: 0
    property real selectionCurrentY: 0
    property string selectionPurpose: "screenshot"
    readonly property bool docked: snappedSide.length > 0
    readonly property real pillWidth: pillGrid.implicitWidth + Theme.space16
    readonly property real pillHeight: pillGrid.implicitHeight + Theme.space16

    Connections {
        target: RecordingService
        function onCapturePillRequested() {
            ShellSettings.capturePillEnabled = true;
            root.suppressVisibility = false;
            root.selectionMode = false;
            root.tucked = false;
            root.displayX = root.snappedSide === "right"
                ? Math.max(0, root.width - root.pillWidth) : 0;
            if (root.docked) tuckTimer.restart();
        }
    }

    function cycleMode() {
        captureMode = captureMode === "desktop" ? "monitor"
            : captureMode === "monitor" ? "area" : "desktop";
    }
    function cycleAudio() {
        audioMode = audioMode === "none" ? "system"
            : audioMode === "system" ? "microphone" : "none";
    }
    function cycleCountdown() {
        countdown = countdown === 0 ? 3 : countdown === 3 ? 5 : 0;
    }
    function revealFromWall() {
        if (!docked || !tucked) return;
        tuckTimer.stop();
        tucked = false;
        displayX = snappedSide === "left" ? 0 : width - pillWidth;
    }
    function snapIfNearEdge() {
        const right = Math.max(0, width - pillWidth);
        if (offsetX < 110) {
            offsetX = 0;
            snappedSide = "left";
        } else if (right - offsetX < 110) {
            offsetX = right;
            snappedSide = "right";
        }
        tucked = false;
        displayX = offsetX;
        ShellSettings.capturePillSide = snappedSide;
        ShellSettings.capturePillY = Math.round(offsetY);
        if (docked) tuckTimer.restart();
    }
    function beginDragAt(sceneX, sceneY) {
        dragStartSide = snappedSide;
        dragReleaseX = 0;
        dragBaseX = Math.min(offsetX, Math.max(0, width - pillWidth));
        dragBaseY = offsetY;
        pointerStartX = sceneX;
        pointerStartY = sceneY;
        cursorPrimed = false;
        dragging = true;
        tucked = false;
        cursorPoll.restart();
    }
    function dragTo(sceneX, sceneY) {
        updateDrag(sceneX - pointerStartX, sceneY - pointerStartY);
    }
    function updateDrag(dx, dy) {
        if (!dragging) return;
        if (dragStartSide.length > 0) {
            const inward = dragStartSide === "left" ? Math.max(0, dx) : Math.max(0, -dx);
            if (inward < 72) {
                const stretch = inward * 0.16;
                displayX = dragStartSide === "left" ? stretch : width - pillWidth - stretch;
                offsetY = Math.max(80, Math.min(height - pillHeight - 100, dragBaseY + dy));
                return;
            }
            const releasedSide = dragStartSide;
            dragStartSide = "";
            snappedSide = "";
            ShellSettings.capturePillSide = "";
            dragReleaseX = dx;
            dragBaseX = releasedSide === "left" ? 18
                : Math.max(0, width - pillWidth - 18);
        }
        offsetX = Math.max(0, Math.min(width - pillWidth,
            dragBaseX + dx - dragReleaseX));
        offsetY = Math.max(80, Math.min(height - pillHeight - 100, dragBaseY + dy));
        displayX = offsetX;
    }
    function endDrag() {
        if (dragStartSide.length > 0) {
            offsetX = dragStartSide === "left" ? 0 : Math.max(0, width - pillWidth);
            displayX = offsetX;
            dragStartSide = "";
        } else {
            snapIfNearEdge();
        }
        dragging = false;
        cursorPrimed = false;
        ShellSettings.capturePillY = Math.round(offsetY);
    }
    function takeScreenshot() {
        if (screenshotProcess.running) return;
        status = "Capturing…";
        error = "";
        if (captureMode === "area") {
            beginAreaSelection("screenshot");
            return;
        }
        suppressVisibility = true;
        screenshotStart.restart();
    }
    function beginAreaSelection(purpose) {
        selectionPurpose = purpose;
        selectionDragging = false;
        suppressVisibility = true;
        areaSelectionStart.interval = 220 + countdown * 1000;
        areaSelectionStart.restart();
    }
    function cancelSelection() {
        selectionDragging = false;
        selectionMode = false;
        suppressVisibility = false;
        selectionPurpose = "screenshot";
    }
    function finishSelection() {
        const left = Math.round(Math.min(selectionStartX, selectionCurrentX));
        const top = Math.round(Math.min(selectionStartY, selectionCurrentY));
        const selectedWidth = Math.round(Math.abs(selectionCurrentX - selectionStartX));
        const selectedHeight = Math.round(Math.abs(selectionCurrentY - selectionStartY));
        if (selectedWidth < 2 || selectedHeight < 2) {
            cancelSelection();
            return;
        }
        const geometry = left + "," + top + " " + selectedWidth + "x" + selectedHeight;
        selectionMode = false;
        if (selectionPurpose === "recording") {
            selectionPurpose = "screenshot";
            suppressVisibility = false;
            RecordingService.start("geometry", audioMode, geometry, 0);
            return;
        }
        screenshotProcess.command = ["bash", Quickshell.shellDir
            + "/../../scripts/ayame-screenshot", "geometry", "0", geometry];
        captureAfterSelection.restart();
    }
    function toggleRecording() {
        if (RecordingService.recording) {
            RecordingService.stop();
            return;
        }
        if (captureMode === "area") {
            beginAreaSelection("recording");
            return;
        }
        suppressVisibility = false;
        RecordingService.start(captureMode, audioMode, screen?.name || "AUTO", countdown);
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: ShellSettings.capturePillEnabled || RecordingService.recording || selectionMode
    mask: Region { item: selectionMode || dragging ? dragPlane : pillSurface }
    WlrLayershell.namespace: "ayame-shell-v2-capture-pill"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: selectionMode
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Item { id: dragPlane; anchors.fill: parent }

    ClippingRectangle {
        id: pillSurface
        x: root.displayX
        y: Math.max(80, Math.min(root.height - height - 100,
            root.offsetY - (height - 48) / 2))
        width: root.pillWidth
        height: root.pillHeight
        topLeftRadius: root.snappedSide === "left" ? 0 : Theme.radiusLarge
        bottomLeftRadius: root.snappedSide === "left" ? 0 : Theme.radiusLarge
        topRightRadius: root.snappedSide === "right" ? 0 : Theme.radiusLarge
        bottomRightRadius: root.snappedSide === "right" ? 0 : Theme.radiusLarge
        color: Theme.glassRaised
        border.width: RecordingService.recording ? 2 : 1
        border.color: RecordingService.recording ? Theme.danger : Theme.glassStroke
        visible: !root.suppressVisibility && !root.selectionMode

        Rectangle {
            anchors { fill: parent; margins: 1 }
            radius: Math.max(0, Theme.radiusLarge - 1)
            color: "transparent"
            border.width: 1
            border.color: Theme.glassHighlight
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onEntered: root.revealFromWall()
            onExited: if (root.docked && !root.dragging) tuckTimer.restart()
            onPressed: mouse => {
                const point = mapToGlobal(mouse.x, mouse.y);
                root.beginDragAt(point.x, point.y);
            }
            onPositionChanged: mouse => {
                if (!pressed || root.cursorPrimed) return;
                const point = mapToGlobal(mouse.x, mouse.y);
                root.dragTo(point.x, point.y);
            }
            onReleased: root.endDrag()
            onCanceled: root.endDrag()
        }

        GridLayout {
            id: pillGrid
            z: 2
            anchors.centerIn: parent
            columns: root.docked ? 1 : 9
            rowSpacing: root.docked ? Theme.space8 : Theme.space4
            columnSpacing: Theme.space4

            Rectangle {
                implicitWidth: root.docked ? 68 : 32
                implicitHeight: 34
                radius: Theme.radiusMedium
                color: grip.containsMouse ? Theme.glassHighest : "transparent"
                AppText { anchors.centerIn: parent; text: "⠿"; color: Theme.outline; font.pixelSize: 16 }
                MouseArea {
                    id: grip
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: mouse => {
                        const point = mapToGlobal(mouse.x, mouse.y);
                        root.beginDragAt(point.x, point.y);
                    }
                    onPositionChanged: mouse => {
                        if (!pressed || root.cursorPrimed) return;
                        const point = mapToGlobal(mouse.x, mouse.y);
                        root.dragTo(point.x, point.y);
                    }
                    onReleased: root.endDrag()
                    onCanceled: root.endDrag()
                }
            }

            Rectangle {
                implicitWidth: root.docked ? 68 : modeText.implicitWidth + Theme.space20
                implicitHeight: 36; radius: Theme.radiusMedium
                color: modeMouse.containsMouse ? Theme.accentSoft : Theme.glassHighest
                AppText {
                    id: modeText; anchors.centerIn: parent
                    text: root.captureMode === "desktop" ? "Desktop"
                        : root.captureMode === "monitor" ? "Monitor" : "Area"
                    font.pixelSize: Theme.fontSmall; font.weight: Font.Bold
                }
                MouseArea { id: modeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleMode() }
            }

            Rectangle {
                implicitWidth: root.docked ? 68 : delayText.implicitWidth + Theme.space20
                implicitHeight: 36; radius: Theme.radiusMedium
                color: delayMouse.containsMouse ? Theme.accentSoft : Theme.glassHighest
                AppText { id: delayText; anchors.centerIn: parent; text: root.countdown === 0 ? "Instant" : root.countdown + "s"; font.pixelSize: Theme.fontSmall; font.weight: Font.Bold }
                MouseArea { id: delayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleCountdown() }
            }

            Rectangle {
                implicitWidth: root.docked ? 68 : 38; implicitHeight: 36; radius: Theme.radiusMedium
                color: shotMouse.containsMouse ? Theme.accent : Theme.accentSoft
                AppIcon { anchors.centerIn: parent; icon: "photo_camera"; iconColor: shotMouse.containsMouse ? Theme.onAccent : Theme.onAccentSoft; implicitWidth: 26; implicitHeight: 26; iconSize: 18 }
                MouseArea { id: shotMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.takeScreenshot() }
            }

            Rectangle {
                implicitWidth: root.docked ? 68 : 38; implicitHeight: 36; radius: Theme.radiusMedium
                color: RecordingService.recording ? Theme.danger
                    : recordMouse.containsMouse ? Theme.accent : Theme.accentSoft
                AppText {
                    anchors.centerIn: parent
                    text: RecordingService.recording ? "■" : "●"
                    color: RecordingService.recording ? Theme.onAccent : Theme.danger
                    font.pixelSize: RecordingService.recording ? 12 : 17
                }
                MouseArea { id: recordMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleRecording() }
            }

            Rectangle {
                implicitWidth: root.docked ? 68 : audioText.implicitWidth + Theme.space20
                implicitHeight: 36; radius: Theme.radiusMedium
                color: audioMouse.containsMouse ? Theme.accentSoft : Theme.glassHighest
                AppText {
                    id: audioText; anchors.centerIn: parent
                    text: root.audioMode === "none" ? "Silent"
                        : root.audioMode === "system" ? "System" : "Mic"
                    font.pixelSize: Theme.fontSmall; font.weight: Font.Bold
                }
                MouseArea { id: audioMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleAudio() }
            }

            AppText {
                visible: RecordingService.recording
                text: RecordingService.elapsedText
                color: Theme.danger
                font.family: Theme.numericFontFamily
                font.weight: Font.Bold
            }

            IconButton {
                visible: !RecordingService.recording
                icon: "close"
                accessibleName: "Hide capture pill"
                implicitWidth: root.docked ? 68 : 34
                implicitHeight: 34
                onActivated: ShellSettings.capturePillEnabled = false
            }
        }

        Behavior on width { SpringAnimation { spring: 3; damping: 0.38 } }
        Behavior on height { SpringAnimation { spring: 3; damping: 0.38 } }
    }

    Item {
        anchors.fill: parent
        visible: root.selectionMode
        z: 50

        Rectangle {
            anchors.fill: parent
            visible: !root.selectionDragging
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: 0; y: 0; width: parent.width
            height: Math.min(root.selectionStartY, root.selectionCurrentY)
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: 0; y: Math.max(root.selectionStartY, root.selectionCurrentY)
            width: parent.width; height: parent.height - y
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: 0; y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: Math.min(root.selectionStartX, root.selectionCurrentX)
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: Math.max(root.selectionStartX, root.selectionCurrentX)
            y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: parent.width - x
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: Math.min(root.selectionStartX, root.selectionCurrentX)
            y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: Math.abs(root.selectionCurrentX - root.selectionStartX)
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "transparent"
            border.width: 4
            border.color: Theme.accent
        }
        GlassSurface {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Theme.space24 }
            implicitWidth: selectionHint.implicitWidth + Theme.space24
            implicitHeight: 38
            radius: Theme.radiusPill
            depth: 3
            AppText {
                id: selectionHint
                anchors.centerIn: parent
                text: root.selectionDragging
                    ? Math.round(Math.abs(root.selectionCurrentX - root.selectionStartX))
                        + " × " + Math.round(Math.abs(root.selectionCurrentY - root.selectionStartY))
                    : "Drag to select an area • Esc to cancel"
                font.weight: Font.Bold
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                root.selectionDragging = true;
                root.selectionStartX = mouse.x;
                root.selectionStartY = mouse.y;
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
            }
            onPositionChanged: mouse => {
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
            }
            onReleased: mouse => {
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
                root.selectionDragging = false;
                root.finishSelection();
            }
        }
    }

    Behavior on displayX {
        enabled: !root.dragging
        SpringAnimation {
            spring: root.tucked ? 3.2 : 8
            damping: root.tucked ? 0.32 : 0.58
            epsilon: 0.35
        }
    }

    onPillWidthChanged: {
        if (snappedSide === "right" && !dragging) {
            offsetX = Math.max(0, width - pillWidth);
            displayX = tucked ? width - 10 : offsetX;
        }
    }

    Timer {
        id: tuckTimer
        interval: 2500
        onTriggered: {
            if (!root.docked || root.dragging) return;
            root.tucked = true;
            root.displayX = root.snappedSide === "left"
                ? -root.pillWidth + 10 : root.width - 10;
        }
    }
    Timer {
        id: cursorPoll
        interval: root.dragging ? 8 : 120
        repeat: true
        running: root.dragging
        onTriggered: if (!cursorPositionProcess.running) cursorPositionProcess.running = true
    }
    Process {
        id: cursorPositionProcess
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.dragging) return;
                try {
                    const position = JSON.parse(text);
                    if (!root.cursorPrimed) {
                        root.pointerStartX = position.x;
                        root.pointerStartY = position.y;
                        root.cursorPrimed = true;
                    } else root.dragTo(position.x, position.y);
                } catch (error) { }
            }
        }
    }
    Timer {
        id: screenshotStart
        interval: 260
        onTriggered: {
            screenshotProcess.command = ["bash", Quickshell.shellDir
                + "/../../scripts/ayame-screenshot", root.captureMode,
                String(root.countdown), root.screen?.name || "AUTO"];
            screenshotProcess.running = true;
        }
    }
    Timer {
        id: areaSelectionStart
        interval: 220
        onTriggered: root.selectionMode = true
    }
    Timer {
        id: captureAfterSelection
        interval: 180
        onTriggered: screenshotProcess.running = true
    }
    Process {
        id: screenshotProcess
        stdout: StdioCollector { onStreamFinished: root.status = text.trim() }
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: (exitCode, exitStatus) => {
            root.suppressVisibility = false;
            if (root.docked) tuckTimer.restart();
        }
    }
    Connections {
        target: RecordingService
        function onControlFinished() {
            root.suppressVisibility = false;
            if (root.docked) tuckTimer.restart();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.selectionMode
        onActivated: root.cancelSelection()
    }

    Component.onCompleted: {
        if (docked) {
            offsetX = snappedSide === "left" ? 0 : Math.max(0, width - pillWidth);
            displayX = offsetX;
            tuckTimer.restart();
        }
    }
}
