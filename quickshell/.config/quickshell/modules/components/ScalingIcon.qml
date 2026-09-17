import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 32
    height: 32

    // The icon glyph
    property alias text: iconLabel.text
    property color color: "#ebffd9"

    // Hover scaling
    property bool hovered: false
    scale: hovered ? 1.25 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    Label {
        id: iconLabel
        anchors.centerIn: parent
        color: root.color
        font.pixelSize: 24
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }
}
