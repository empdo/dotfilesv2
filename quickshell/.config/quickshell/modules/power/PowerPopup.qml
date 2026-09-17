import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "modules" as Modules
import "."
import "../components"
 
Item {
    id: root
    implicitWidth: 220
    implicitHeight: 110

    property var popup
    property color textColor: "#ebffd9"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 38

        ScalingIcon {
            text: "󰍃"
            color: root.textColor
            Layout.alignment: Qt.AlignBottom
        }

        ScalingIcon {
            text: "󰒲"
            color: root.textColor
            Layout.alignment: Qt.AlignBottom
        }

        ScalingIcon {
            text: ""
            color: root.textColor
            Layout.alignment: Qt.AlignBottom
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onExited: root.popup.hidePopup()
    }
}
