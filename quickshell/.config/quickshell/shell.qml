//@ pragma UseQApplication
// shell.qml
import QtQuick
import Quickshell
import "modules" as Modules
import "modules/cheatsheet"
import "modules/clipboard"
import "modules/launcher"
import "modules/notifications"
import "modules/polkit"

Scope {
    id: root
    // One bar per output, on whichever edge of it Modules.Shell says -- the
    // launcher and the clipboard open flush against that same edge, so the
    // three of them read the rule from one place.
    Variants {
        model: Quickshell.screens

        delegate: Bar {
            required property var modelData

            screen: modelData
            horizontal: Modules.Shell.barIsHorizontal(modelData)
        }
    }
    Cheatsheet {}
    ClipboardPanel {}
    Launcher {}
    NotificationOverlay {}
    PolkitPrompt {}
}
