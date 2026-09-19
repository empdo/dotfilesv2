// WallpaperPanel.qml -- the wallpaper selector.
//
// Opened from the Wallpaper tile in the quick settings menu. It is its own
// layershell panel rather than a popup hanging off the bar, so it can sit
// clear of the bar on the left of the screen with a real gap and a border.
//
// A singleton so the settings menu can call WallpaperPanel.toggle() without a
// reference being threaded through the bar.
pragma Singleton

import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel 2.1
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../" as Modules

Singleton {
    id: root

    property bool open: false

    // Whatever the picker last wrote into hyprpaper.conf, so the settings tile
    // can name the wallpaper that is actually up.
    property string currentPath: ""
    readonly property string currentName:
        currentPath ? currentPath.split("/").pop() : ""

    function show() { root.open = true; }
    function hide() { root.open = false; }
    function toggle() { root.open = !root.open; }

    FileView {
        id: conf
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            // Every monitor gets the same path, so the first one is enough.
            const m = /^\s*path\s*=\s*(.+)$/m.exec(conf.text());
            root.currentPath = m ? m[1].trim() : "";
        }
    }

    Process {
        id: setter
    }

    function apply(path) {
        setter.command = [Quickshell.env("HOME") + "/.config/hypr/setwallpaper.sh", path];
        setter.running = true;
        root.hide();
    }

    PanelWindow {
        id: panel
        visible: root.open
        color: "transparent"

        // Anchored to the left edge only, so the compositor centres it
        // vertically.
        anchors {
            left: true
        }

        // Clear of the bar's 60px, plus a 5mm gap. physicalPixelDensity is
        // pixels per millimetre; fall back to 96dpi if the monitor does not
        // report a physical size.
        readonly property real density: panel.screen && panel.screen.physicalPixelDensity > 0
                                        ? panel.screen.physicalPixelDensity
                                        : 96 / 25.4
        margins.left: 60 + Math.round(5 * density)

        implicitWidth: 400
        implicitHeight: 820

        WlrLayershell.layer: WlrLayer.Overlay
        // OnDemand rather than Exclusive: the panel takes the keyboard when it
        // is clicked, so Escape closes it, but it does not swallow typing
        // everywhere else while it happens to be open.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:wallpaper"
        exclusionMode: ExclusionMode.Ignore

        // ClippingRectangle rather than Rectangle: the list and its fades have
        // to be clipped to the rounded border, which plain clip:true will not do.
        ClippingRectangle {
            anchors.fill: parent
            radius: 18
            color: Modules.Theme.background
            border.width: 1
            border.color: Modules.Theme.foreground

            FocusScope {
                id: keyScope
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.hide();
                        event.accepted = true;
                    }
                }

                FolderListModel {
                    id: imageModel
                    folder: "file://" + Quickshell.env("HOME") + "/Pictures/"
                    nameFilters: ["*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.gif"]
                }

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 12
                    highlightMoveVelocity: 100000

                    clip: true
                    spacing: 0
                    orientation: ListView.Vertical
                    model: imageModel

                    delegate: Item {
                        id: entry
                        required property string filePath

                        width: listView.width
                        height: 235

                        readonly property bool current: entry.filePath === root.currentPath

                        // Items nearer the middle of the list sit slightly larger,
                        // so the one you are aiming at stands out as you scroll.
                        readonly property real centreY: listView.contentY + listView.height / 2
                        readonly property real dist: Math.abs(centreY - (y + height / 2))
                        scale: 0.95 - Math.min(dist / 300, 1) * 0.15

                        Behavior on scale {
                            NumberAnimation { duration: 80 }
                        }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: listView.width
                            height: 220
                            radius: 12
                            color: Modules.Theme.trough
                            border.width: entry.current ? 2 : 0
                            border.color: Modules.Theme.foreground

                            Image {
                                anchors.fill: parent
                                source: "file://" + entry.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 800
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.apply(entry.filePath)
                            }
                        }
                    }
                }

                // Fade the list out at both ends rather than letting it collide
                // with the border.
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: 2
                    height: 70
                    z: 100
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Modules.Theme.background }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: 2
                    height: 70
                    z: 100
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Modules.Theme.background }
                    }
                }
            }
        }

        Connections {
            target: root
            function onOpenChanged() {
                if (root.open)
                    keyScope.forceActiveFocus();
            }
        }
    }
}
