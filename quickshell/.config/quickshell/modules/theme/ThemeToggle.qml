// modules/theme/ThemeToggle.qml
import QtQuick
import QtQuick.Controls
import "../" as Modules

Item {
    id: root

    implicitWidth: 60
    implicitHeight: 40

    Label {
        id: lbl
        anchors.centerIn: parent
        color: Modules.Theme.foreground
        font.family: "Symbols Nerd Font Mono"
        font.weight: Font.DemiBold
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        // sun in light mode, moon in dark mode
        text: Modules.Theme.light ? "󰖨" : "󰖔"

        scale: mouse.containsMouse ? 1.25 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Modules.Theme.toggle()
    }
}
