// modules/media/MediaService.qml
//
// Picks the one player the bar should speak for, out of however many MPRIS
// clients are running, and exposes it as a flat set of properties so the
// widget and the popup never disagree about what is playing.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property bool hasPlayers: players.length > 0

    // Set from the popup when the user picks a player by hand. Kept as the
    // player's uniqueId rather than the object, so a client that restarts
    // does not leave a dangling reference.
    property int preferredId: -1

    readonly property var active: {
        // An explicit choice wins, for as long as that player is still around.
        for (const p of players)
            if (p.uniqueId === root.preferredId)
                return p;
        // Otherwise whatever is actually making noise, then whatever has a
        // track loaded, so a paused Spotify still beats an idle client.
        for (const p of players)
            if (p.isPlaying)
                return p;
        for (const p of players)
            if (p.trackTitle)
                return p;
        return players[0] || null;
    }

    readonly property bool playing: active ? active.isPlaying : false
    readonly property string title: active ? active.trackTitle : ""
    readonly property string artist: active ? active.trackArtist : ""
    readonly property string album: active ? active.trackAlbum : ""
    readonly property string artUrl: active ? active.trackArtUrl : ""
    readonly property string identity: active ? active.identity : ""

    readonly property bool canNext: active ? active.canGoNext : false
    readonly property bool canPrevious: active ? active.canGoPrevious : false
    readonly property bool canToggle: active ? active.canTogglePlaying : false
    readonly property bool canSeek: active ? (active.canSeek && active.positionSupported) : false

    readonly property real length: active && active.lengthSupported ? active.length : 0

    // MPRIS does not push position updates, so poll it while something is
    // playing. `elapsed` is what the progress bar binds to.
    property real elapsed: 0

    Timer {
        running: root.playing && root.active !== null
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = root.active ? root.active.position : 0
    }

    // A new track restarts the bar immediately rather than waiting for the poll.
    onTitleChanged: elapsed = active ? active.position : 0

    function playPause() {
        if (active && active.canTogglePlaying)
            active.togglePlaying();
    }

    function next() {
        if (active && active.canGoNext)
            active.next();
    }

    function previous() {
        if (active && active.canGoPrevious)
            active.previous();
    }

    function seekFraction(f) {
        if (!active || !root.canSeek || root.length <= 0)
            return;
        active.position = Math.max(0, Math.min(root.length, f * root.length));
        root.elapsed = active.position;
    }

    function selectPlayer(player) {
        root.preferredId = player ? player.uniqueId : -1;
    }

    // mm:ss, for the two ends of the progress bar.
    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

}
