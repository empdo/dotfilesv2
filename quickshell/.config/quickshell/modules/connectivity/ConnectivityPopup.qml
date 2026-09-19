// ConnectivityPopup.qml -- the bar menu for Wi-Fi and Bluetooth.
//
// Left click a row to do the obvious thing (connect, or disconnect if it is
// already connected); right click to forget it. Passphrases are handled by
// WifiPrompt, which is its own focusable overlay -- see that file for why.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import "."
import "../" as Modules

Item {
    id: root

    // Driven by the bar's ExpandableItem: scanning runs only while on screen.
    property bool active: false
    // Keeps the bar popup pinned while the passphrase overlay is up.
    readonly property bool holdOpen: WifiPrompt.open

    implicitWidth: 340
    implicitHeight: 470


    // Scanning costs power and, for bluetooth, can disturb connected audio, so
    // both radios only search while the menu is on screen. Declared as Bindings
    // rather than set from onActiveChanged: the popup is built with `active`
    // already true, so a change handler would never fire the first time.
    Binding {
        target: ConnectivityService.wifiDevice
        property: "scannerEnabled"
        value: root.active && ConnectivityService.wifiEnabled
        when: ConnectivityService.wifiDevice !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: ConnectivityService.btAdapter
        property: "discovering"
        value: root.active && ConnectivityService.btEnabled
        when: ConnectivityService.btAdapter !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    // --- actions -------------------------------------------------------------

    function activateNetwork(net) {
        if (net.connected)
            net.disconnect();
        else if (net.known)
            net.connect();
        else if (ConnectivityService.isSecured(net))
            WifiPrompt.ask(net);
        else
            net.connect();
    }

    function activateDevice(dev) {
        if (dev.connected)
            dev.disconnect();
        else if (dev.paired || dev.bonded)
            dev.connect();
        else
            dev.pair();
    }

    function deviceBusy(dev) {
        return dev.pairing
            || dev.state === BluetoothDeviceState.Connecting
            || dev.state === BluetoothDeviceState.Disconnecting;
    }

    function deviceSubtitle(dev) {
        const bits = [];
        if (dev.connected)
            bits.push("Connected");
        else if (dev.paired || dev.bonded)
            bits.push("Paired");
        if (dev.batteryAvailable)
            bits.push(Math.round(dev.battery * 100) + "%");
        return bits.join(" · ");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        // ---- network -------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Network"
                color: Modules.Theme.foreground
                font.family: "Roboto Mono"
                font.pixelSize: 15
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Label {
                text: ConnectivityService.statusLabel
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 140
            }

            Toggle {
                checked: ConnectivityService.wifiEnabled
                enabled: ConnectivityService.hasWifi
                onToggled: ConnectivityService.toggleWifi()
            }
        }

        // The cable, when there is one. Shown above Wi-Fi because it is what
        // the machine is actually using whenever it is plugged in.
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
                     ? "Connected · " + Math.round(d.linkSpeed) + " Mb/s"
                     : ConnectionState.toString(d.state);
            }
            active: ConnectivityService.wiredConnected
            // Wired connections come up on their own; clicking would only ever
            // drop one by accident, so this row is display-only.
            onClicked: {}
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1   // share the spare height with bluetooth

            ListView {
                id: wifiList
                anchors.fill: parent
                visible: ConnectivityService.wifiEnabled
                         && ConnectivityService.wifiNetworks.length > 0
                clip: true
                model: ConnectivityService.wifiNetworks
                spacing: 1
                ScrollBar.vertical: ScrollBar {}

                delegate: ListRow {
                    required property var modelData

                    width: wifiList.width
                    glyph: ConnectivityService.wifiGlyph(modelData.signalStrength)
                    title: modelData.name
                    subtitle: (modelData.connected ? "Connected"
                                                  : modelData.known ? "Saved"
                                                  : ConnectivityService.securityLabel(modelData))
                              + " · " + ConnectivityService.signalPercent(modelData.signalStrength)
                    trailing: ConnectivityService.isSecured(modelData) ? "" : ""
                    active: modelData.connected
                    busy: modelData.stateChanging

                    onClicked: root.activateNetwork(modelData)
                    onSecondaryClicked: if (modelData.known) modelData.forget()
                }
            }

            Label {
                anchors.centerIn: parent
                visible: !wifiList.visible
                text: !ConnectivityService.hasWifi ? "No Wi-Fi adapter"
                    : !ConnectivityService.wifiEnabled ? "Wi-Fi is off"
                    : "Scanning…"
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Modules.Theme.divider
        }

        // ---- bluetooth -----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Bluetooth"
                color: Modules.Theme.foreground
                font.family: "Roboto Mono"
                font.pixelSize: 15
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Label {
                text: {
                    if (!ConnectivityService.hasBluetooth)
                        return "No adapter";
                    if (!ConnectivityService.btEnabled)
                        return "Off";
                    const n = ConnectivityService.btConnected.length;
                    if (n > 0)
                        return n + " connected";
                    return ConnectivityService.btDevices.length > 0
                         ? "Not connected" : "No devices";
                }
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 11
            }

            Toggle {
                checked: ConnectivityService.btEnabled
                enabled: ConnectivityService.hasBluetooth
                onToggled: ConnectivityService.toggleBluetooth()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1

            ListView {
                id: btList
                anchors.fill: parent
                visible: ConnectivityService.btEnabled
                         && ConnectivityService.btDevices.length > 0
                clip: true
                model: ConnectivityService.btDevices
                spacing: 1
                ScrollBar.vertical: ScrollBar {}

                delegate: ListRow {
                    required property var modelData

                    width: btList.width
                    glyph: modelData.connected ? "󰂱" : "󰂯"
                    title: modelData.name || modelData.deviceName || modelData.address
                    subtitle: root.deviceSubtitle(modelData)
                    trailing: modelData.batteryAvailable ? "󰁹" : ""
                    active: modelData.connected
                    busy: root.deviceBusy(modelData)

                    onClicked: root.activateDevice(modelData)
                    onSecondaryClicked: if (modelData.paired || modelData.bonded) modelData.forget()
                }
            }

            Label {
                anchors.centerIn: parent
                visible: !btList.visible
                text: !ConnectivityService.hasBluetooth ? "No Bluetooth adapter"
                    : !ConnectivityService.btEnabled ? "Bluetooth is off"
                    : "Searching…"
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 12
            }
        }

        Label {
            Layout.fillWidth: true
            text: "click connect · right click forget"
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
