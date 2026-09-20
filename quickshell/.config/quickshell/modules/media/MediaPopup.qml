// MediaPopup.qml -- now playing: art, track, a seekable progress bar and
// transport controls, plus a player picker when more than one client is up.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "."
import "../" as Modules

Item {
    id: root

    readonly property bool multiple: MediaService.players.length > 1

    implicitWidth: 320
    implicitHeight: 176 + (multiple ? 34 : 0)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ---- art and track ---------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                Layout.preferredWidth: 58
                Layout.preferredHeight: 58
                radius: 10
                color: Modules.Theme.trough

                Image {
                    anchors.fill: parent
                    source: MediaService.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 116
                    sourceSize.height: 116
                }

                // Shows through whenever the art is missing or still loading.
                Label {
                    anchors.centerIn: parent
                    visible: MediaService.artUrl === ""
                    text: ""      // nf-fa-music
                    color: Modules.Theme.inactive
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: 22
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: MediaService.title || "Nothing playing"
                    color: Modules.Theme.foreground
                    font.family: "Roboto Mono"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: MediaService.artist
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: MediaService.album
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 10
                    opacity: 0.7
                    elide: Text.ElideRight
                }
            }
        }

        // ---- progress ----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: MediaService.length > 0

            Label {
                text: MediaService.formatTime(MediaService.elapsed)
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 10
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Modules.Theme.trough

                readonly property real fraction:
                    MediaService.length > 0
                    ? Math.max(0, Math.min(1, MediaService.elapsed / MediaService.length))
                    : 0

                Rectangle {
                    width: track.fraction * parent.width
                    height: parent.height
                    radius: 2
                    color: Modules.Theme.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    // A 4px bar is a small target, so take clicks a bit above
                    // and below it too.
                    anchors.topMargin: -7
                    anchors.bottomMargin: -7
                    enabled: MediaService.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: event => MediaService.seekFraction(event.x / width)
                }
            }

            Label {
                text: MediaService.formatTime(MediaService.length)
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 10
            }
        }

        // ---- transport ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 26

            Repeater {
                model: [
                    { glyph: "", action: "previous", enabled: MediaService.canPrevious },
                    { glyph: MediaService.playing ? "" : "",
                      action: "playPause", enabled: MediaService.canToggle },
                    { glyph: "", action: "next", enabled: MediaService.canNext }
                ]

                delegate: Label {
                    required property var modelData

                    text: modelData.glyph
                    color: Modules.Theme.foreground
                    opacity: modelData.enabled ? 1.0 : 0.3
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: modelData.action === "playPause" ? 20 : 15

                    scale: mouse.containsMouse && modelData.enabled ? 1.25 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        enabled: modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.action === "previous")
                                MediaService.previous();
                            else if (modelData.action === "next")
                                MediaService.next();
                            else
                                MediaService.playPause();
                        }
                    }
                }
            }
        }

        // ---- which player ------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            visible: root.multiple

            Repeater {
                model: MediaService.players

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool current:
                        MediaService.active && MediaService.active.dbusName === modelData.dbusName

                    implicitWidth: label.implicitWidth + 16
                    implicitHeight: 20
                    radius: 10
                    color: current ? Modules.Theme.trough : "transparent"
                    border.width: 1
                    border.color: current ? Modules.Theme.divider : "transparent"

                    Label {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.identity
                        color: parent.current ? Modules.Theme.foreground : Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.selectPlayer(modelData)
                    }
                }
            }
        }
    }
}
