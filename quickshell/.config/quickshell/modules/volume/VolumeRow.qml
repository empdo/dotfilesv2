// VolumeRow.qml -- one labelled volume slider: the output, the microphone, or
// one application.
//
// The icon on the left is the mute button: an application's real icon when its
// stream name matches a desktop entry, otherwise a speaker glyph that shows the
// mute state directly.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../" as Modules

Item {
    id: root

    property string glyph: ""
    property string iconSource: ""
    property string label: ""
    property real volume: 0
    property bool muted: false

    // Emitted only when the user drags, never when `volume` changes underneath
    // us -- binding the slider's value and writing it back on every change
    // makes the two fight, which is what made the old popup unusable.
    signal moved(real value)
    signal muteToggled

    implicitHeight: 44

    // Hover feedback uses a HoverHandler rather than a MouseArea so it does not
    // swallow the drags meant for the slider.
    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: 8
        color: hover.hovered ? Modules.Theme.trough : "transparent"
        opacity: 0.55

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            opacity: root.muted ? 0.4 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.iconSource !== ""
                implicitSize: 22
                source: root.iconSource
                asynchronous: true
            }

            Label {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: root.glyph
                color: Modules.Theme.foreground
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 15
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.muteToggled()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: root.label
                    color: root.muted ? Modules.Theme.inactive : Modules.Theme.foreground
                    font.family: "Roboto Mono"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                // Fixed width, right aligned: the number must not shift the
                // label about as it counts up and down.
                Label {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: root.muted ? "muted" : Math.round(root.volume * 100) + "%"
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                }
            }

            Slider {
                id: slider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                stepSize: 0.01
                value: root.volume
                // onMoved, not onValueChanged: see the signal comment above.
                onMoved: root.moved(value)

                implicitHeight: 12

                background: Rectangle {
                    y: (slider.height - height) / 2
                    width: slider.availableWidth
                    implicitHeight: 5
                    radius: 2.5
                    color: Modules.Theme.trough

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 2.5
                        color: root.muted ? Modules.Theme.inactive : Modules.Theme.foreground

                        Behavior on width {
                            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // A knob, so the bar reads as something you can drag. The ring
                // in the background colour keeps it legible on top of the fill.
                handle: Rectangle {
                    x: slider.visualPosition * (slider.availableWidth - width)
                    y: (slider.height - height) / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: root.muted ? Modules.Theme.inactive : Modules.Theme.foreground
                    border.width: 2
                    border.color: Modules.Theme.background
                    scale: slider.pressed || hover.hovered ? 1.0 : 0.82

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
