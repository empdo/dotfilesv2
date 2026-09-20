// AppList.qml -- the ranked result rows. Purely a view: Launcher.qml owns the
// query, the ranking and the selection, so this file only draws and reports clicks.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../" as Modules

Item {
    id: root

    property var entries: []
    property int selected: 0
    property string query: ""

    signal activated(int index)
    signal hovered(int index)

    readonly property int rowHeight: 58

    function scrollBy(dy) {
        const max = Math.max(0, list.contentHeight - list.height);
        list.contentY = Math.max(0, Math.min(max, list.contentY + dy));
    }

    // How many rows a Page Up/Down should travel.
    readonly property int pageRows: Math.max(1, Math.floor(list.height / rowHeight))

    // Scrolls the view so the row at `index` is on screen with a row's worth of
    // context past it, and does nothing at all when it already is.
    //
    // Only the keyboard calls this. The list used to keep the selected row
    // inside that band by itself (`highlightRangeMode: ApplyRange`), which
    // meant *any* selection change scrolled -- including one made by hovering,
    // so putting the pointer on the top or bottom row shoved the list out from
    // under it. Scrolling is now something navigation does deliberately, and a
    // hover is not navigation: the pointer is already on the row it means.
    function reveal(index) {
        if (root.entries.length === 0)
            return;

        const step = root.rowHeight + list.spacing;
        const top = index * step - root.rowHeight;
        const bottom = index * step + root.rowHeight + root.rowHeight;
        const max = Math.max(0, list.contentHeight - list.height);

        if (top < list.contentY)
            list.contentY = Math.max(0, top);
        else if (bottom > list.contentY + list.height)
            list.contentY = Math.min(max, bottom - list.height);
    }

    // A fresh set of rows starts at the top rather than keeping a scroll
    // position that belonged to the old ones.
    onEntriesChanged: root.reveal(root.selected)

    ListView {
        id: list
        anchors.fill: parent
        visible: root.entries.length > 0
        clip: true
        spacing: 2
        model: root.entries
        currentIndex: root.selected

        // Keep a little context above and below the cursor while arrowing about.
        // Deliberately not ApplyRange: the view scrolls when `reveal` says so
        // and at no other time, so hovering never moves it.
        highlightRangeMode: ListView.NoHighlightRange
        highlightMoveDuration: 90

        // The highlight is a sibling of the rows so it can slide between them.
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
                spacing: 14

                // Themed icon when the icon theme has one, otherwise a glyph, so
                // an entry with a broken Icon= line still lines up with the rest.
                //Item {
                //    Layout.preferredWidth: 34
                //    Layout.preferredHeight: 34

                //    readonly property string iconSource:
                //        Quickshell.iconPath(row.modelData.icon, true)

                //    // implicitSize rather than anchors.fill: IconImage derives the
                //    // texture's sourceSize from its laid-out size, and while the
                //    // layout is still settling that can ask the SVG renderer for an
                //    // absurd buffer ("requested buffer size is too big").
                //    IconImage {
                //        anchors.centerIn: parent
                //        implicitSize: 34
                //        visible: parent.iconSource !== ""
                //        source: parent.iconSource
                //        asynchronous: true
                //    }

                //    Label {
                //        anchors.centerIn: parent
                //        visible: parent.iconSource === ""
                //        text: "\uF1B2"        // nf-fa-cube, a stand-in app icon
                //        color: Modules.Theme.inactive
                //        font.family: "JetBrainsMono Nerd Font"
                //        font.pixelSize: 22
                //    }
                //}

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: row.modelData.name
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 16
                            font.bold: row.active
                            elide: Text.ElideRight
                            // Measured against the delegate, not against this
                            // layout: asking the layout for its own width while
                            // it is being laid out sends Qt Quick Layouts into a
                            // recursive rearrange.
                            Layout.maximumWidth: row.width * 0.5
                        }

                        // Desktop actions ("New Private Window") ride along with
                        // their app, so the row has to say which one this is.
                        Label {
                            visible: row.modelData.actionName !== ""
                            text: "  " + row.modelData.actionName
                            color: Modules.Theme.inactive
                            font.family: "Roboto Mono"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Takes up the slack when there is no action label to do it.
                        Item {
                            visible: row.modelData.actionName === ""
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: row.modelData.sub
                        color: Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Label {
                    visible: row.modelData.runInTerminal
                    text: "\uF120"        // nf-fa-terminal
                    color: Modules.Theme.inactive
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
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
                // about which row Enter would launch. It cannot scroll the view --
                // see `reveal` above -- so the row under the pointer stays the
                // row under the pointer.
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
            text: "\uF002"        // nf-fa-search
            color: Modules.Theme.inactive
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 34
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.query === "" ? "No applications found"
                                    : "Nothing matches \"" + root.query + "\""
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 14
        }
    }
}
