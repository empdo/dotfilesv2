// KeyCap.qml -- one key drawn as a physical cap, e.g. [SUPER] [+] [RETURN]
import QtQuick
import QtQuick.Controls
import "../" as Modules

Rectangle {
    id: root

    property string text: ""
    property color textColor: Modules.Theme.foreground

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24

    radius: 5
    color: Modules.Theme.trough
    border.width: 1
    border.color: Modules.Theme.divider

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: "Roboto Mono"
        font.pixelSize: 13
        font.bold: true
    }
}
