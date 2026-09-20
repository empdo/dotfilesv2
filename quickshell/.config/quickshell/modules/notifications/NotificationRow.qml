// NotificationRow.qml -- one past notification in the history list.
//
// Deliberately quieter than the toast: no actions and a clamped body, because
// the list is for catching up on what was missed rather than for acting on it.
// Clicking still runs the default action, and the cross drops the row.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "."
import "../" as Modules

Rectangle {
    id: root

    required property var entry

    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property string iconSource: NotificationService.iconSource(entry)

    implicitHeight: layout.implicitHeight + 16
    radius: 10
    color: mouse.containsMouse ? Modules.Theme.trough : "transparent"

    function activate() {
        for (const action of root.entry.actions) {
            if (action.identifier === "default") {
                NotificationService.invoke(root.entry, action);
                return;
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
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
        anchors.margins: 8
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        ClippingRectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            Layout.alignment: Qt.AlignTop
            visible: icon.status === Image.Ready
            radius: 6
            color: "transparent"

            Image {
                id: icon
                anchors.fill: parent
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 52
                sourceSize.height: 52
                asynchronous: true
                smooth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: root.entry.appName || "Notification"
                    color: root.critical ? Modules.Theme.urgent : Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    // Ticked over by the popup's clock while it is on screen.
                    text: "· " + NotificationService.formatAge(root.entry.time)
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 9
                    opacity: 0.7
                }

                Label {
                    text: ""     // nf-md-close
                    color: Modules.Theme.inactive
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: 11
                    opacity: mouse.containsMouse ? 1 : 0

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
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.body
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 10
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
