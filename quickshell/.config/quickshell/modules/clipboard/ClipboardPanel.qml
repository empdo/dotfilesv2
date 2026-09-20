// ClipboardPanel.qml -- pick something out of the clipboard history.
//
// Laid out like the launcher and driven the same way, because it is the same
// motion: open, type to narrow, Enter to take the top one. Ranking is the
// launcher's own `matchScore`, so "gim" finds a snippet the same way it finds
// GIMP -- but with an empty query the list stays in copy order, since with
// nothing typed the thing you want is nearly always the last thing you copied.
//
// Opened with SUPER + SHIFT + V, from the Clipboard tile in the quick
// settings menu, or with:  qs ipc call clipboard menu
//
// Instantiated by shell.qml rather than being a singleton like the wallpaper
// picker. A singleton is built only when something first asks for it, and the
// IPC handler below has to be registered from the start -- so the tile asks
// the service to open this, instead of this being something the tile holds.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../" as Modules
import "../launcher/search.js" as Search

Scope {
    id: root

    property bool open: false
    property int selected: 0

    readonly property string query: input.text

    // The same trick the launcher plays: a PanelWindow with no `screen` lands
    // on whatever Qt calls the default output, which is rarely the one being
    // looked at, so ask Hyprland which monitor has focus.
    property var targetScreen: null

    function focusedScreen() {
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === mon.name)
                    return screens[i];
        }
        return null;
    }

    readonly property var results: {
        const all = ClipboardService.entries;
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return all;

        const scored = [];
        for (const entry of all) {
            // An image has no text of its own, so it answers to "image".
            const score = Search.matchScore(ClipboardService.haystack(entry), q);
            if (score > 0)
                scored.push({
                    entry: entry,
                    score: score
                });
        }
        // Copy order breaks ties, so equally good matches stay newest-first.
        scored.sort((a, b) => b.score - a.score);
        return scored.map(s => s.entry);
    }

    readonly property var current: results[selected] || null

    function show() {
        input.text = "";
        selected = 0;
        targetScreen = root.focusedScreen();
        open = true;
    }

    function hide() {
        open = false;
        input.text = "";
        selected = 0;
    }

    function toggle() {
        open ? hide() : show();
    }

    function take(entry) {
        if (!entry)
            return;
        ClipboardService.copy(entry);
        root.hide();
    }

    function drop(entry) {
        if (!entry)
            return;
        ClipboardService.remove(entry);
        root.select(Math.max(0, Math.min(root.selected, root.results.length - 1)));
    }

    function move(delta) {
        const n = root.results.length;
        if (n === 0)
            return;
        root.select(Math.max(0, Math.min(n - 1, root.selected + delta)));
    }

    // Moving the cursor with the keyboard scrolls the list to follow it.
    // Hovering deliberately does not -- see the list's `reveal`.
    function select(index) {
        root.selected = index;
        list.reveal(index);
    }

    onQueryChanged: root.select(0)

    // The quick settings tile cannot reach into this window, so it asks the
    // service and this listens.
    Connections {
        target: ClipboardService

        function onToggleRequested() {
            root.toggle();
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void { root.toggle(); }
        function hide(): void   { root.hide(); }
        // Named menu() for the same reason the launcher's is: `qs ipc call
        // clipboard show` is swallowed by the `qs ipc show` subcommand.
        function menu(): void   { root.show(); }
        function clear(): void  { ClipboardService.clear(); }
    }

    PanelWindow {
        id: overlay
        visible: root.open
        color: "transparent"
        screen: root.targetScreen

        anchors { top: true; left: true; right: true; bottom: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:clipboard"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 120, 680)
            height: Math.min(parent.height - 120, 540)
            radius: 18
            color: Modules.Theme.background
            border.width: 1
            border.color: Modules.Theme.foreground

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: ""        // nf-fa-paste
                        color: Modules.Theme.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                    }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Modules.Theme.foreground
                        font.family: "Roboto Mono"
                        font.pixelSize: 20
                        selectionColor: Modules.Theme.trough
                        selectedTextColor: Modules.Theme.foreground
                        focus: true
                        inputMethodHints: Qt.ImhNoPredictiveText

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: "Search clipboard"
                            color: Modules.Theme.inactive
                            font: input.font
                        }

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;

                            if (event.key === Qt.Key_Escape) {
                                root.hide();
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.take(root.current);
                            } else if (event.key === Qt.Key_Delete
                                       || (ctrl && event.key === Qt.Key_D)) {
                                root.drop(root.current);
                            } else if (event.key === Qt.Key_Down
                                       || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                root.move(1);
                            } else if (event.key === Qt.Key_Up
                                       || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                root.move(-1);
                            } else if (event.key === Qt.Key_PageDown) {
                                root.move(list.pageRows);
                            } else if (event.key === Qt.Key_PageUp) {
                                root.move(-list.pageRows);
                            } else if (event.key === Qt.Key_Home && ctrl) {
                                root.select(0);
                            } else if (event.key === Qt.Key_End && ctrl) {
                                root.select(Math.max(0, root.results.length - 1));
                            } else {
                                return;   // hand everything else to text editing
                            }
                            event.accepted = true;
                        }
                    }

                    Label {
                        text: root.results.length + (root.results.length === 1 ? " entry" : " entries")
                        color: Modules.Theme.inactive
                        font.family: "Roboto Mono"
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Modules.Theme.divider
                }

                ClipboardList {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    entries: root.results
                    selected: root.selected
                    query: root.query

                    onHovered: i => root.selected = i
                    onActivated: i => root.take(root.results[i])
                }

                Label {
                    Layout.fillWidth: true
                    text: "↑↓ select    ⏎ copy    Del remove    Esc close"
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Layershell windows are mapped when `visible` flips, so focus has to
        // be taken after the fact rather than once at construction.
        Connections {
            target: root
            function onOpenChanged() {
                if (root.open)
                    input.forceActiveFocus();
            }
        }
    }
}
