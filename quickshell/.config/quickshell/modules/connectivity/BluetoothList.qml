// BluetoothList.qml -- the Bluetooth half of the settings menu.
//
// Discovery runs only while the list is on screen: scanning can disturb audio
// on already-connected devices.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import "."
import "../" as Modules

Item {
    id: root

    property bool active: false

    // BlueZ rejects discovery calls that land on top of each other
    // ("Resource Not Ready", "Operation already in progress"), which is easy to
    // provoke by sweeping the pointer across the bar. Let `active` settle first.
    property bool discoverWanted: false
    onActiveChanged: settle.restart()
    // The list is usually built with `active` already true, and a change
    // handler never fires for that, so kick the timer on creation too.
    Component.onCompleted: settle.restart()

    Timer {
        id: settle
        interval: 400
        onTriggered: root.discoverWanted = root.active
    }

    Binding {
        target: ConnectivityService.btAdapter
        property: "discovering"
        value: root.discoverWanted && ConnectivityService.btEnabled
        when: ConnectivityService.btAdapter !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    function activate(dev) {
        if (dev.connected)
            dev.disconnect();
        else if (dev.paired || dev.bonded)
            dev.connect();
        else
            dev.pair();
    }

    function busy(dev) {
        return dev.pairing
            || dev.state === BluetoothDeviceState.Connecting
            || dev.state === BluetoothDeviceState.Disconnecting;
    }

    function subtitle(dev) {
        const bits = [];
        if (dev.connected)
            bits.push("Connected");
        else if (dev.paired || dev.bonded)
            bits.push("Paired");
        if (dev.batteryAvailable)
            bits.push(Math.round(dev.battery * 100) + "%");
        return bits.join(" · ");
    }

    ListView {
        id: list
        anchors.fill: parent
        visible: ConnectivityService.btEnabled
                 && ConnectivityService.btDevices.length > 0
        clip: true
        model: ConnectivityService.btDevices
        spacing: 1
        ScrollBar.vertical: ScrollBar {}

        delegate: ListRow {
            required property var modelData

            width: list.width
            glyph: modelData.connected ? "󰂱" : "󰂯"
            title: modelData.name || modelData.deviceName || modelData.address
            subtitle: root.subtitle(modelData)
            trailing: modelData.batteryAvailable ? "󰁹" : ""
            active: modelData.connected
            busy: root.busy(modelData)

            onClicked: root.activate(modelData)
            onSecondaryClicked: if (modelData.paired || modelData.bonded) modelData.forget()
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !list.visible
        text: !ConnectivityService.hasBluetooth ? "No Bluetooth adapter"
            : !ConnectivityService.btEnabled ? "Bluetooth is off"
            : "Searching…"
        color: Modules.Theme.inactive
        font.family: "Roboto Mono"
        font.pixelSize: 12
    }
}
