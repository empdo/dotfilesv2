import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../" as Modules

Item {
    id: root
    implicitWidth: 220
    implicitHeight: 240

    property var popup
    property color textColor: "#ebffd9"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8

        Label {
            text: "Volume"
            color: textColor
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Modules.AudioService.muted ? "Muted" : Math.round(Modules.AudioService.volume * 100) + "%"
            color: "#ebffd9"
            font.pixelSize: 18
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#444"
            Layout.topMargin: 6
            Layout.bottomMargin: 6
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Layout.topMargin: 6
            Text {
                id: muteIcon
                text: Modules.AudioService.muted ? "󰟦" : "󰟥"
                color: textColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 14
                Layout.minimumWidth: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: Modules.AudioService.toggleMute()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Slider {
                id: slider
                from: 0.0
                to: 1.0
                stepSize: 0.01
                Layout.preferredWidth: 140
                value: Modules.AudioService.volume
                onValueChanged: Modules.AudioService.setVolume(value)
                height: 20
                hoverEnabled: true

                background: Rectangle {
                    implicitHeight: 6
                    radius: 3
                    color: "#333"
                    z: -1

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: Modules.AudioService.muted ? "#666" : textColor
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                handle: null
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Layout.topMargin: 6
            Text {
                id: muteIcon2
                text: Modules.AudioService.muted ? "" : ""
                color: textColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 14
                Layout.minimumWidth: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: Modules.AudioService.toggleMute()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Slider {
                id: slider2
                from: 0.0
                to: 1.0
                stepSize: 0.01
                Layout.preferredWidth: 140
                value: Modules.AudioService.volume
                onValueChanged: Modules.AudioService.setVolume(value)
                height: 20
                hoverEnabled: true

                background: Rectangle {
                    implicitHeight: 6
                    radius: 3
                    color: "#333"
                    z: -1

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: Modules.AudioService.muted ? "#666" : textColor
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                handle: null
            }
        }
        MouseArea {
            hoverEnabled: true

            onExited: {
                root.popup.hidePopup();
            }
        }
    }
}
