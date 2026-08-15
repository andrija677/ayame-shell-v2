import "../../components"
import "../../services"
import "../../theme"
import "../quicksettings"
import QtQuick
import QtQuick.Layouts

GlassSurface {
    id: root

    property var hostWindow: null
    property int currentPage: 0

    signal closeRequested()
    signal settingsRequested()
    signal powerRequested()

    function showPage(page) {
        currentPage = page;
    }

    radius: Theme.radiusXLarge
    depth: 2
    clip: true
    onEnabledChanged: {
        if (enabled) {
            currentPage = 0;
        }
    }

    ColumnLayout {
        spacing: Theme.space12

        anchors {
            fill: parent
            margins: Theme.space20
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.currentPage === 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                AppText {
                    text: "Control center"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }

                AppText {
                    text: ControlService.lastError.length > 0 ? ControlService.lastError : "Your system, right here"
                    color: ControlService.lastError.length > 0 ? Theme.danger : Theme.success
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }

            }

            IconButton {
                icon: "settings"
                accessibleName: "Open Settings"
                onActivated: root.settingsRequested()
            }

            IconButton {
                icon: "close"
                accessibleName: "Close control center"
                onActivated: root.closeRequested()
            }

        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentPage

            QuickMainPage {
                hostWindow: root.hostWindow
                onWifiRequested: root.showPage(1)
                onBluetoothRequested: root.showPage(2)
                onClipboardRequested: root.showPage(3)
                onDisplaysRequested: root.showPage(4)
                onKeybindsRequested: root.showPage(5)
                onSettingsRequested: root.settingsRequested()
                onPowerRequested: root.powerRequested()
            }

            WifiPage {
                wifiDevice: ControlService.wifiDevice
                onBackRequested: root.showPage(0)
            }

            BluetoothPage {
                adapter: ControlService.bluetoothAdapter
                onBackRequested: root.showPage(0)
            }

            ClipboardPage {
                onBackRequested: root.showPage(0)
            }

            DisplayPage {
                onBackRequested: root.showPage(0)
            }

            KeybindsPage {
                onBackRequested: root.showPage(0)
            }

        }

    }

}
