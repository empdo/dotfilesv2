import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../" as Modules

Item {
    id: root
    implicitWidth: 60
    implicitHeight: 120

    property color textColor: "#ebffd9"
    property int labelHeight: 22

    Column {
        id: clock
        spacing: 4

        Label {
            color: textColor
            font.family: "Roboto Mono"
            font.pixelSize: 20
            height: labelHeight
            width: root.width
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.hour
        }

        Label {
            font.family: "Roboto Mono"
            color: textColor
            font.pixelSize: 20
            width: root.width
            height: labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.min
        }

        Item {
            width: root.width
            height: 4
        }

        Label {
            id: monthLabel
            color: textColor
            width: root.width
            font.pixelSize: 20
            height: labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.month
        }

        Label {
            color: textColor
            font.pixelSize: 20
            width: root.width
            height: labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.day
        }
    }
}
