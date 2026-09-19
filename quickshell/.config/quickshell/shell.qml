//@ pragma UseQApplication
// shell.qml
import QtQuick
import Quickshell
import "modules" as Modules
import "modules/cheatsheet"
import "modules/launcher"

Scope {
    id: root
    Bar {}
    Cheatsheet {}
    Launcher {}
}
