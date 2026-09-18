// TrayPopup.qml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../" as Modules

Item {
    id: root

    property color textColor: Modules.Theme.foreground
    property int iconSize: 24
    property int columns: 4

    // Number of app menus currently open. The bar keeps the popup open while > 0,
    // since moving the cursor onto a menu counts as leaving the popup.
    property int openMenus: 0
    readonly property bool menuOpen: openMenus > 0

    property string hoveredTitle: ""

    implicitWidth: Math.max(grid.implicitWidth + 40, 90)
    implicitHeight: content.implicitHeight + 60

    Column {
        id: content
        anchors.centerIn: parent
        spacing: 12

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            columns: Math.max(1, Math.min(root.columns, repeater.count))
            spacing: 16

            Repeater {
                id: repeater
                model: SystemTray.items

                MouseArea {
                    id: trayItem

                    required property SystemTrayItem modelData

                    width: root.iconSize
                    height: root.iconSize
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onContainsMouseChanged: {
                        root.hoveredTitle = containsMouse
                            ? (modelData.tooltipTitle || modelData.title || modelData.id)
                            : "";
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                            if (modelData.hasMenu)
                                menuAnchor.open();
                        } else {
                            modelData.activate();
                        }
                    }

                    onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

                    // The app's own right-click menu, opened beside the icon
                    QsMenuAnchor {
                        id: menuAnchor
                        menu: trayItem.modelData.menu
                        anchor.item: trayItem
                        anchor.rect.x: trayItem.width + 8
                        anchor.rect.y: 0

                        onOpened: root.openMenus++
                        onClosed: root.openMenus = Math.max(0, root.openMenus - 1)
                    }

                    Image {
                        anchors.fill: parent
                        source: trayItem.modelData.icon
                        sourceSize.width: root.iconSize
                        sourceSize.height: root.iconSize
                        smooth: true

                        scale: trayItem.containsMouse ? 1.15 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

    }
}
