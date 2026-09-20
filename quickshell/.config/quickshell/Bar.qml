// Bar.qml
//
// One bar, either way round. A vertical bar hugs the left edge of its screen;
// a horizontal one runs across the bottom. Everything orientation-dependent is
// threaded down through `horizontal`, so the two stay the same bar rather than
// drifting into two that have to be kept in step.
import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

import "."

import "modules/clock"
import "modules/components"
import "modules/media"
import "modules/notifications"
import "modules/power"
import "modules/settings"
import "modules/tray"
import "modules/volume"
import "modules" as Modules

Scope {
    id: root

    // Which output this bar belongs to, and which edge of it it runs along.
    property var screen: null
    property bool horizontal: false

    readonly property int thickness: 60

    property color textColor: Modules.Theme.foreground
    property color backgroundColor: Modules.Theme.background

    PanelWindow {
        id: bar

        screen: root.screen
        exclusiveZone: root.thickness
        color: "transparent"

        // Three edges either way: the bar spans the screen along its own
        // length and clings to the one edge it lives on.
        anchors {
            top: !root.horizontal
            left: true
            right: root.horizontal
            bottom: true
        }
        implicitWidth: root.horizontal ? 0 : root.thickness
        implicitHeight: root.horizontal ? root.thickness : 0

        Rectangle {
            id: barArea
            anchors.fill: parent
            color: root.backgroundColor
            z: 10
            clip: false

            // The edge facing the rest of the screen.
            Rectangle {
                visible: !root.horizontal
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: root.textColor
                opacity: 0.8
            }

            Rectangle {
                visible: root.horizontal
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: root.textColor
                opacity: 0.8
            }

            Item {
                anchors.fill: parent

                // Items are grouped into capsules (see BarSection.qml) so the
                // bar reads as a few groups rather than eight loose icons.
                // Children of a section must not set their own anchors -- the
                // section lays them out itself.

                // START: the cat, workspaces, the tray and notifications
                BarSection {
                    horizontal: root.horizontal
                    thickness: root.thickness
                    capsule: false

                    anchors.top: root.horizontal ? undefined : parent.top
                    anchors.topMargin: root.horizontal ? 0 : 8
                    anchors.left: root.horizontal ? parent.left : undefined
                    anchors.leftMargin: root.horizontal ? 8 : 0
                    anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined

                    // Furthest along, where the Arch logo used to be.
                    //Item {
                    //    implicitWidth: 60
                    //    implicitHeight: 34

                    //    CatIcon {
                    //        anchors.centerIn: parent
                    //        width: 40
                    //        height: 40
                    //    }
                    //}

                    WorkspacesWidget {
                        horizontal: root.horizontal
                        thickness: root.thickness
                    }

                    ExpandableItem {
                        id: trayExpandable
                        barWindow: bar
                        horizontal: root.horizontal
                        iconComponent: TrayIcon {}
                        popupContent: Component {
                            TrayPopup {
                                onMenuOpenChanged: trayExpandable.keepOpen = menuOpen
                            }
                        }
                    }

                    ExpandableItem {
                        id: notificationItem
                        barWindow: bar
                        horizontal: root.horizontal
                        iconComponent: NotificationWidget {}
                        popupContent: Component {
                            NotificationPopup {
                                // Opening the list is what clears the badge.
                                active: notificationItem.open
                            }
                        }
                    }
                }

                // CENTRE: what is playing. The whole capsule goes away when
                // nothing is, rather than leaving an empty one. Centred on
                // both axes, which is the middle of the bar either way round.
                BarSection {
                    horizontal: root.horizontal
                    thickness: root.thickness
                    visible: MediaService.hasPlayers
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    ExpandableItem {
                        id: mediaItem
                        barWindow: bar
                        horizontal: root.horizontal
                        iconComponent: MediaWidget {}
                        popupContent: Component {
                            MediaPopup {}
                        }
                    }
                }

                // JUST BEFORE THE CONTROLS: the clock, on its own
                BarSection {
                    horizontal: root.horizontal
                    thickness: root.thickness
                    capsule: false

                    anchors.bottom: root.horizontal ? undefined : controlsSection.top
                    anchors.right: root.horizontal ? controlsSection.left : undefined
                    anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined

                    ExpandableItem {
                        id: clockItem
                        barWindow: bar
                        horizontal: root.horizontal
                        iconComponent: ClockWidget {}
                        popupContent: Component {
                            CalendarPopup {}
                        }
                    }
                }

                // END: audio, quick settings and power
                //
                // On a vertical bar these sit low enough that a popup centred
                // on the icon would run off the bottom of the screen, so all
                // three pin theirs to that edge instead. A horizontal bar has
                // no such trouble -- its popups are clamped along the bar.
                BarSection {
                    id: controlsSection
                    horizontal: root.horizontal
                    thickness: root.thickness

                    anchors.bottom: root.horizontal ? undefined : parent.bottom
                    anchors.bottomMargin: root.horizontal ? 0 : 12
                    anchors.right: root.horizontal ? parent.right : undefined
                    anchors.rightMargin: root.horizontal ? 12 : 0
                    anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined

                    ExpandableItem {
                        id: volumeItem
                        barWindow: bar
                        horizontal: root.horizontal
                        smoothBottom: !root.horizontal
                        iconComponent: VolumeWidget {}
                        popupContent: Component {
                            VolumePopup {}
                        }
                    }

                    ExpandableItem {
                        id: settingsItem
                        barWindow: bar
                        horizontal: root.horizontal
                        smoothBottom: !root.horizontal
                        iconComponent: SettingsWidget {}
                        popupContent: Component {
                            SettingsPopup {
                                // Scan only while the menu is on screen, and
                                // keep it pinned while the passphrase overlay
                                // is up.
                                active: settingsItem.open
                                onHoldOpenChanged: settingsItem.keepOpen = holdOpen
                            }
                        }
                    }

                    ExpandableItem {
                        id: powerIcon
                        barWindow: bar
                        horizontal: root.horizontal
                        smoothBottom: !root.horizontal
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
