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

        text: " "

        scale: mouse.containsMouse ? 1.15 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    // Hover is handled by the enclosing ExpandableItem; this only exists so the
    // glyph grows under the pointer like the other bar icons. It previously
    // carried the volume widget's handler, so clicking power toggled the mute.
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
    }
}
