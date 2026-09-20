// BarSection.qml -- a group of bar items sharing one rounded backdrop.
//
// The bar used to be a single column of evenly spaced icons with nothing to
// say which belonged together; the capsule gives each group an edge so the
// bar reads as a few things rather than eight.
//
// Children go in a positioner, so they must not set their own anchors. The
// capsule is deliberately narrower than the 60px items -- their visible glyphs
// are only about half that, so it stays centred on the icons rather than on
// their boxes.
//
// Groups that already read as one thing can drop the backdrop with
// `capsule: false` and keep the shared layout.
import QtQuick
import "modules" as Modules

Item {
    id: root

    default property alias content: grid.data
    property real spacing: 12
    property real padding: 10
    property real capsuleWidth: 46
    property real thickness: 60
    property bool capsule: true

    // Set by a bar that runs along the bottom of the screen.
    property bool horizontal: false

    implicitWidth: horizontal ? grid.implicitWidth + 2 * padding : thickness
    implicitHeight: horizontal ? thickness : grid.implicitHeight + 2 * padding

    Rectangle {
        visible: root.capsule
        anchors.centerIn: parent
        width: root.horizontal ? parent.width : root.capsuleWidth
        height: root.horizontal ? root.capsuleWidth : parent.height
        radius: Math.min(width, height) / 2
        color: Modules.Theme.trough
        opacity: 0.28
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        spacing: root.spacing
        // One column stacks the items down a vertical bar; a row lays them
        // along a horizontal one. A Grid keeps a single child list either way,
        // so a section does not need two positioners to pick between.
        columns: root.horizontal ? 100 : 1

        // A Grid aligns its cells to the top-left corner unless told
        // otherwise, and the items in a section are not all the same size --
        // the workspaces pill fills the bar's whole thickness while an icon
        // is only 40px of it, which left the tray and the bell riding 10px
        // high of everything beside them.
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
}
