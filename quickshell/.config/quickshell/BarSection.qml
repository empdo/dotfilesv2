// BarSection.qml -- a group of bar items sharing one rounded backdrop.
//
// The bar used to be a single column of evenly spaced icons with nothing to
// say which belonged together; the capsule gives each group an edge so the
// bar reads as a few things rather than eight.
//
// Children go in a Column, so they must not set their own anchors. The capsule
// is deliberately narrower than the 60px items -- their visible glyphs are only
// about half that, so it stays centred on the icons rather than on their boxes.
//
// Groups that already read as one thing can drop the backdrop with
// `capsule: false` and keep the shared column layout.
import QtQuick
import "modules" as Modules

Item {
    id: root

    default property alias content: column.data
    property real spacing: 12
    property real padding: 10
    property real capsuleWidth: 46
    property bool capsule: true

    implicitWidth: 60
    implicitHeight: column.implicitHeight + 2 * padding

    Rectangle {
        visible: root.capsule
        anchors.centerIn: parent
        width: root.capsuleWidth
        height: parent.height
        radius: width / 2
        color: Modules.Theme.trough
        opacity: 0.28
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
