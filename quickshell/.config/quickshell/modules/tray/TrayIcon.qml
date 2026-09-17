// TrayIcon.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root
    property color textColor: "#ebffd9"

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
