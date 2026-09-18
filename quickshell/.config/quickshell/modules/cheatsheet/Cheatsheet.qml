// Cheatsheet.qml -- SUPER + / opens a keybind cheatsheet: first a menu of apps,
// then that app's sheet.
//
// The data comes from ~/.cache/cheatsheet/binds.json, written by collect.py,
// which queries each app for its *live* binds rather than parsing configs.
// Hyprland rebuilds it on start (see hyprland.lua), and the FileView below
// watches the file, so re-running collect.py refreshes an open sheet.
//
// Opened with:  qs ipc call cheatsheet toggle
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../" as Modules

Scope {
    id: root

    property bool open: false
    property var data: ({ apps: [] })
    property int appIndex: 0
    property bool showingSheet: false   // false = app menu, true = that app's binds
    property string query: ""

    readonly property var apps: data.apps || []
    readonly property var currentApp: apps[appIndex] || null

    function show() {
        // Preselect whatever is focused, so the sheet is usually one keypress away.
        activeWindow.running = true;
        query = "";
        showingSheet = false;
        open = true;
    }

    function hide() {
        open = false;
        query = "";
        showingSheet = false;
    }

    function toggle() {
        open ? hide() : show();
    }

    // Back one step: sheet -> menu -> closed.
    function back() {
        if (showingSheet) {
            showingSheet = false;
            query = "";
        } else {
            hide();
        }
    }

    // Jump straight to one app's sheet, skipping the menu:
    //   qs ipc call cheatsheet open nvim
    function openApp(id: string): void {
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id === id) {
                appIndex = i;
                query = "";
                showingSheet = true;
                open = true;
                return;
            }
        }
        console.warn("cheatsheet: no such app:", id);
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void { root.toggle(); }
        function hide(): void   { root.hide(); }
        // Not "show": `qs ipc call cheatsheet show` is swallowed by the
        // `qs ipc show` subcommand, so the menu entry point is named menu().
        function menu(): void { root.show(); }
        function open(app: string): void { root.openApp(app); }
    }

    FileView {
        id: bindsFile
        path: Quickshell.env("HOME") + "/.cache/cheatsheet/binds.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(bindsFile.text());
            } catch (e) {
                console.warn("cheatsheet: could not parse binds.json:", e);
                root.data = { apps: [] };
            }
        }
    }

    // Picks the app matching the focused window, falling back to Hyprland.
    Process {
        id: activeWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let cls = "";
                try {
                    cls = (JSON.parse(text).class || "").toLowerCase();
                } catch (e) {}
                for (let i = 0; i < root.apps.length; i++) {
                    const m = root.apps[i].match || [];
                    for (const pat of m) {
                        if (pat !== "*" && cls.includes(pat)) {
                            root.appIndex = i;
                            return;
                        }
                    }
                }
                root.appIndex = 0;
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
        exclusionMode: ExclusionMode.Ignore

        // Dim whatever is behind, and close on a click outside the card.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }
        }

        // Everything below lives on this item so it can own keyboard focus.
        FocusScope {
            id: keyScope
            anchors.fill: parent
            focus: true

            // Re-take focus each time the overlay is mapped.
            Connections {
                target: root
                function onOpenChanged() {
                    if (root.open)
                        keyScope.forceActiveFocus();
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.back();
                } else if (event.key === Qt.Key_Backspace) {
                    root.query = root.query.slice(0, -1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                           || event.key === Qt.Key_Right) {
                    if (!root.showingSheet && root.currentApp)
                        root.showingSheet = true;
                } else if (event.key === Qt.Key_Left) {
                    root.back();
                } else if (event.key === Qt.Key_Down) {
                    if (!root.showingSheet)
                        root.appIndex = Math.min(root.appIndex + 1, root.apps.length - 1);
                    else
                        sheet.scrollBy(120);
                } else if (event.key === Qt.Key_Up) {
                    if (!root.showingSheet)
                        root.appIndex = Math.max(root.appIndex - 1, 0);
                    else
                        sheet.scrollBy(-120);
                } else if (event.key === Qt.Key_Tab) {
                    root.appIndex = (root.appIndex + 1) % Math.max(root.apps.length, 1);
                } else if (event.text && event.text.length === 1 && event.text >= " ") {
                    root.query += event.text;
                } else {
                    return;
                }
                event.accepted = true;
            }

            // ---- the card -------------------------------------------------
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 1180)
                height: Math.min(parent.height - 120, 820)
                radius: 18
                color: Modules.Theme.background
                border.width: 1
                border.color: Modules.Theme.foreground

                // Swallow clicks so the dim-layer MouseArea does not close us.
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 18

                    // ---- header ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            text: root.showingSheet && root.currentApp
                                  ? root.currentApp.name + " keybinds"
                                  : "Keybinds"
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Doubles as the search box: just start typing.
                        Label {
                            visible: root.query.length > 0
                            text: "  " + root.query
                            color: Modules.Theme.foreground
                            font.family: "Roboto Mono"
                            font.pixelSize: 16
                        }

                        Label {
                            text: root.showingSheet ? "Esc  back" : "Esc  close"
                            color: Modules.Theme.inactive
                            font.family: "Roboto Mono"
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Modules.Theme.divider
                    }

                    // ---- body: app menu, then the sheet ----
                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.showingSheet ? 1 : 0

                        AppMenu {
                            apps: root.apps
                            selected: root.appIndex
                            query: root.query
                            onPicked: i => {
                                root.appIndex = i;
                                root.query = "";
                                root.showingSheet = true;
                            }
                        }

                        BindSheet {
                            id: sheet
                            app: root.currentApp
                            query: root.query
                        }
                    }
                }
            }
        }
    }
}
