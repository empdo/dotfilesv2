// modules/Shell.qml -- the shell's own geometry, in one place.
//
// Which edge the bar lives on is read off the shape of the output, and three
// things now have to agree about the answer: the bar itself, and the two
// panels that open flush against it. Disagreeing here does not look like a
// wrong number -- it looks like a drawer growing out of the wrong side of the
// screen -- so the rule lives here rather than being restated at each place
// that needs it.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // How much of its screen the bar takes along the edge it lives on.
    readonly property int barThickness: 60

    // A screen taller than it is wide -- this machine's second monitor is
    // rotated a quarter turn -- gets the bar across its bottom instead of down
    // its left edge, where a vertical bar would eat a twentieth of an already
    // narrow screen. Reading it off the shape rather than the output name
    // means a monitor added or re-rotated sorts itself out.
    function barIsHorizontal(screen) {
        return !!screen && screen.height > screen.width;
    }

    // The screen the keyboard is on. A PanelWindow with no `screen` lands on
    // whatever Qt calls the default output, which on a multi-monitor setup is
    // rarely the one being looked at, so ask Hyprland which monitor has focus.
    //
    // Hyprland names the monitor; a window wants the Quickshell screen of the
    // same name, so the lookup is the useful half and it lives here.
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
}
