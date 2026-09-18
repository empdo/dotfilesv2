import Quickshell
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel 2.1
import Quickshell.Io
import "../" as Modules

Rectangle {
    id: root
    width: 400
    height: 800
    color: "transparent"

    FolderListModel {
        id: imageModel
        folder: "file:///home/emil/Pictures/"
        nameFilters: ["*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.gif"]
    }

    ListView {
        id: listView
        highlightMoveVelocity: 100000

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            rightMargin: 10
            leftMargin: 10
            topMargin: 20
            bottomMargin: 20

            // let the contentArea enforce padding
            // do NOT fill parent directly
        }

        clip: true
        spacing: 0
        orientation: ListView.Vertical
        model: imageModel

        delegate: Item {
            width: listView.width
            height: img.height - 15
            // --- scaling for center focus ---
            property real center: listView.contentY + listView.height / 2
            property real itemCenter: y + height / 2
            property real dist: Math.abs(center - itemCenter)

            scale: 0.95 - Math.min(dist / 300, 1) * 0.15

            // --------------------------------

            Process {
                id: setWallpaper
                command: ["/home/emil/.config/hypr/setwallpaper.sh", filePath]
            }

            MouseArea {
                anchors.fill: img
                onClicked: setWallpaper.running = true
            }

            Image {
                id: img
                anchors.horizontalCenter: parent.horizontalCenter
                source: "file:///" + filePath
                width: listView.width
                height: 250
                asynchronous: true
            }
        }
    }

    // TOP FADE
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            rightMargin: 1
            topMargin: 20
            bottomMargin: 20
        }
        height: 80   // how big the fade is
        z: 100
        gradient: Gradient {
            GradientStop {
                position: 1.0
                color: "#00000000"
            }  // transparent
            GradientStop {
                position: 4.0
                color: Modules.Theme.background
            }  // black @ 80% opacity
            GradientStop {
                position: 0.0
                color: Modules.Theme.background
            }  // black @ 80% opacity
        }
    }

    // BOTTOM FADE
    Rectangle {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            rightMargin: 1
            topMargin: 20
            bottomMargin: 20
        }
        height: 80
        z: 100
        gradient: Gradient {
            GradientStop {
                position: 1.0
                color: Modules.Theme.background
            }  // black @ 80%
            GradientStop {
                position: 6.0
                color: Modules.Theme.background
            }  // black @ 80% opacity
            GradientStop {
                position: 0.0
                color: "#00000000"
            }  // transparent
        }
    }
}
