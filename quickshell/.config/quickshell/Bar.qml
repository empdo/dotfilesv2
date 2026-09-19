// Bar.qml
import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

import "."

import "modules/clock"
import "modules/media"
import "modules/power"
import "modules/settings"
import "modules/tray"
import "modules/volume"
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

                    // Items are grouped into capsules (see BarSection.qml) so
                    // the bar reads as a few groups rather than eight loose
                    // icons. Children of a section must not set their own
                    // anchors -- the section lays them out in a Column.

                    // TOP: workspaces and the system tray
                    BarSection {
                        capsule: false
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        WorkspacesWidget {}

                        ExpandableItem {
                            id: trayExpandable
                            barWindow: bar
                            iconComponent: TrayIcon {}
                            popupContent: Component {
                                TrayPopup {
                                    onMenuOpenChanged: trayExpandable.keepOpen = menuOpen
                                }
                            }
                        }
                    }

                    // CENTRE: what is playing. The whole capsule goes away
                    // when nothing is, rather than leaving an empty one.
                    BarSection {
                        visible: MediaService.hasPlayers
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                        ExpandableItem {
                            id: mediaItem
                            barWindow: bar
                            iconComponent: MediaWidget {}
                            popupContent: Component {
                                MediaPopup {}
                            }
                        }
                    }

                    // ABOVE THE CONTROLS: the clock, on its own
                    BarSection {
                        capsule: false
                        anchors.bottom: controlsSection.top
                        anchors.bottomMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter

                        ExpandableItem {
                            id: clockItem
                            barWindow: bar
                            iconComponent: ClockWidget {}
                            popupContent: Component {
                                CalendarPopup {}
                            }
                        }
                    }

                    // BOTTOM: audio, quick settings and power
                    //
                    // Everything here sits low enough that a popup centred on
                    // its icon would run off the bottom of the screen, so all
                    // three pin theirs to the bottom edge instead.
                    BarSection {
                        id: controlsSection
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        anchors.horizontalCenter: parent.horizontalCenter

                        ExpandableItem {
                            id: volumeItem
                            barWindow: bar
                            smoothBottom: true
                            iconComponent: VolumeWidget {}
                            popupContent: Component {
                                VolumePopup {}
                            }
                        }

                        ExpandableItem {
                            id: settingsItem
                            barWindow: bar
                            smoothBottom: true
                            iconComponent: SettingsWidget {}
                            popupContent: Component {
                                SettingsPopup {
                                    // Scan only while the menu is on screen, and
                                    // keep it pinned while the passphrase
                                    // overlay is up.
                                    active: settingsItem.open
                                    onHoldOpenChanged: settingsItem.keepOpen = holdOpen
                                }
                            }
                        }

                        ExpandableItem {
                            id: powerIcon
                            barWindow: bar
                            smoothBottom: true
                            iconComponent: PowerWidget {}
                            popupContent: Component {
                                PowerPopup {}
                            }
                        }
                    }
                }
            }
        }
    }
}
