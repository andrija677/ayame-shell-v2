//@ pragma UseQApplication

import QtQuick
import Quickshell
import "modules/prototype"
import "modules/runtime"
import "services"

ShellRoot {
    readonly property var appearanceService: AppearanceService
    Loader {
        active: Quickshell.env("AYAME_V2_RUNTIME") !== "1"
        sourceComponent: Component { PrototypeDesktop {} }
    }
    Loader {
        active: Quickshell.env("AYAME_V2_RUNTIME") === "1"
        sourceComponent: Component { RuntimeShell {} }
    }
}
