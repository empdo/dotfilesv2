// modules/connectivity/ConnectivityService.qml
//
// One place to ask about the machine's connectivity, so the bar icon and the
// popup never disagree. Everything here comes from Quickshell's native
// NetworkManager and BlueZ bindings -- no nmcli/bluetoothctl shelling out.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

Singleton {
    id: root

    // --- network devices -----------------------------------------------------

    readonly property var devices: Networking.devices ? Networking.devices.values : []

    readonly property var wifiDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }

    readonly property var wiredDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wired)
                return d;
        return null;
    }

    readonly property bool hasWifi: wifiDevice !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wiredConnected: wiredDevice ? wiredDevice.connected : false

    // --- wifi networks -------------------------------------------------------

    // NetworkManager can report one entry per access point, so several rows can
    // share an SSID. Keep the strongest of each, then put the connected network
    // first, saved ones next, and the rest by signal -- the order you would
    // actually pick from.
    readonly property var wifiNetworks: {
        if (!wifiDevice || !wifiDevice.networks)
            return [];

        const best = {};
        for (const n of wifiDevice.networks.values) {
            if (!n || !n.name)          // hidden SSIDs have nothing to show
                continue;
            const prev = best[n.name];
            if (!prev || n.signalStrength > prev.signalStrength || n.connected)
                best[n.name] = n;
        }

        const out = Object.keys(best).map(k => best[k]);
        out.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return out;
    }

    readonly property var activeWifi: {
        for (const n of wifiNetworks)
            if (n.connected)
                return n;
        return null;
    }

    // --- bluetooth -----------------------------------------------------------

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool hasBluetooth: btAdapter !== null
    readonly property bool btEnabled: btAdapter ? btAdapter.enabled : false

    // Connected first, then paired, then whatever the scan turned up.
    readonly property var btDevices: {
        if (!btAdapter || !btAdapter.devices)
            return [];

        const out = btAdapter.devices.values.filter(d => d && (d.name || d.deviceName));
        out.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return out;
    }

    readonly property var btConnected: btDevices.filter(d => d.connected)

    // --- actions -------------------------------------------------------------

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth() {
        if (btAdapter)
            btAdapter.enabled = !btAdapter.enabled;
    }

    // --- presentation helpers ------------------------------------------------

    // Nerd Font signal bars. Quickshell reports signalStrength as 0.0-1.0,
    // not NetworkManager's 0-100.
    function wifiGlyph(strength) {
        if (strength >= 0.75) return "󰤨";
        if (strength >= 0.50) return "󰤥";
        if (strength >= 0.25) return "󰤢";
        if (strength > 0)     return "󰤟";
        return "󰤯";
    }

    function signalPercent(strength) {
        return Math.round(strength * 100) + "%";
    }

    function isSecured(network) {
        return network.security !== undefined
            && network.security !== WifiSecurityType.Open;
    }

    function securityLabel(network) {
        return root.isSecured(network)
             ? WifiSecurityType.toString(network.security)
             : "Open";
    }

    // What the bar icon shows: the connection actually carrying traffic wins.
    readonly property string statusGlyph: {
        if (wiredConnected)
            return "󰈀";
        if (activeWifi)
            return wifiGlyph(activeWifi.signalStrength);
        if (!hasWifi)
            return "󰈂";          // no wifi hardware and no cable
        return wifiEnabled ? "󰤯" : "󰤮";
    }

    readonly property string statusLabel: {
        if (wiredConnected)
            return "Wired";
        if (activeWifi)
            return activeWifi.name;
        if (hasWifi && !wifiEnabled)
            return "Wi-Fi off";
        return "Offline";
    }

    readonly property bool online: wiredConnected || activeWifi !== null
}
