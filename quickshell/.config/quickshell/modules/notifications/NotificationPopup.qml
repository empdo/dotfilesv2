// NotificationPopup.qml -- the history behind the bar's bell.
//
// Opening it clears the badge, which is why the bar hands it `active` rather
// than letting it work that out for itself: the popup contents are built once,
// at startup, and only shown later.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "."
import "../connectivity"
import "../" as Modules

Item {
    id: root

    // Driven by the bar's ExpandableItem.
    property bool active: false

    implicitWidth: 380
    implicitHeight: 440

    onActiveChanged: if (active) NotificationService.markSeen()

    component SwitchRow : RowLayout {
        id: switchRow

        property string label
        property bool checked
        signal toggled

        spacing: 6

        Label {
            text: switchRow.label
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 11
        }

        Toggle {
            checked: switchRow.checked
            onToggled: switchRow.toggled()
        }
    }


    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        // ---- header ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Notifications"
                color: Modules.Theme.foreground
                font.family: "Roboto Mono"
                font.pixelSize: 14
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            SwitchRow {
                label: "Silence"
                checked: NotificationService.dnd
                onToggled: NotificationService.dnd = !NotificationService.dnd
            }

            SwitchRow {
                label: "Count"
                checked: NotificationService.badge
                onToggled: NotificationService.badge = !NotificationService.badge
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Modules.Theme.divider
        }

        // ---- the list --------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                visible: NotificationService.hasEntries
                clip: true
                spacing: 2
                model: NotificationService.entries
                ScrollBar.vertical: ScrollBar {}

                delegate: NotificationRow {
                    required property var modelData

                    width: list.width - 8
                    entry: modelData
                }
            }

            Label {
                anchors.centerIn: parent
                visible: !NotificationService.hasEntries
                text: NotificationService.dnd ? "Silenced" : "Nothing new"
                color: Modules.Theme.inactive
                font.family: "Roboto Mono"
                font.pixelSize: 12
            }
        }

        // ---- clear -----------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            visible: NotificationService.hasEntries
            radius: 14
            color: clearMouse.containsMouse ? Modules.Theme.trough : "transparent"
            border.width: 1
            border.color: Modules.Theme.divider

            Label {
                anchors.centerIn: parent
                text: "Clear all"
                color: Modules.Theme.foreground
                font.family: "Roboto Mono"
                font.pixelSize: 11
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.clear()
            }
        }
    }
}
