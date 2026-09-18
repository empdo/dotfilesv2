// Bar.qml
import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

import "."

import "modules/clock"
import "modules/power"
import "modules/theme"
import "modules/tray"
import "modules/volume"
import "modules/wallpaper"
import "modules" as Modules

Scope {
    property color textColor: Modules.Theme.foreground
    property color backgroundColor: Modules.Theme.background

    PanelWindow {
        id: bar

        exclusiveZone: 60
        color: "transparent"

        anchors {
            top: true
            left: true
            bottom: true
        }
        implicitWidth: 60

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 100
            }
        }


        Row {
            id: mainRow
            anchors.fill: parent
            spacing: 0
            clip: false

            Rectangle {
                id: barArea
                width: 60
                height: parent.height
                color: backgroundColor
                z: 10
                clip: false

                // right border
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 1
                    color: textColor
                    opacity: 0.8
                }

                Item {
                    anchors.fill: parent

                    // TOP: workspaces
                    WorkspacesWidget {
                        id: workspaces
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // BELOW WORKSPACES: system tray popup
                    ExpandableItem {
                        id: trayExpandable
                        barWindow: bar
                        iconComponent: TrayIcon {}
                        popupContent: Component {
                            TrayPopup {
                                onMenuOpenChanged: trayExpandable.keepOpen = menuOpen
                            }
                        }

                        anchors.top: workspaces.bottom
                        anchors.topMargin: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // ABOVE CLOCK: volume
                    ExpandableItem {
                        id: volumeItem
                        barWindow: bar
                        iconComponent: VolumeWidget {}
                        popupContent: Component {
                            VolumePopup {}
                        }

                        anchors.bottom: clockItem.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 15
                    }


                    // BOTTOM: clock
                    ExpandableItem {
                        id: clockItem
                        barWindow: bar
                        iconComponent: ClockWidget {}
                        popupContent: Component {
                            CalendarPopup {}
                        }

                        anchors.bottom: powerIcon.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    ExpandableItem {
                        id: wallpaperItem 
                        barWindow: bar
                        iconComponent: WallpaperIcon{}
                        popupContent: Component {
                            WallpaperPopup{}
                        }

                        anchors.centerIn: parent
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // BELOW WALLPAPER: light/dark toggle
                    ThemeToggle {
                        id: themeToggle
                        anchors.top: wallpaperItem.bottom
                        anchors.topMargin: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    ExpandableItem {
                        id: powerIcon
                        barWindow: bar
                        smoothBottom: true
                        iconComponent: PowerWidget {}
                        popupContent: Component {
                            PowerPopup {}
                        }

                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 25
                    }
                }
            }
        }
    }
}
