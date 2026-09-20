// WorkspacesWidget.qml -- workspace slots, scoped to this bar's monitor.
//
// Slots rather than a list of whatever happens to be open. Hyprland only
// reports workspaces that exist, so a plain repeater over them means the third
// dot is workspace 3 one minute and workspace 7 the next, and position tells
// you nothing. Slots make position *be* the identity: the fourth dot is always
// workspace 4, which is what SUPER + 4 goes to.
//
// The row runs up to the highest workspace in use on this monitor rather than
// to a fixed ten, so two workspaces show two dots and a jump to 8 shows eight,
// with 2 to 7 sitting empty in between. The gaps are the point -- they are
// what keeps the eighth dot the eighth.
//
// Each bar shows only the workspaces living on its own monitor, so the two
// bars say different things -- a workspace is on exactly one monitor at a
// time, and which one that is is half of what you want to know.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "modules" as Modules

Item {
    id: root

    // Set by a bar that runs along the bottom of the screen.
    property bool horizontal: false
    property real thickness: 60

    // The output this bar belongs to; empty means "do not filter".
    property string monitorName: ""

    // Up to the highest workspace in use on this bar's monitor, and never
    // fewer than one so the pill does not collapse to nothing.
    readonly property int slotCount: {
        const all = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        let highest = 1;
        for (const w of all) {
            // Special workspaces -- the scratchpad and friends -- carry
            // negative ids and have no slot of their own.
            if (w.id < 1)
                continue;
            if (root.monitorName !== ""
                && (!w.monitor || w.monitor.name !== root.monitorName))
                continue;
            if (w.id > highest)
                highest = w.id;
        }
        return highest;
    }

    implicitWidth: horizontal ? pill.implicitWidth : thickness
    implicitHeight: horizontal ? thickness : pill.implicitHeight

    // The workspace occupying a slot on this bar's monitor, or null.
    function workspaceFor(id) {
        const all = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (const w of all) {
            if (w.id !== id)
                continue;
            if (root.monitorName === ""
                || (w.monitor && w.monitor.name === root.monitorName))
                return w;
        }
        return null;
    }

    function goTo(id) {
        const ws = root.workspaceFor(id);
        if (ws) {
            ws.activate();
            return;
        }
        // An empty slot still switches to that workspace, which creates it.
        // The Hyprland config here is in Lua mode, where a dispatcher is a Lua
        // expression rather than a bare string -- `workspace 5` is an error
        // there, the same trap the power menu documents.
        Hyprland.dispatch(Hyprland.usingLua
            ? "hl.dsp.focus({ workspace = " + id + " })"
            : "workspace " + id);
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent

        color: Modules.Theme.background
        radius: 20
        border.color: Modules.Theme.foreground
        border.width: 1
        clip: true

        implicitWidth: root.horizontal ? dots.implicitWidth + 16 : 28
        implicitHeight: root.horizontal ? 28 : dots.implicitHeight + 16
        width: implicitWidth
        height: implicitHeight

        Grid {
            id: dots
            anchors.centerIn: parent
            spacing: 8
            columns: root.horizontal ? 100 : 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Repeater {
                model: root.slotCount

                delegate: Rectangle {
                    id: dot
                    required property int index

                    readonly property int workspaceId: index + 1
                    readonly property var workspace: root.workspaceFor(workspaceId)
                    readonly property bool occupied: workspace !== null

                    // `active` is the workspace this monitor is showing.
                    // `focused` is the one the keyboard is on -- there is only
                    // ever one of those across both screens, so a muted fill
                    // on the other bar says "this is what is over there".
                    readonly property bool current: occupied && workspace.active
                    readonly property bool attended: occupied && workspace.focused

                    width: 12
                    height: 12
                    radius: 6

                    color: !current ? "transparent"
                         : attended ? Modules.Theme.foreground
                         : Modules.Theme.inactive
                    border.color: Modules.Theme.foreground
                    border.width: occupied ? 2 : 1

                    // An empty slot is still a slot -- it holds the position
                    // that gives the others their meaning -- but it has no
                    // business competing with the ones in use.
                    opacity: occupied ? 1.0 : 0.22

                    Behavior on opacity {
                        NumberAnimation { duration: 140 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goTo(dot.workspaceId)
                    }
                }
            }
        }
    }
}
