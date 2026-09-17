import QtQuick
import QtQuick.Controls
import Quickshell
import "modules" as Modules
import "../" as Modules

Item {
    id: root
    property color textColor: "#ebffd9"

    implicitWidth: 60
    implicitHeight: 40

    Label {
        id: lbl
        anchors.centerIn: parent 
        color: root.textColor
        font.weight: Font.DemiBold
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: !Modules.AudioService.muted ? " " : " "
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Modules.AudioService.toggleMute()
    }
}
