// TrayIcon.qml
import QtQuick
import QtQuick.Controls
import "../" as Modules

Item {
    id: root
    property color textColor: Modules.Theme.foreground

    implicitWidth: 60
    implicitHeight: 40

    Label {
        anchors.centerIn: parent
        color: root.textColor
        font.weight: Font.DemiBold
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: "󰅂"
    }
}
