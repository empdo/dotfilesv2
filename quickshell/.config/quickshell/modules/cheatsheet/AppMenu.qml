// AppMenu.qml -- stage one: pick the app whose binds you want to see.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as Modules

Item {
    id: root

    property var apps: []
    property int selected: 0
    property string query: ""

    signal picked(int index)

    // Typing filters the menu, but the list keeps original indices so `selected`
    // stays meaningful for the key handler.
    readonly property var shown: {
        const q = query.toLowerCase();
        const out = [];
        for (let i = 0; i < apps.length; i++)
            if (!q || apps[i].name.toLowerCase().includes(q))
                out.push({ index: i, app: apps[i] });
        return out;
    }

    function bindCount(app) {
        let n = 0;
        for (const g of (app.groups || []))
            n += (g.binds || []).length;
        return n;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.shown
            currentIndex: {
                for (let i = 0; i < root.shown.length; i++)
                    if (root.shown[i].index === root.selected)
                        return i;
                return 0;
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: list.width
                height: 56
                radius: 10

                readonly property bool active: modelData.index === root.selected
                color: active ? Modules.Theme.trough : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 16

                    Label {
                        text: modelData.app.icon || ""
                        color: Modules.Theme.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: modelData.app.name
                        color: Modules.Theme.foreground
                        font.family: "Roboto Mono"
                        font.pixelSize: 17
                        font.bold: row.active
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.bindCount(modelData.app) + " binds"
                        color: Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 13
                    }

                    Label {
                        text: ""
                        color: row.active ? Modules.Theme.foreground : Modules.Theme.inactive
                        font.pixelSize: 16
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selected = modelData.index
                    onClicked: root.picked(modelData.index)
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.shown.length === 0
            text: root.apps.length === 0
                  ? "No binds collected yet — run collect.py"
                  : "Nothing matches \"" + root.query + "\""
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: "↑↓ select    ⏎ open    type to filter"
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
