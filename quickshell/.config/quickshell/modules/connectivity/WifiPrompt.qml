// WifiPrompt.qml -- asks for a Wi-Fi passphrase.
//
// This is a separate layershell overlay rather than part of the bar popup
// because a PopupWindow anchored to the bar cannot take keyboard focus, and
// the bar popup closes as soon as the pointer leaves it -- neither of which
// works for typing a password. A singleton so any part of the popup can call
// WifiPrompt.ask(network) without threading a reference through.
pragma Singleton

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import "../" as Modules

Singleton {
    id: root

    property var network: null
    property bool open: false
    property string error: ""
    // "input" while typing, "connecting" once the passphrase has been handed
    // to NetworkManager.
    property string phase: "input"

    signal finished

    function ask(net) {
        network = net;
        error = "";
        phase = "input";
        field.text = "";
        open = true;
    }

    function cancel() {
        open = false;
        network = null;
        phase = "input";
        field.text = "";
        root.finished();
    }

    function submit() {
        if (!network || field.text.length === 0)
            return;
        phase = "connecting";
        error = "";
        // NetworkManager reports Disconnected briefly before it starts
        // associating, so ignore the state for a moment after submitting.
        settle.restart();
        network.connectWithPsk(field.text);
    }

    Timer {
        id: settle
        interval: 2000
    }

    // Watches the network being connected to, so the prompt can close itself on
    // success and say something useful on failure.
    Connections {
        target: root.open ? root.network : null
        ignoreUnknownSignals: true

        function onConnectedChanged() {
            if (root.network && root.network.connected)
                root.cancel();
        }

        function onStateChanged() {
            if (root.phase !== "connecting" || settle.running)
                return;
            if (root.network && root.network.state === ConnectionState.Disconnected) {
                root.phase = "input";
                root.error = "Could not connect. Check the password.";
                field.selectAll();
                field.forceActiveFocus();
            }
        }
    }

    PanelWindow {
        id: overlay
        visible: root.open
        color: "transparent"

        anchors { top: true; left: true; right: true; bottom: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:wifi-prompt"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: root.cancel()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 420
            implicitHeight: column.implicitHeight + 44
            radius: 18
            color: Modules.Theme.background
            border.width: 1
            border.color: Modules.Theme.foreground

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 22
                spacing: 14

                Label {
                    Layout.fillWidth: true
                    text: root.network ? root.network.name : ""
                    color: Modules.Theme.foreground
                    font.family: "Roboto Mono"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    text: root.phase === "connecting"
                          ? "Connecting…"
                          : (root.error !== "" ? root.error : "Enter the network password")
                    color: root.error !== "" ? Modules.Theme.foreground : Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                // The password line: a bare TextInput on a trough, matching the
                // launcher rather than pulling in a themed Controls TextField.
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 8
                    color: Modules.Theme.trough

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        TextInput {
                            id: field
                            Layout.fillWidth: true
                            enabled: root.phase === "input"
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 15
                            selectionColor: Modules.Theme.divider
                            selectedTextColor: Modules.Theme.foreground
                            echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
                            focus: true

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.cancel();
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.submit();
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }

                        Label {
                            id: reveal
                            property bool checked: false

                            text: checked ? "󰈈" : "󰈉"
                            color: Modules.Theme.inactive
                            font.family: "Symbols Nerd Font Mono"
                            font.pixelSize: 14

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: reveal.checked = !reveal.checked
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "⏎ connect    Esc cancel"
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Connections {
            target: root
            function onOpenChanged() {
                if (root.open)
                    field.forceActiveFocus();
            }
        }
    }
}
