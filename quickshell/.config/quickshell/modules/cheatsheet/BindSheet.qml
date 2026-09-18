// BindSheet.qml -- stage two: every bind for one app, grouped, in newspaper columns.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as Modules

Item {
    id: root

    property var app: null
    property string query: ""

    function scrollBy(dy) {
        const max = Math.max(0, flick.contentHeight - flick.height);
        flick.contentY = Math.max(0, Math.min(max, flick.contentY + dy));
    }

    // How many rows fit in one column before it is worth starting a new one.
    // 28px is one bind row (a 24px key cap plus the layout spacing); 46px covers
    // the group heading, its rule and the surrounding padding.
    readonly property int rowsPerColumn: Math.max(6, Math.floor((flick.height - 46) / 28))

    // Filtering keeps a group only if something in it matched, so headings never
    // sit above an empty column. A group longer than one column is then split
    // across several, otherwise one big group (SUPER, say) starves the layout
    // and leaves the rest of the card empty.
    readonly property var groups: {
        if (!app)
            return [];
        const q = query.toLowerCase();
        const out = [];
        for (const g of (app.groups || [])) {
            const binds = (g.binds || []).filter(b =>
                !q || b.desc.toLowerCase().includes(q)
                   || b.keys.join(" ").toLowerCase().includes(q));
            // Split evenly rather than filling each column to the brim, so a
            // 22-row group becomes two columns of 11 and not 21 plus an orphan.
            const cols = Math.max(1, Math.ceil(binds.length / rowsPerColumn));
            const size = Math.ceil(binds.length / cols);
            for (let i = 0; i < binds.length; i += size) {
                out.push({
                    name: g.name,
                    continued: i > 0,
                    binds: binds.slice(i, i + size)
                });
            }
        }
        return out;
    }

    readonly property int matches: {
        let n = 0;
        for (const g of groups)
            n += g.binds.length;
        return n;
    }

    // Three columns unless the card is narrow, so a long sheet stays scannable.
    readonly property int columns: width > 900 ? 3 : 2

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: flow.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {}

            // Columns rather than one long list: a cheatsheet is meant to be
            // scanned at a glance, not scrolled through.
            Flow {
                id: flow
                width: flick.width
                spacing: 26

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        required property var modelData

                        width: Math.floor((flow.width - flow.spacing * (root.columns - 1)) / root.columns)
                        spacing: 4

                        Label {
                            text: modelData.continued ? modelData.name + " (cont.)" : modelData.name
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 13
                            font.bold: true
                            opacity: modelData.continued ? 0.4 : 0.65
                            topPadding: 14
                            bottomPadding: 2
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Modules.Theme.divider
                        }

                        Repeater {
                            model: modelData.binds

                            RowLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 10

                                Row {
                                    spacing: 4
                                    Layout.alignment: Qt.AlignTop

                                    Repeater {
                                        model: modelData.keys

                                        KeyCap {
                                            required property var modelData
                                            text: modelData
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: modelData.desc
                                    color: modelData.undocumented === true
                                           ? Modules.Theme.inactive : Modules.Theme.foreground
                                    font.family: "Roboto Mono"
                                    font.italic: modelData.undocumented === true
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.matches === 0
            text: "Nothing matches \"" + root.query + "\""
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: root.matches + " binds    ↑↓ scroll    type to filter    Esc back"
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
