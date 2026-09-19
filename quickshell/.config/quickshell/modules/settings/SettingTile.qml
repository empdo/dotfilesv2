// SettingTile.qml -- one of the quick settings across the top of the menu:
// a glyph, what it is, and its current value. The whole tile is the control,
// so there is no separate switch -- the theme is a choice between two modes
// rather than something that is on or off.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as Modules

Rectangle {
    id: root

    property string glyph: ""
    property string title: ""
    property string value: ""

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 46
    radius: 10
    color: mouse.containsMouse ? Modules.Theme.trough : "transparent"
    border.width: 1
    border.color: Modules.Theme.divider

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10

        Label {
            text: root.glyph
            color: Modules.Theme.foreground
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: root.title
            color: Modules.Theme.foreground
            font.family: "Roboto Mono"
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Label {
            text: root.value
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
