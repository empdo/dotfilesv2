// NetworkList.qml -- the Network half of the settings menu: the wired
// connection pinned at the top, then the Wi-Fi networks below it.
//
// The wired row sits outside the ListView on purpose, so scrolling a long list
// of access points never pushes the connection you are actually using offscreen.
//
// Owns its own scanning: the list only searches while it is on screen, because
// scanning costs power. Declared as a Binding rather than set from a change
// handler, since the list is usually built with `active` already true.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "."
import "../" as Modules

Item {
    id: root

    property bool active: false

    Binding {
        target: ConnectivityService.wifiDevice
        property: "scannerEnabled"
        value: root.active && ConnectivityService.wifiEnabled
        when: ConnectivityService.wifiDevice !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    function activate(net) {
        if (net.connected)
            net.disconnect();
        else if (net.known)
            net.connect();
        else if (ConnectivityService.isSecured(net))
            WifiPrompt.ask(net);
        else
            net.connect();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        ListRow {
            Layout.fillWidth: true
            visible: ConnectivityService.wiredDevice !== null
            glyph: "󰈀"
            title: ConnectivityService.wiredDevice
                   ? ConnectivityService.wiredDevice.name : ""
            subtitle: {
                const d = ConnectivityService.wiredDevice;
                if (!d)
                    return "";
                if (!d.hasLink)
                    return "Cable unplugged";
                return d.connected
                     ? "Connected \u00B7 " + Math.round(d.linkSpeed) + " Mb/s"
                     : "Not connected";
            }
            active: ConnectivityService.wiredConnected
            // Wired comes up on its own; clicking could only drop it by
            // accident, so this row is display-only.
            onClicked: {}
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                visible: ConnectivityService.wifiEnabled
                         && ConnectivityService.wifiNetworks.length > 0
                clip: true
                model: ConnectivityService.wifiNetworks
                spacing: 1
                ScrollBar.vertical: ScrollBar {}

                delegate: ListRow {
                    required property var modelData

                    width: list.width
                    glyph: ConnectivityService.wifiGlyph(modelData.signalStrength)
                    title: modelData.name
                    subtitle: (modelData.connected ? "Connected"
                                                   : modelData.known ? "Saved"
                                                   : ConnectivityService.securityLabel(modelData))
                              + " \u00B7 " + ConnectivityService.signalPercent(modelData.signalStrength)
                    trailing: ConnectivityService.isSecured(modelData) ? "\uF023" : ""   // nf-fa-lock
                    active: modelData.connected
                    busy: modelData.stateChanging

                    onClicked: root.activate(modelData)
                    onSecondaryClicked: if (modelData.known) modelData.forget()
                }
            }

            Label {
                anchors.centerIn: parent
                visible: !list.visible
                text: !ConnectivityService.hasWifi ? "No Wi-Fi adapter"
                    : !ConnectivityService.wifiEnabled ? "Wi-Fi is off"
                    : "Scanning\u2026"
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 12
            }
        }
    }
}
