// modules/Theme.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Persisted across restarts in ~/.local/state/quickshell/by-id/<id>/theme.json
    property alias light: adapter.light

    function toggle() {
        adapter.light = !adapter.light;
    }

    // --- palette ---
    property color background: light ? "#f4f6ec" : "#1a1a1a"
    property color foreground: light ? "#2c3a1c" : "#ebffd9"

    // text/icons drawn on top of a foreground-filled shape
    property color onAccent: background

    property color divider: light ? "#c7cfb6" : "#444444"
    property color trough: light ? "#d7ddc8" : "#333333"
    property color inactive: light ? "#9aa489" : "#666666"

    // fade between palettes instead of snapping
    Behavior on background {
        ColorAnimation {
            duration: 180
        }
    }
    Behavior on foreground {
        ColorAnimation {
            duration: 180
        }
    }
    Behavior on divider {
        ColorAnimation {
            duration: 180
        }
    }
    Behavior on trough {
        ColorAnimation {
            duration: 180
        }
    }
    Behavior on inactive {
        ColorAnimation {
            duration: 180
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("theme.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool light: false
        }
    }
}
