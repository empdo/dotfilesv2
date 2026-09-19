// MediaWidget.qml -- the bar icon for whatever is playing: the album art when
// there is any, otherwise a music glyph. Clicking it plays or pauses, matching
// the volume icon, which mutes on click.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "."
import "../" as Modules

Item {
    id: root

    implicitWidth: 60
    implicitHeight: 40

    readonly property bool hasArt: art.status === Image.Ready

    ClippingRectangle {
        anchors.centerIn: parent
        width: 30
        height: 30
        radius: 8
        color: "transparent"
        visible: root.hasArt
        // Art for a paused track is dimmed, so the bar shows at a glance
        // whether something is actually playing.
        opacity: MediaService.playing ? 1.0 : 0.45

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Image {
            id: art
            anchors.fill: parent
            source: MediaService.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 60
            sourceSize.height: 60
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.hasArt
        text: ""      // nf-fa-music
        color: Modules.Theme.foreground
        opacity: MediaService.playing ? 1.0 : 0.5
        font.family: "Symbols Nerd Font Mono"
        font.weight: Font.DemiBold
        font.pixelSize: 18
    }

    // A small dot marks a live track, since dimmed art alone is subtle.
    Rectangle {
        visible: MediaService.playing
        width: 4
        height: 4
        radius: 2
        color: Modules.Theme.foreground
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: MediaService.playPause()
    }
}
