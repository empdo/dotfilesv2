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
    Bar {}
    Cheatsheet {}
    ClipboardPanel {}
    Launcher {}
    NotificationOverlay {}
    PolkitPrompt {}
}
