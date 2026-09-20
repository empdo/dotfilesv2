import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import "modules" as Modules

Item {
    // size to the content instead of filling the whole bar,
    // so things can be anchored below it
    implicitWidth: 60
    implicitHeight: content.implicitHeight

    Column {
        id: content
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        // Arch logo
//        Text {
//            text: "󰣇"
//            color: Modules.Theme.foreground
//            rightPadding: 5
//            topPadding: 8
//            font.pixelSize: 30
//            horizontalAlignment: Text.AlignHCenter
//            anchors.horizontalCenter: parent.horizontalCenter
//        }

        // Workspaces background
        Rectangle {
            id: repeaterBackground
            color: Modules.Theme.background
            radius: 20
            border.color: Modules.Theme.foreground
            border.width: 1
            width: 28
            height: repeaterRow.implicitHeight + 16
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            Column {
                id: repeaterRow
                anchors.centerIn: parent
                spacing: 8
                padding: 8

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: modelData.active ? Modules.Theme.foreground : "transparent"
                        border.color: Modules.Theme.foreground
                        border.width: 2
                        anchors.horizontalCenter: parent.horizontalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.activate()
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
