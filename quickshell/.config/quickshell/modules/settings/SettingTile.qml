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
            // A value is a value, not a headline: it gives way rather than
            // squeezing the title out of its own tile. Wallpapers are the
            // reason -- "a_painting_of_a_tree_and_water.jpg" is wider than the
            // tile it has to fit in. Measured against the tile rather than the
            // layout, since asking a Qt Quick Layout for its width while it is
            // being laid out sends it into a recursive rearrange.
            // A third of the tile: enough that the longest title in the row
            // still fits whole, since the title is what says which tile this
            // is and the value is only ever a detail about it.
            Layout.maximumWidth: root.width * 0.33
            elide: Text.ElideRight
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
