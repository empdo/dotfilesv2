// modules/polkit/PolkitPrompt.qml -- the polkit authentication agent.
//
// polkitd was running on this machine with no agent registered against it,
// which fails quietly: anything asking for privilege got no dialog and no
// error, it simply never happened. This is the missing half.
//
// It is a focused layershell overlay for the same reason WifiPrompt is one --
// a password needs keyboard focus, which a bar popup cannot take -- and it
// looks like the launcher because it is the same shape of thing: a card in the
// middle of a dimmed screen that takes one line of input.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import "../" as Modules

Scope {
    id: root

    readonly property var flow: agent.flow
    readonly property bool open: flow !== null && !flow.isCompleted

    // polkit describes who may authorise the action. Usually that is one
    // account and there is nothing to choose, so the picker only appears when
    // there is an actual choice to make.
    readonly property var identities: flow ? flow.identities : []
    readonly property bool choosing: identities.length > 1

    function identityLabel(identity) {
        if (!identity)
            return "";
        return identity.userName || identity.name || identity.displayName || "account";
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            field.text = "";
            // The overlay is mapped when `open` flips, so focus is taken after
            // the fact rather than at construction.
            Qt.callLater(() => field.forceActiveFocus());
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        // A wrong password starts the exchange again rather than ending it, so
        // the field has to be emptied for the retry.
        function onRequest(message, echo) {
            field.text = "";
            Qt.callLater(() => field.forceActiveFocus());
        }
    }

    function submit() {
        if (!root.flow || !root.flow.isResponseRequired)
            return;
        root.flow.submit(field.text);
        field.text = "";
    }

    function cancel() {
        if (root.flow)
            root.flow.cancelAuthenticationRequest();
        field.text = "";
    }

    PanelWindow {
        id: overlay
        visible: root.open
        color: "transparent"

        anchors { top: true; left: true; right: true; bottom: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:polkit"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5

            // Clicking away from a privilege prompt cancels it rather than
            // leaving it parked behind whatever asked for it.
            MouseArea {
                anchors.fill: parent
                onClicked: root.cancel()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 120, 460)
            implicitHeight: layout.implicitHeight + 44
            height: implicitHeight
            radius: 18
            color: Modules.Theme.background
            border.width: 1
            border.color: Modules.Theme.foreground

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: layout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 22
                spacing: 14

                // ---- what is being asked ---------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        Layout.alignment: Qt.AlignTop

                        readonly property string iconSource:
                            root.flow ? Quickshell.iconPath(root.flow.iconName, true) : ""

                        Image {
                            id: icon
                            anchors.fill: parent
                            source: parent.iconSource
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 76
                            sourceSize.height: 76
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        // Whatever asked is free to name an icon the theme does
                        // not have, so there is a shield to fall back on.
                        Label {
                            anchors.centerIn: parent
                            visible: !icon.visible
                            text: ""        // nf-fa-shield
                            color: Modules.Theme.foreground
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 26
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            Layout.fillWidth: true
                            text: "Authentication required"
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.flow ? root.flow.message : ""
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }

                        // The action id is the only thing that says precisely
                        // what is being authorised, so it is worth the small
                        // grey line even though it reads like machinery.
                        Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.flow ? root.flow.actionId : ""
                            color: Modules.Theme.inactive
                            font.family: "Roboto Mono"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                // ---- who as, when there is a choice -----------------------
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.choosing

                    Repeater {
                        model: root.identities

                        delegate: Rectangle {
                            required property var modelData

                            readonly property bool current:
                                root.flow && root.flow.selectedIdentity === modelData

                            implicitWidth: identityLabel.implicitWidth + 18
                            implicitHeight: 22
                            radius: 11
                            color: current ? Modules.Theme.trough : "transparent"
                            border.width: 1
                            border.color: current ? Modules.Theme.divider : "transparent"

                            Label {
                                id: identityLabel
                                anchors.centerIn: parent
                                text: root.identityLabel(modelData)
                                color: parent.current ? Modules.Theme.foreground
                                                      : Modules.Theme.inactive
                                font.family: "Roboto Mono"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.flow.selectedIdentity = modelData
                            }
                        }
                    }
                }

                // ---- the password ------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.flow ? root.flow.isResponseRequired : false
                    implicitHeight: 38
                    radius: 10
                    color: Modules.Theme.trough
                    border.width: 1
                    border.color: field.activeFocus ? Modules.Theme.foreground
                                                    : Modules.Theme.divider

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Label {
                            text: ""        // nf-fa-lock
                            color: Modules.Theme.inactive
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }

                        TextInput {
                            id: field
                            Layout.fillWidth: true
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 14
                            selectionColor: Modules.Theme.divider
                            selectedTextColor: Modules.Theme.foreground
                            clip: true

                            // polkit says whether what is being asked for is a
                            // secret; an agent that always masks would be wrong
                            // for the prompts that are not.
                            echoMode: root.flow && root.flow.responseVisible
                                    ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: field.text === ""
                                text: root.flow && root.flow.inputPrompt !== ""
                                    ? root.flow.inputPrompt : "Password"
                                color: Modules.Theme.inactive
                                font: field.font
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.cancel();
                                } else if (event.key === Qt.Key_Return
                                           || event.key === Qt.Key_Enter) {
                                    root.submit();
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }

                // ---- what went wrong, or what is happening ------------------
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.flow ? root.flow.supplementaryMessage : ""
                    color: root.flow && root.flow.supplementaryIsError
                         ? Modules.Theme.urgent : Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }

                // ---- buttons ------------------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: [
                            { label: "Cancel", primary: false },
                            { label: "Authenticate", primary: true }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            implicitWidth: buttonLabel.implicitWidth + 26
                            implicitHeight: 28
                            radius: 14
                            color: modelData.primary ? Modules.Theme.foreground
                                 : buttonMouse.containsMouse ? Modules.Theme.trough
                                 : "transparent"
                            border.width: 1
                            border.color: modelData.primary ? Modules.Theme.foreground
                                                            : Modules.Theme.divider
                            opacity: modelData.primary && !(root.flow && root.flow.isResponseRequired)
                                   ? 0.4 : 1.0

                            Label {
                                id: buttonLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: modelData.primary ? Modules.Theme.onAccent
                                                         : Modules.Theme.foreground
                                font.family: "Roboto Mono"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: buttonMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.primary ? root.submit() : root.cancel()
                            }
                        }
                    }
                }
            }
        }
    }
}
