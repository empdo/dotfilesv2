// ClipboardList.qml -- the history rows. Purely a view: ClipboardPanel.qml owns
// the query, the filtering and the selection, the same split the launcher uses.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import "."
import "../" as Modules

Item {
    id: root

    property var entries: []
    property int selected: 0
    property string query: ""

    signal activated(int index)
    signal hovered(int index)

    readonly property int rowHeight: 52
    readonly property int pageRows: Math.max(1, Math.floor(list.height / rowHeight))

    ListView {
        id: list
        anchors.fill: parent
        visible: root.entries.length > 0
        clip: true
        spacing: 2
        model: root.entries
        currentIndex: root.selected

        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: root.rowHeight
        preferredHighlightEnd: height - root.rowHeight
        highlightMoveDuration: 90

        highlight: Rectangle {
            radius: 10
            color: Modules.Theme.trough
        }
        highlightResizeDuration: 0

        ScrollBar.vertical: ScrollBar {
            policy: list.contentHeight > list.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            width: 4
            contentItem: Rectangle {
                radius: 2
                color: Modules.Theme.inactive
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            width: list.width
            height: root.rowHeight

            readonly property bool active: index === root.selected

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 18
                spacing: 12

                // Position in the history, so "the one before last" is countable
                // rather than something you have to squint down the list for.
                Label {
                    Layout.preferredWidth: 22
                    text: row.index + 1
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                }

                // Images show themselves; there is no describing one usefully
                // in a line of text.
                ClippingRectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 34
                    visible: row.modelData.kind === "image"
                    radius: 6
                    color: Modules.Theme.trough

                    Image {
                        anchors.fill: parent
                        source: row.modelData.kind === "image"
                              ? "file://" + row.modelData.path : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Bounded so a row never decodes a full screenshot;
                        // a list of them would otherwise cost hundreds of
                        // megabytes to show forty-pixel thumbnails.
                        sourceSize.width: 80
                        sourceSize.height: 68
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Label {
                        Layout.fillWidth: true
                        text: ClipboardService.preview(row.modelData)
                        color: Modules.Theme.foreground
                        font.family: "Roboto Mono"
                        font.pixelSize: 14
                        font.bold: row.active
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: ClipboardService.detail(row.modelData)
                        color: Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Label {
                    visible: row.active
                    text: "⏎"
                    color: Modules.Theme.foreground
                    font.pixelSize: 15
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                // Hovering moves the cursor, so mouse and keyboard never disagree
                // about which row Enter would copy.
                onPositionChanged: root.hovered(row.index)
                onClicked: root.activated(row.index)
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: root.entries.length === 0
        spacing: 6

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: ""        // nf-fa-paste
            color: Modules.Theme.inactive
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 34
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.query === "" ? "Nothing copied yet"
                                    : "Nothing matches \"" + root.query + "\""
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 14
        }
    }
}
