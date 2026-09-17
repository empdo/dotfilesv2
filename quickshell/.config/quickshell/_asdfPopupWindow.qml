// PopupWindow.qml
import Quickshell
import QtQuick

PanelWindow {
    id: popup

    implicitWidth: popupLoader.implicitWidth
    implicitHeight: popupLoader.implicitHeight
    color: "transparent"

    visible: false
    exclusiveZone: -1

    // You do NOT set contentItem.
    // Instead, you place your loader AS A CHILD.
    Loader {
        id: loader
        anchors.fill: parent
    }

    // allow ExpandableItem to set the popup's content
    property alias popupLoader: loader
}
