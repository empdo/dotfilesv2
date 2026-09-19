// SettingsWidget.qml -- the bar icon that opens the quick settings menu.
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
        font.pixelSize: 22
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: "\uF013"           // nf-fa-cog

        // Matches the other bar icons, which grow slightly under the pointer.
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
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
    }
}
