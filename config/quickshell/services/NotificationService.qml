import "../settings"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
pragma Singleton

QtObject {
    id: root

    readonly property bool serverEnabled: Quickshell.env("AYAME_V2_RUNTIME") === "1" && Quickshell.env("AYAME_V2_NOTIFICATION_SERVER") === "1" && ShellSettings.notificationServerEnabled
    readonly property var history: historyAdapter.entries ?? []
    readonly property int count: history.length
    property FileView historyFile

    historyFile: FileView {
        id: historyFile

        path: Quickshell.dataDir + "/notification-history.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: historyAdapter

            property var entries: []
        }

    }

    property Loader serverLoader

    serverLoader: Loader {
        active: root.serverEnabled

        sourceComponent: Component {
            NotificationServer {
                keepOnReload: true
                persistenceSupported: true
                bodySupported: true
                bodyMarkupSupported: false
                bodyHyperlinksSupported: false
                bodyImagesSupported: false
                actionsSupported: true
                imageSupported: true
                onNotification: (notification) => {
                    notification.tracked = true;
                    root.saveNotification(notification);
                    if (!ShellSettings.doNotDisturb)
                        root.popupRequested(root.popupSnapshot(notification));

                }
            }

        }

    }

    signal popupRequested(var notification)
    signal popupsCleared()

    function popupSnapshot(notification) {
        const actions = [];
        for (const action of notification.actions ?? []) {
            const nativeAction = action;
            actions.push({
                "text": action.text ?? "Action",
                "invoke": () => {
                    try {
                        nativeAction.invoke();
                    } catch (error) {
                    }
                }
            });
        }
        return {
            "appIcon": notification.appIcon ?? "",
            "summary": notification.summary ?? "",
            "appName": notification.appName ?? "",
            "body": notification.body ?? "",
            "expireTimeout": notification.expireTimeout ?? 6000,
            "actions": actions
        };
    }

    function saveNotification(notification) {
        if (notification.transient === true)
            return ;

        const updated = history.slice();
        updated.push({
            "id": Date.now().toString() + "-" + Math.random().toString(16).slice(2),
            "appIcon": notification.appIcon ?? "",
            "desktopEntry": notification.desktopEntry ?? "",
            "summary": notification.summary ?? "",
            "appName": notification.appName ?? "",
            "body": notification.body ?? "",
            "receivedAt": new Date().toISOString()
        });
        historyAdapter.entries = updated.slice(Math.max(0, updated.length - 100));
        historyFile.writeAdapter();
    }

    function dismiss(id) {
        historyAdapter.entries = history.filter((entry) => {
            return entry.id !== id;
        });
        historyFile.writeAdapter();
    }

    function clearAll() {
        historyAdapter.entries = [];
        historyFile.writeAdapter();
        popupsCleared();
    }

}
