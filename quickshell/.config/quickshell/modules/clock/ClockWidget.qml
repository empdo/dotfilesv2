// ClockWidget.qml -- the time in the bar.
//
// A vertical bar is 60px wide, which will not take "03:59" at a readable size,
// so the clock goes down the bar a component per line. A horizontal bar is
// 60px tall instead, which is room for two lines across rather than four down.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../" as Modules

Item {
    id: root

    // Set by a bar that runs along the bottom of the screen.
    property bool horizontal: false
    property real thickness: 60

    implicitWidth: horizontal ? stack.implicitWidth + 12 : thickness
    implicitHeight: horizontal ? thickness : 120

    property color textColor: Modules.Theme.foreground
    property int labelHeight: 22

    Column {
        id: stack
        anchors.centerIn: parent
        spacing: root.horizontal ? 1 : 4

        // ---- down a vertical bar ------------------------------------------
        Label {
            visible: !root.horizontal
            color: root.textColor
            font.family: "Roboto Mono"
            font.pixelSize: 20
            height: root.labelHeight
            width: root.thickness
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.hour
        }

        Label {
            visible: !root.horizontal
            font.family: "Roboto Mono"
            color: root.textColor
            font.pixelSize: 20
            width: root.thickness
            height: root.labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.min
        }

        Item {
            visible: !root.horizontal
            width: root.thickness
            height: 4
        }

        Label {
            visible: !root.horizontal
            color: root.textColor
            width: root.thickness
            font.pixelSize: 20
            height: root.labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.month
        }

        Label {
            visible: !root.horizontal
            color: root.textColor
            font.pixelSize: 20
            width: root.thickness
            height: root.labelHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Modules.Time.day
        }

        // ---- across a horizontal bar ---------------------------------------
        Label {
            visible: root.horizontal
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.textColor
            font.family: "Roboto Mono"
            font.pixelSize: 18
            text: Modules.Time.hour + ":" + Modules.Time.min
        }

        Label {
            visible: root.horizontal
            anchors.horizontalCenter: parent.horizontalCenter
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 12
            text: Modules.Time.month + " " + Modules.Time.day
        }
    }
}
