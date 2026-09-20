// ExpandableItem.qml
import QtQuick
import Quickshell

Item {
    id: root

    property var barWindow
    property Component popupContent
    property Component iconComponent

    property bool iconHovered: false
    property bool popupHovered: false

    property bool smoothBottom

    // set this to hold the popup open, e.g. while a context menu from it is showing
    property bool keepOpen: false

    // Open immediately, but close with a short delay so the cursor can
    // travel from the bar surface to the popup surface without it vanishing.
    property bool hovered: iconHovered || popupHovered || keepOpen
    property bool open: false

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            open = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.open = false
    }

    implicitWidth: iconLoader.item ? iconLoader.item.implicitWidth || iconLoader.item.width : 60
    implicitHeight: iconLoader.item ? iconLoader.item.implicitHeight || iconLoader.item.height : 40

    // icon inside the bar
    Loader {
        id: iconLoader
        anchors.centerIn: parent
        sourceComponent: iconComponent

        scale: popup.visible ? 1.1 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    PopupWindow {
        id: popup
        color: "transparent"

        implicitWidth: popupLoader.item ? popupLoader.item.implicitWidth : 260
        implicitHeight: popupLoader.item ? popupLoader.item.implicitHeight : 100

        anchor.window: barWindow

        visible: root.open

        // Wraps the content (instead of sitting on top of it) so items inside
        // the popup still get hover events while this tracks the whole popup.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            onEntered: popupHovered = true
            onExited: popupHovered = false

            Loader {
                id: popupLoader

                sourceComponent: Component {
                    RoundedPopupCard {
                        id: card
                        smoothBottom: root.smoothBottom

                        // Animate the popup appearing
                        width: popup.visible ? implicitWidth : 0
                        height: popup.visible ? implicitHeight : 0

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        content: Loader {
                            id: innerLoader
                            sourceComponent: popupContent
                            anchors.top: parent.top
                            anchors.left: parent.left
                        }
                    }
                }
            }
        }
        anchor.adjustment: PopupAdjustment.None

        anchor.onAnchoring: {
            const winItem = barWindow.contentItem;

            const center = root.mapToItem(winItem, root.width / 2, root.height / 2);

            anchor.rect.x = root.barWindow.width - 1;

            if (root.smoothBottom) {
                anchor.rect.y = winItem.height - popup.implicitHeight;
            } else {
                const pos = root.mapToItem(winItem, 0, 0);
                const centred = pos.y + (root.height - popup.implicitHeight) / 2;
                // Clamped to the screen: items near either end of the bar --
                // the notification bell is the tall one -- would otherwise
                // have the top or bottom of their popup cut off. The card is
                // a panel rather than a speech bubble, so it does not have to
                // stay lined up with the icon that opened it.
                anchor.rect.y = Math.max(0, Math.min(centred, winItem.height - popup.implicitHeight));
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: iconHovered = true
        onExited: iconHovered = false
    }
}
