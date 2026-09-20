// NotificationToast.qml -- one notification, as it appears in the stack in the
// corner of the screen.
//
// The card times itself out. Hovering stops the clock so a notification cannot
// disappear while it is being read; moving away starts the wait over rather
// than resuming it, which is the forgiving way round.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "."
import "../" as Modules

Item {
    id: root

    required property var entry

    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property string iconSource: NotificationService.iconSource(entry)

    property bool hovered: false
    property bool leaving: false

    implicitWidth: 380
    implicitHeight: card.implicitHeight

    function dismiss() {
        if (root.leaving)
            return;
        root.leaving = true;
        exit.start();
    }

    function activate() {
        // Clicking the body runs the notification's default action if it has
        // one -- that is what opens the chat window the message came from.
        for (const action of root.entry.actions) {
            if (action.identifier === "default") {
                NotificationService.invoke(root.entry, action);
                return;
            }
        }
        root.dismiss();
    }

    Timer {
        id: life
        // A timeout of 0 means the notification stays until it is dismissed.
        running: root.entry.timeout > 0 && !root.hovered && !root.leaving
        interval: root.entry.timeout
        onTriggered: root.dismiss()
    }

    Connections {
        target: root.entry

        // The app replaced this notification's contents, so it is new again
        // and gets its full time on screen rather than the rest of the old
        // notification's.
        function onRevisionChanged() {
            if (life.running)
                life.restart();
        }
    }

    // Slide in from the edge the stack is anchored to, and back out again.
    ParallelAnimation {
        id: enter
        running: true
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "x"; from: 40; to: 0; duration: 240; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: exit
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 150 }
        NumberAnimation { target: card; property: "x"; to: 60; duration: 150; easing.type: Easing.InCubic }
        onFinished: NotificationService.dismissPopup(root.entry)
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: layout.implicitHeight + 28
        height: implicitHeight
        radius: 14
        color: Modules.Theme.background
        border.width: 1
        border.color: root.critical ? Modules.Theme.urgent : Modules.Theme.foreground

        // Critical notifications get a stripe rather than a coloured card, so
        // they stand out without shouting over the rest of the palette.
        Rectangle {
            visible: root.critical
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 24
            radius: 2
            color: Modules.Theme.urgent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: event => {
                if (event.button === Qt.RightButton)
                    NotificationService.remove(root.entry);
                else
                    root.activate();
            }
        }

        RowLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            anchors.leftMargin: 16
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                // An app is free to name an icon its theme does not have, and
                // a broken image is worse than none, so the slot only appears
                // once something has actually loaded into it.
                visible: icon.status === Image.Ready
                radius: 8
                color: "transparent"

                Image {
                    id: icon
                    anchors.fill: parent
                    source: root.iconSource
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 76
                    sourceSize.height: 76
                    asynchronous: true
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        Layout.fillWidth: true
                        text: root.entry.appName || "Notification"
                        color: root.critical ? Modules.Theme.urgent : Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Label {
                        text: ""     // nf-md-close
                        color: Modules.Theme.inactive
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 12
                        // Only while the pointer is on the card: a close button
                        // on every toast would be four crosses down the screen.
                        opacity: root.hovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.remove(root.entry)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry.summary
                    color: Modules.Theme.foreground
                    font.family: "Roboto Mono"
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry.body
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                    // The server advertises body markup, so senders are allowed
                    // to use the spec's small subset of HTML.
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                // ---- actions -------------------------------------------------
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6
                    visible: repeater.count > 0

                    Repeater {
                        id: repeater
                        // The default action is what clicking the card does; it
                        // has no business also being a button.
                        model: root.entry.actions.filter(a => a.identifier !== "default")

                        delegate: Rectangle {
                            required property var modelData

                            implicitWidth: actionLabel.implicitWidth + 20
                            implicitHeight: 24
                            radius: 12
                            color: actionMouse.containsMouse ? Modules.Theme.trough : "transparent"
                            border.width: 1
                            border.color: Modules.Theme.divider

                            Label {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData.text || modelData.identifier
                                color: Modules.Theme.foreground
                                font.family: "Roboto Mono"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.invoke(root.entry, modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
