import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../theme"

GlassSurface {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        for (const candidate of players) {
            if (candidate.isPlaying) return candidate;
        }
        return players.length > 0 ? players[0] : null;
    }
    readonly property real progress: {
        progressTimer.tick;
        if (!player?.positionSupported || !player?.lengthSupported
                || player.length <= 0) return 0;
        return Math.max(0, Math.min(1, player.position / player.length));
    }
    readonly property real displayedPosition: {
        progressTimer.tick;
        return player?.position ?? -1;
    }

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0) return "--:--";
        const whole = Math.floor(seconds);
        return Math.floor(whole / 60) + ":"
            + String(whole % 60).padStart(2, "0");
    }

    implicitHeight: player ? 126 : 88
    depth: 1
    radius: Theme.radiusLarge

    Timer {
        id: progressTimer
        property int tick: 0
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: tick++
    }

    RowLayout {
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: root.player ? 76 : 58
            implicitHeight: implicitWidth
            radius: Theme.radiusMedium
            color: Theme.tertiarySoft

            Image {
                id: artwork
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            AppIcon {
                anchors.fill: parent
                visible: artwork.status !== Image.Ready
                icon: root.player ? "music_note" : "headphones"
                iconColor: Theme.onSurface
                iconSize: root.player ? 34 : 26
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space8

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    AppText {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || "Nothing playing"
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    AppText {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist || "Start some music and it will meet you here"
                        color: Theme.onSurfaceMuted
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }
                AppText {
                    visible: root.player !== null
                    text: root.player?.identity || ""
                    color: Theme.outline
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    Layout.maximumWidth: 72
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.player !== null
                    && (root.player?.lengthSupported ?? false)
                    && (root.player?.positionSupported ?? false)
                spacing: Theme.space8

                AppText {
                    text: root.formatTime(root.displayedPosition)
                    color: Theme.outline
                    font.family: Theme.numericFontFamily
                    font.pixelSize: 9
                }
                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 3
                    color: Theme.alpha(Theme.outline, 0.25)
                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors { fill: parent; topMargin: -8; bottomMargin: -8 }
                        enabled: root.player?.canSeek ?? false
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => root.player.position
                            = root.player.length * mouse.x / width
                    }
                }
                AppText {
                    text: root.formatTime(root.player?.length ?? -1)
                    color: Theme.outline
                    font.family: Theme.numericFontFamily
                    font.pixelSize: 9
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.space8
                visible: root.player !== null
                IconButton {
                    icon: "skip_previous"
                    accessibleName: "Previous track"
                    enabled: root.player?.canGoPrevious ?? false
                    implicitWidth: 36; implicitHeight: 36
                    onActivated: root.player?.previous()
                }
                IconButton {
                    icon: root.player?.isPlaying ? "pause" : "play_arrow"
                    accessibleName: root.player?.isPlaying ? "Pause" : "Play"
                    enabled: root.player?.canTogglePlaying ?? false
                    checked: true
                    implicitWidth: 42; implicitHeight: 42
                    onActivated: root.player?.togglePlaying()
                }
                IconButton {
                    icon: "skip_next"
                    accessibleName: "Next track"
                    enabled: root.player?.canGoNext ?? false
                    implicitWidth: 36; implicitHeight: 36
                    onActivated: root.player?.next()
                }
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.motionResponsive; easing.type: Theme.easeEnter }
    }
}
