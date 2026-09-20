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
    // One bar per output. A screen that is taller than it is wide -- this
    // machine's second monitor is rotated a quarter turn -- gets the bar
    // across its bottom instead of down its left edge, where a vertical bar
    // would eat a twentieth of an already narrow screen. Reading it off the
    // shape rather than the output name means a monitor added or re-rotated
    // sorts itself out.
    Variants {
        model: Quickshell.screens

        delegate: Bar {
            required property var modelData

            screen: modelData
            horizontal: modelData.height > modelData.width
        }
    }
    Cheatsheet {}
    ClipboardPanel {}
    Launcher {}
    NotificationOverlay {}
    PolkitPrompt {}
}
