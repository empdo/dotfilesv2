// PowerPopup.qml -- log out, suspend, shut down.
//
// These used to be three bare glyphs with no handlers at all, so the menu
// looked functional but did nothing.
//
// Every action needs two clicks. The popup opens on hover, so a single click
// would put a stray mouse one twitch away from shutting the machine down; the
// first click arms an action and says so, and it disarms itself after a moment.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../components"
import "../" as Modules

Item {
    id: root

    property color textColor: Modules.Theme.foreground

    // hyprland.service exists but is not what is running -- this session was
    // started from a TTY login, so stopping that unit would do nothing.
    // Exiting the compositor is the reliable logout. The config is in Lua mode,
    // where hyprctl dispatch takes a dispatcher object rather than a string.
    readonly property var actions: [
        {
            glyph: "󰍃",
            label: "Log out",
            command: ["hyprctl", "dispatch", "hl.dsp.exit()"]
        },
        {
            glyph: "󰒲",
            label: "Sleep",
            command: ["systemctl", "suspend"]
        },
        {
            glyph: "\uF011",      // nf-fa-power_off
            label: "Shut down",
            command: ["systemctl", "poweroff"]
        }
    ]

    property int armed: -1

    implicitWidth: 240
    implicitHeight: 96

    function trigger(index) {
        if (root.armed !== index) {
            root.armed = index;
            disarm.restart();
            return;
        }
        disarm.stop();
        root.armed = -1;
        Quickshell.execDetached(root.actions[index].command);
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    // Leaving the popup cancels whatever was armed, so it is never left
    // primed for the next time it opens.
    onVisibleChanged: if (!visible) root.armed = -1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Repeater {
            model: root.actions

            delegate: Item {
                id: entry
                required property var modelData
                required property int index

                readonly property bool isArmed: root.armed === entry.index

                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: entry.isArmed ? Modules.Theme.trough
                         : mouse.containsMouse ? Modules.Theme.trough : "transparent"
                    opacity: entry.isArmed ? 1.0 : 0.5
                    border.width: entry.isArmed ? 1 : 0
                    border.color: Modules.Theme.foreground

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: entry.modelData.glyph
                        color: root.textColor
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 21

                        scale: mouse.containsMouse ? 1.15 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: entry.isArmed ? "Confirm?" : entry.modelData.label
                        color: entry.isArmed ? root.textColor : Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 10
                        font.bold: entry.isArmed
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.trigger(entry.index)
                    // Moving away from a primed button cancels it.
                    onExited: if (entry.isArmed) root.armed = -1
                }
            }
        }
    }
}
