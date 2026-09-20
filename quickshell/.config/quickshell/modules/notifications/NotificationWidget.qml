// NotificationWidget.qml -- the bell in the bar.
//
// Hovering opens the history; clicking toggles do not disturb, the same deal
// the volume icon makes (hover for the mixer, click to mute). The badge counts
// what has arrived since the history was last looked at, not the whole list --
// a standing count of 50 tells you nothing.
import QtQuick
import QtQuick.Controls
import Quickshell
import "."
import "../" as Modules

Item {
    id: root

    implicitWidth: 60
    implicitHeight: 40

    Label {
        id: bell
        anchors.centerIn: parent
        color: NotificationService.dnd ? Modules.Theme.inactive : Modules.Theme.foreground
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 18

        text: NotificationService.dnd ? "󰂛"                            // nf-md-bell_off
            : NotificationService.hasEntries ? "󰂚"                     // nf-md-bell
            : "󰂜"                                                      // nf-md-bell_outline
    }

    // Unread count, tucked into the corner of the glyph. Can be turned off
    // from the popup, for when a number in the corner of the eye is worse
    // than not knowing.
    Rectangle {
        visible: NotificationService.badge && NotificationService.unseen > 0
        anchors.left: bell.right
        anchors.leftMargin: -6
        anchors.bottom: bell.top
        anchors.bottomMargin: -10

        implicitWidth: Math.max(14, badge.implicitWidth + 6)
        implicitHeight: 14
        radius: height / 2
        color: Modules.Theme.foreground

        Label {
            id: badge
            anchors.centerIn: parent
            // Past nine the exact number stops mattering and the badge starts
            // being wider than the icon it sits on.
            text: NotificationService.unseen > 9 ? "9+" : NotificationService.unseen
            color: Modules.Theme.onAccent
            font.family: "Roboto Mono"
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: NotificationService.dnd = !NotificationService.dnd
    }
}
