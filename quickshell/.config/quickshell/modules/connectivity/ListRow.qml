// ListRow.qml -- one clickable row, shared by the network and bluetooth lists
// so both halves of the popup line up and highlight identically.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as Modules

Rectangle {
    id: root

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    // Drawn in place of `trailing` while an action is in flight.
    property bool busy: false
    // The row this list is "on": connected network, connected device.
    property bool active: false

    signal clicked
    signal secondaryClicked

    implicitHeight: 40
    radius: 8
    color: mouse.containsMouse ? Modules.Theme.trough : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Label {
            text: root.glyph
            color: root.active ? Modules.Theme.foreground : Modules.Theme.inactive
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 16
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                color: Modules.Theme.foreground
                font.family: "Roboto Mono"
                font.pixelSize: 13
                font.bold: root.active
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Label {
            visible: root.trailing !== "" && !root.busy
            text: root.trailing
            color: Modules.Theme.inactive
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 12
        }

        // A plain spinning arc: the actions here (associating, pairing) take
        // long enough that a static row looks broken.
        Label {
            id: spinner
            visible: root.busy
            text: "󰑮"
            color: Modules.Theme.foreground
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 12

            RotationAnimation on rotation {
                running: spinner.visible
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.secondaryClicked();
            else
                root.clicked();
        }
    }
}
