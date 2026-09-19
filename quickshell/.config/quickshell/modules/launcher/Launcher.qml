// Launcher.qml -- the app launcher, replacing `wofi --show drun`.
//
// Reads the XDG desktop entries through Quickshell's DesktopEntries singleton,
// so there is no cache to rebuild: installing an app makes it appear.
// Ranking lives in search.js; launch counts are kept in
// ~/.local/state/quickshell/by-id/<id>/launcher.json so the apps you actually
// use float to the top -- something wofi's plain alphabetical drun list never did.
//
// Opened with:  qs ipc call launcher toggle
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../" as Modules
import "search.js" as Search

Scope {
    id: root

    // --- configuration -------------------------------------------------------

    // Terminal used for entries with Terminal=true (wofi called this `term`).
    // kitty takes the command straight after its own options; most other
    // terminals want an explicit ["foot", "-e"] style separator here.
    property var terminal: ["kitty"]

    // Desktop actions ("New Private Window") are folded into the results once
    // you type, but kept out of the resting list so it stays one row per app.
    property bool searchActions: true

    // --- state ---------------------------------------------------------------

    property bool open: false
    property int selected: 0
    property var uses: ({})

    readonly property string query: input.text

    // The screen the launcher should appear on. A PanelWindow with no `screen`
    // lands on whatever Qt calls the default output, which on a multi-monitor
    // setup is rarely the one being looked at -- so resolve it from Hyprland's
    // focused monitor each time the launcher is opened.
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

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle(); }
        function hide(): void   { root.hide(); }
        // Named menu(), not show(): `qs ipc call launcher show` is swallowed by
        // the `qs ipc show` subcommand -- the same trap as the cheatsheet module.
        function menu(): void   { root.show(); }
    }

    // --- desktop entries -----------------------------------------------------

    // QStringList properties arrive as list-likes rather than real arrays, and
    // search.js checks Array.isArray, so copy them across.
    function toArray(v) {
        const out = [];
        if (v)
            for (let i = 0; i < v.length; i++)
                out.push(v[i]);
        return out;
    }

    function makeRecord(entry, action) {
        return {
            entry: entry,
            action: action,
            name: entry.name,
            actionName: action ? action.name : "",
            // genericName first: "Web Browser" reads better in a narrow row than
            // a full Comment= sentence, and the comment is still searchable.
            sub: entry.genericName || entry.comment || "",
            icon: (action && action.icon) || entry.icon || "",
            id: (entry.id || "").replace(/\.desktop$/, ""),
            keywords: root.toArray(entry.keywords),
            genericName: entry.genericName || "",
            comment: entry.comment || "",
            runInTerminal: entry.runInTerminal,
            // Identifies the row in the launch history. Actions get their own
            // count, so a frequently used action can outrank its parent app.
            key: (entry.id || entry.name) + (action ? "#" + action.id : "")
        };
    }

    readonly property var appRecords: {
        const out = [];
        const all = DesktopEntries.applications.values;
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            // NoDisplay entries are associations and settings panes, not apps.
            if (!e || e.noDisplay || !e.name)
                continue;
            out.push(root.makeRecord(e, null));
        }
        return out;
    }

    readonly property var actionRecords: {
        const out = [];
        if (!root.searchActions)
            return out;
        const all = DesktopEntries.applications.values;
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            if (!e || e.noDisplay || !e.name)
                continue;
            const acts = e.actions || [];
            for (let k = 0; k < acts.length; k++)
                out.push(root.makeRecord(e, acts[k]));
        }
        return out;
    }

    readonly property var results: {
        const pool = root.query.trim() === ""
                   ? root.appRecords
                   : root.appRecords.concat(root.actionRecords);
        return Search.rank(pool, root.query, root.uses);
    }

    readonly property var current: results[selected] || null

    // --- launch history ------------------------------------------------------

    FileView {
        id: history
        path: Quickshell.statePath("launcher.json")
        atomicWrites: true

        onLoaded: {
            try {
                root.uses = JSON.parse(history.text()).uses || ({});
            } catch (e) {
                console.warn("launcher: could not parse launcher.json:", e);
                root.uses = ({});
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.save();
        }
    }

    function save() {
        history.setText(JSON.stringify({ uses: root.uses }, null, 2));
    }

    function bump(key) {
        // A fresh object, because assigning the same reference back would not
        // notify, and `results` has to re-rank before the next open.
        const next = {};
        for (const k in root.uses)
            next[k] = root.uses[k];
        next[key] = (next[key] || 0) + 1;
        root.uses = next;
        root.save();
    }

    // --- launching -----------------------------------------------------------

    function launch(rec) {
        if (!rec)
            return;

        root.bump(rec.key);
        root.hide();

        if (rec.entry.runInTerminal) {
            // DesktopEntry.execute() runs the bare command, which would leave a
            // TUI app with no terminal attached, so wrap it ourselves.
            const cmd = root.terminal.concat(
                root.toArray(rec.action ? rec.action.command : rec.entry.command));
            const ctx = { command: cmd };
            if (rec.entry.workingDirectory)
                ctx.workingDirectory = rec.entry.workingDirectory;
            Quickshell.execDetached(ctx);
        } else if (rec.action) {
            rec.action.execute();
        } else {
            rec.entry.execute();
        }
    }

    function move(delta) {
        const n = root.results.length;
        if (n === 0)
            return;
        // Clamped rather than wrapped: holding Down should settle at the end of
        // the list instead of silently jumping back to the top.
        root.selected = Math.max(0, Math.min(n - 1, root.selected + delta));
    }

    // Typing changes what is on offer, so the cursor goes back to the best match.
    onQueryChanged: selected = 0

    // --- the overlay ---------------------------------------------------------

    PanelWindow {
        id: overlay
        visible: root.open
        color: "transparent"
        screen: root.targetScreen

        anchors { top: true; left: true; right: true; bottom: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:launcher"
        exclusionMode: ExclusionMode.Ignore

        // Dim the desktop, and treat a click outside the card as "never mind".
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
            width: Math.min(parent.width - 120, 760)
            height: Math.min(parent.height - 120, 560)
            radius: 18
            color: Modules.Theme.background
            border.width: 1
            border.color: Modules.Theme.foreground

            // Swallow clicks so they do not reach the dim layer behind.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                // ---- search box ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: "\uF002"        // nf-fa-search
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
                        // A launcher query is one line; Enter is for launching.
                        inputMethodHints: Qt.ImhNoPredictiveText

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: "Search applications"
                            color: Modules.Theme.inactive
                            font: input.font
                        }

                        // Navigation is handled here rather than on a wrapping
                        // FocusScope so the arrow keys never move the text cursor.
                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;

                            if (event.key === Qt.Key_Escape) {
                                root.hide();
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launch(root.current);
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
                                root.selected = 0;
                            } else if (event.key === Qt.Key_End && ctrl) {
                                root.selected = Math.max(0, root.results.length - 1);
                            } else if (event.key === Qt.Key_Tab) {
                                // Complete to the selected app's name, so Tab then
                                // typing narrows within one app's actions.
                                if (root.current)
                                    input.text = root.current.name;
                            } else {
                                return;   // hand everything else to text editing
                            }
                            event.accepted = true;
                        }
                    }

                    Label {
                        text: root.results.length + (root.results.length === 1 ? " result" : " results")
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

                // ---- results ----
                AppList {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    entries: root.results
                    selected: root.selected
                    query: root.query

                    onHovered: i => root.selected = i
                    onActivated: i => root.launch(root.results[i])
                }

                Label {
                    Layout.fillWidth: true
                    text: "↑↓ select    ⏎ launch    ⇥ complete    Esc close"
                    color: Modules.Theme.inactive
                    font.family: "Roboto Mono"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Layershell windows are mapped when `visible` flips, so focus has to be
        // taken after the fact rather than once at construction.
        Connections {
            target: root
            function onOpenChanged() {
                if (root.open)
                    input.forceActiveFocus();
            }
        }
    }
}
