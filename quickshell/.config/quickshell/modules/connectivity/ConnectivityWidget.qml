// ConnectivityWidget.qml -- the bar icon: whichever connection is carrying
// traffic, with a dot when something is connected over Bluetooth.
import QtQuick
import QtQuick.Controls
import Quickshell
import "."
import "../" as Modules

Item {
    id: root
    property color textColor: Modules.Theme.foreground

    implicitWidth: 60
    implicitHeight: 40

    Label {
        id: lbl
        anchors.centerIn: parent
        color: ConnectivityService.online ? root.textColor : Modules.Theme.inactive
        font.family: "Symbols Nerd Font Mono"
        font.weight: Font.DemiBold
        font.pixelSize: 20
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: ConnectivityService.statusGlyph
    }

    Rectangle {
        visible: ConnectivityService.btConnected.length > 0
        width: 5
        height: 5
        radius: 2.5
        color: root.textColor
        anchors.horizontalCenter: lbl.horizontalCenter
        anchors.top: lbl.bottom
        anchors.topMargin: 1
    }
}
