import QtQuick
import QtQuick.Controls
import Quickshell
import "../" as Modules

Item {
    id: root
    property color textColor: Modules.Theme.foreground

    implicitWidth: 60
    implicitHeight: 40

    Label {
        id: lbl
        anchors.centerIn: parent 
        color: root.textColor
        font.weight: Font.DemiBold
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: " "
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Modules.AudioService.toggleMute()
    }
}
