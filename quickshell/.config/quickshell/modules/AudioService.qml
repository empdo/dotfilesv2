// modules/AudioService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // --- Track sinks and sources ---
    readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
        if (node.isStream) {
            // Streams are the applications. isSink is true for the ones playing
            // audio out; the false ones are recording (a call's microphone leg),
            // which belong to the input slider rather than the app list.
            if (node.isSink)
                acc.streams.push(node);
        } else if (node.isSink) {
            acc.sinks.push(node);
        } else if (node.audio) {
            acc.sources.push(node);
        }
        return acc;
    }, {
        sinks: [],
        sources: [],
        streams: []
    })

    readonly property list<PwNode> sinks: nodes.sinks
    readonly property list<PwNode> sources: nodes.sources
    readonly property list<PwNode> streams: nodes.streams

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

    // --- Per-node control, for the application streams ---
    // Same guards as the sink helpers: a node that is not ready has no audio
    // object, and writing to it silently does nothing.
    function setNodeVolume(node, newVolume) {
        if (!node?.ready || !node?.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1.0, newVolume));
    }

    function toggleNodeMute(node) {
        if (!node?.ready || !node?.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    // PipeWire stream names are the raw application name ("spotify"), so give
    // them a capital. description and nickname are usually empty for streams.
    function nodeLabel(node) {
        const name = node?.description || node?.nickname || node?.name || "";
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    // The stream name is usually close enough to a desktop entry to find the
    // application's real icon ("spotify" -> spotify.desktop). Returns "" when
    // there is no match, and the row falls back to a speaker glyph.
    function nodeIcon(node) {
        const name = node?.name || "";
        if (!name)
            return "";
        const entry = DesktopEntries.heuristicLookup(name);
        if (!entry || !entry.icon)
            return "";
        return Quickshell.iconPath(entry.icon, true);
    }

    // --- Keep bindings live with PipeWire ---
    PwObjectTracker {
        // this ensures all sinks/sources stay “bound”. The streams have to be
        // tracked too, otherwise their audio object never binds and every
        // application reads back a volume of 0.
        objects: [...root.sinks, ...root.sources, ...root.streams]
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
