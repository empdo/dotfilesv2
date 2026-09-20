// NotificationOverlay.qml -- the stack of toasts in the corner of the screen,
// and the IPC surface for the module.
//
// The bar owns the left edge and its popups fly out across it, so the toasts
// live in the top right instead, where nothing else is. Newest goes on top.
//
// Like the launcher, this resolves the monitor from Hyprland rather than
// letting Qt pick: a PanelWindow with no `screen` lands on whatever Qt calls
// the default output, which on a multi-monitor setup is rarely the one being
// looked at. The screen is re-resolved whenever the stack goes from empty to
// showing something, so a burst of toasts does not jump between monitors.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../" as Modules

Scope {
    id: root

    readonly property var popups: NotificationService.popups

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

    onPopupsChanged: {
        if (popups.length > 0 && !overlay.visible)
            root.targetScreen = root.focusedScreen();
    }

    IpcHandler {
        target: "notifications"

        function dnd(): void      { NotificationService.dnd = !NotificationService.dnd; }
        function silence(): void  { NotificationService.dnd = true; }
        function unsilence(): void { NotificationService.dnd = false; }
        function dismiss(): void  { NotificationService.dismissPopups(); }
        function clear(): void    { NotificationService.clear(); }
    }

    PanelWindow {
        id: overlay

        visible: root.popups.length > 0
        color: "transparent"
        screen: root.targetScreen

        anchors { top: true; right: true }
        margins { top: 12; right: 16 }

        implicitWidth: stack.width
        implicitHeight: Math.max(1, stack.height)

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:notifications"
        exclusionMode: ExclusionMode.Ignore

        // Only the cards take clicks. Without this the whole column, gaps
        // included, would swallow them on its way to the window underneath.
        mask: Region {
            item: stack
        }

        Column {
            id: stack
            width: 380
            spacing: 10

            // Cards animate themselves in and out; this is the older ones
            // sliding down to make room, and back up again afterwards.
            move: Transition {
                NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
            }
            add: Transition {
                NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: root.popups

                delegate: NotificationToast {
                    required property var modelData

                    width: stack.width
                    entry: modelData
                }
            }
        }
    }
}
