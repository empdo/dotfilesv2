//@ pragma UseQApplication
// shell.qml
import QtQuick
import Quickshell
import "modules" as Modules
import "modules/cheatsheet"

Scope {
    id: root
    Bar {}
    Cheatsheet {}
}
