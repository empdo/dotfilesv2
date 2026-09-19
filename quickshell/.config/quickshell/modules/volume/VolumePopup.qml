// VolumePopup.qml -- output, microphone, and one row per application.
//
// The application rows come from PipeWire's stream nodes, which AudioService
// keeps tracked so their volumes actually read back.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "."
import "../" as Modules

Item {
    id: root

    readonly property var streams: Modules.AudioService.streams
    readonly property int rowHeight: 44
    readonly property int rowSpacing: 10
    // Grow with the number of applications, but stop at five rows and scroll
    // past that, so a busy machine cannot push the popup off the screen.
    readonly property int shownRows: Math.min(streams.length, 5)
    readonly property int appsHeight: streams.length === 0
        ? 24
        : shownRows * rowHeight + (shownRows - 1) * rowSpacing

    implicitWidth: 320
    implicitHeight: 2 * 18                       // margins
                    + 2 * rowHeight + rowSpacing // output + input
                    + 2 * 14 + 1                 // divider and its spacing
                    + appsHeight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: root.rowSpacing

        VolumeRow {
            Layout.fillWidth: true
            glyph: Modules.AudioService.muted ? "󰟦" : "󰟥"
            label: "Output"
            volume: Modules.AudioService.volume
            muted: Modules.AudioService.muted
            onMoved: v => Modules.AudioService.setVolume(v)
            onMuteToggled: Modules.AudioService.toggleMute()
        }

        VolumeRow {
            Layout.fillWidth: true
            glyph: Modules.AudioService.sourceMuted ? "󰍭" : "󰍬"
            label: "Input"
            volume: Modules.AudioService.sourceVolume
            muted: Modules.AudioService.sourceMuted
            onMoved: v => Modules.AudioService.setNodeVolume(Modules.AudioService.source, v)
            onMuteToggled: Modules.AudioService.toggleNodeMute(Modules.AudioService.source)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            height: 1
            color: Modules.Theme.divider
        }

        Label {
            Layout.fillWidth: true
            visible: root.streams.length === 0
            text: "Nothing playing"
            color: Modules.Theme.inactive
            font.family: "Roboto Mono"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.streams.length > 0
            clip: true
            spacing: root.rowSpacing
            model: root.streams

            delegate: VolumeRow {
                required property var modelData

                width: appList.width
                glyph: modelData.audio && modelData.audio.muted
                       ? "󰟦" : "󰟥"
                iconSource: Modules.AudioService.nodeIcon(modelData)
                label: Modules.AudioService.nodeLabel(modelData)
                volume: modelData.audio ? modelData.audio.volume : 0
                muted: modelData.audio ? modelData.audio.muted : false

                onMoved: v => Modules.AudioService.setNodeVolume(modelData, v)
                onMuteToggled: Modules.AudioService.toggleNodeMute(modelData)
            }
        }
    }
}
