import "../config/quickshell/modules/prototype"
import QtQuick
import QtTest

TestCase {
    function test_settingsSurfaceCreates() {
        const settings = createTemporaryObject(settingsComponent, this);
        verify(settings !== null);
        compare(settings.currentPage, 0);
        settings.currentPage = 4;
        compare(settings.currentPage, 4);
    }

    function test_hubAndSubpagesCreate() {
        const hub = createTemporaryObject(hubComponent, this);
        verify(hub !== null);
        compare(hub.currentPage, 0);
        for (let page = 1; page <= 5; page++) {
            hub.showPage(page);
            compare(hub.currentPage, page);
        }
    }

    name: "SettingsAndHub"
    when: windowShown
    width: 1100
    height: 760

    Component {
        id: settingsComponent

        SettingsPanel {
            width: 900
            height: 640
        }

    }

    Component {
        id: hubComponent

        HubPanel {
            width: 480
            height: 700
            hostWindow: null
        }

    }

}
