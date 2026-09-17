// modules/AudioService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // --- Track sinks and sources ---
    readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
        if (!node.isStream) {
            if (node.isSink)
                acc.sinks.push(node);
            else if (node.audio)
                acc.sources.push(node);
        }
        return acc;
    }, {
        sinks: [],
        sources: []
    })

    readonly property list<PwNode> sinks: nodes.sinks
    readonly property list<PwNode> sources: nodes.sources

    // --- Default devices ---
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // --- Reactive state ---
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // --- Volume control (safe against unbound nodes) ---
    function setVolume(newVolume) {
        if (!sink?.ready || !sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.0, newVolume));
    }

    function toggleMute() {
        if (!sink?.ready || !sink?.audio)
            return;
        sink.audio.muted = !sink.audio.muted;
    }

    function incrementVolume(amount) {
        setVolume(volume + (amount || 0.05));
    }

    function decrementVolume(amount) {
        setVolume(volume - (amount || 0.05));
    }

    // --- Keep bindings live with PipeWire ---
    PwObjectTracker {
        // this ensures all sinks/sources stay “bound”
        objects: [...root.sinks, ...root.sources]
    }

    Component.onCompleted: {
        console.log("Default sink:", sink ? sink.name : "none");
        console.log("Description:", sink ? sink.description : "none");
        console.log("Audio channels:", sink?.audio?.channels);
        console.log("Current volume:", sink?.audio?.volume);

        console.log("Available Pipewire properties:");
        for (let key in Pipewire) {
            if (Pipewire.hasOwnProperty(key))
                console.log("  •", key, typeof Pipewire[key]);
        }
    }
}
