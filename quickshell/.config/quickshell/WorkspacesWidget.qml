import QtQuick
import Quickshell
import Quickshell.Hyprland
import "modules" as Modules

Item {
    id: root

    // Set by a bar that runs along the bottom of the screen.
    property bool horizontal: false

    property real thickness: 60

    // Size to the content instead of filling the whole bar, so things can be
    // anchored past it.
    implicitWidth: horizontal ? pill.implicitWidth : thickness
    implicitHeight: horizontal ? thickness : pill.implicitHeight

    Rectangle {
        id: pill
        anchors.centerIn: parent

        color: Modules.Theme.background
        radius: 20
        border.color: Modules.Theme.foreground
        border.width: 1
        clip: true

        implicitWidth: root.horizontal ? dots.implicitWidth + 16 : 28
        implicitHeight: root.horizontal ? 28 : dots.implicitHeight + 16
        width: implicitWidth
        height: implicitHeight

        Grid {
            id: dots
            anchors.centerIn: parent
            spacing: 8
            columns: root.horizontal ? 100 : 1

            Repeater {
                model: Hyprland.workspaces

                delegate: Rectangle {
                    required property var modelData

                    width: 12
                    height: 12
                    radius: 6
                    color: modelData.active ? Modules.Theme.foreground : "transparent"
                    border.color: Modules.Theme.foreground
                    border.width: 2

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }
}
