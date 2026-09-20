// SettingsPopup.qml -- the quick settings menu behind the bar's gear icon.
//
// Quick settings across the top, then the two device lists side by side:
// Network on the left, Bluetooth on the right. Each list's radio switch sits
// beside its heading, so the switch is next to what it actually controls.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "."
import "../clipboard"
import "../connectivity"
import "../wallpaper"
import "../" as Modules

Item {
    id: root

    // Driven by the bar's ExpandableItem: the lists scan only while on screen.
    property bool active: false
    // Keeps the bar popup pinned while the passphrase overlay is up.
    readonly property bool holdOpen: WifiPrompt.open

    implicitWidth: 700
    implicitHeight: 470

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ---- quick settings ------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SettingTile {
                glyph: Modules.Theme.light ? "󰖨" : "󰖔"
                title: "Theme"
                value: Modules.Theme.light ? "Light" : "Dark"
                onClicked: Modules.Theme.toggle()
            }

            SettingTile {
                glyph: ""
                title: "Wallpaper"
                value: WallpaperPanel.currentName || "Choose\u2026"
                onClicked: WallpaperPanel.toggle()
            }

            SettingTile {
                glyph: "\uF0EA"        // nf-fa-paste
                title: "Clipboard"
                value: ClipboardService.hasEntries
                     ? ClipboardService.entries.length + " saved"
                     : "Empty"
                onClicked: ClipboardService.toggle()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Modules.Theme.divider
        }

        // ---- the two device lists, side by side ----------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1   // equal halves
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Network"
                        color: Modules.Theme.foreground
                        font.family: "Roboto Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Toggle {
                        checked: ConnectivityService.wifiEnabled
                        enabled: ConnectivityService.hasWifi
                        onToggled: ConnectivityService.toggleWifi()
                    }
                }

                NetworkList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.active
                }
            }

            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Modules.Theme.divider
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Bluetooth"
                        color: Modules.Theme.foreground
                        font.family: "Roboto Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Toggle {
                        checked: ConnectivityService.btEnabled
                        enabled: ConnectivityService.hasBluetooth
                        onToggled: ConnectivityService.toggleBluetooth()
                    }
                }

                BluetoothList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.active
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: "click connect \u00B7 right click forget"
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
