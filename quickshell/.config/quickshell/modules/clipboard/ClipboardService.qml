// modules/clipboard/ClipboardService.qml -- the clipboard history.
//
// Wayland only lets the focused surface read the clipboard, so Quickshell's own
// `clipboardText` is empty from a bar that never takes focus -- it was tried,
// and it sees nothing. `wl-paste --watch` goes through the data-control
// protocol instead, which is exactly what it is for, and wl-clipboard was
// already installed for `wl-copy`.
//
// Text and images get a watcher each, asking for a type apiece, because that
// is the one way to tell them apart without a race: `wl-paste --list-types`
// reports on the clipboard as it stands now, which is not necessarily the
// clipboard that triggered the notification. Asked for one type, each watcher
// only ever fires for the kind it can actually read, which was worth checking
// and does hold -- copying text leaves the image watcher silent and the other
// way round.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Past this many, the oldest fall off the end. Short on purpose: the
    // history is for the last few things you copied, not an archive, and a
    // short list is one you can read rather than search.
    readonly property int historyLimit: 15

    // Copied images are files, not rows in a JSON list, so they live beside
    // the history rather than in it.
    readonly property string imageDir: Quickshell.cachePath("clipboard")

    // Newest first.
    property var entries: []

    readonly property bool hasEntries: entries.length > 0

    // Raised by the quick settings tile and answered by ClipboardPanel. The
    // panel is a window owned by shell.qml, so a tile in a bar popup has no
    // way to reach it directly.
    signal toggleRequested

    function toggle() {
        root.toggleRequested();
    }

    // --- watching -------------------------------------------------------------

    // Each entry is printed followed by an ASCII record separator, so snippets
    // containing newlines -- most of the interesting ones -- arrive whole
    // rather than a line at a time.
    Process {
        running: true
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cat; printf '\\036'"]

        stdout: SplitParser {
            splitMarker: "\u001e"
            onRead: data => root.rememberText(data)
        }
    }

    // Images are written to a file named after their own content hash, which
    // buys deduplication for nothing: copying the same picture twice lands on
    // the same path instead of filling the cache with identical files.
    Process {
        running: true
        command: ["wl-paste", "--type", "image/png", "--watch", "sh", "-c",
                  'mkdir -p "$1" && t="$1/.incoming.$$" && cat > "$t" '
                  + '&& h=$(sha256sum "$t" | cut -c1-16) && f="$1/$h.png" '
                  + '&& mv -f "$t" "$f" && printf "%s\\t%s\\036" "$f" "$(wc -c < "$f")"',
                  "sh", root.imageDir]

        stdout: SplitParser {
            splitMarker: "\u001e"
            onRead: data => root.rememberImage(data)
        }
    }

    // --- remembering ------------------------------------------------------------

    function rememberText(text) {
        // Whitespace-only selections are almost always an accident of dragging.
        if (!text || text.trim() === "")
            return;

        root.add({
            kind: "text",
            text: text,
            time: Date.now()
        }, e => e.kind === "text" && e.text === text);
    }

    function rememberImage(record) {
        const parts = record.split("\t");
        if (parts.length < 2 || parts[0] === "")
            return;

        root.add({
            kind: "image",
            path: parts[0],
            bytes: parseInt(parts[1], 10) || 0,
            time: Date.now()
        }, e => e.kind === "image" && e.path === parts[0]);
    }

    // Copying something already in the list moves it up rather than stacking a
    // second identical row.
    function add(entry, isSame) {
        const rest = root.entries.filter(e => !isSame(e));
        const kept = [entry].concat(rest);
        root.entries = kept.slice(0, root.historyLimit);
        // Whatever fell off the end takes its file with it.
        for (const dropped of kept.slice(root.historyLimit))
            root.discard(dropped);
        root.save();
    }

    // --- using ------------------------------------------------------------------

    // The text goes in on stdin: wl-copy joins its arguments with spaces,
    // which would flatten every newline in it.
    function copy(entry) {
        if (entry.kind === "image")
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", entry.path]);
        else
            Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "sh", entry.text]);
    }

    function remove(entry) {
        root.entries = root.entries.filter(e => e !== entry);
        root.discard(entry);
        root.save();
    }

    function clear() {
        const all = root.entries;
        root.entries = [];
        for (const entry of all)
            root.discard(entry);
        root.save();
    }

    // An image row owns its file, so dropping the row deletes it. Nothing else
    // can be pointing at it: the name is the content hash, so a second copy of
    // the same picture is the same row.
    function discard(entry) {
        if (entry.kind === "image" && entry.path)
            Quickshell.execDetached(["rm", "-f", entry.path]);
    }

    // --- presentation ------------------------------------------------------------

    function preview(entry) {
        // The list re-evaluates a delegate as its row leaves the model, so
        // everything the view calls has to survive being handed nothing.
        if (!entry)
            return "";
        if (entry.kind === "image")
            return "Image";

        // The first line with anything on it: a snippet that starts with a
        // blank line would otherwise show as an empty row.
        const lines = entry.text.split("\n");
        for (const line of lines)
            if (line.trim() !== "")
                return line.trim();
        return entry.text.trim();
    }

    function detail(entry) {
        if (!entry)
            return "";
        if (entry.kind === "image")
            return "PNG · " + root.formatBytes(entry.bytes);

        const lines = entry.text.split("\n").length;
        const chars = entry.text.length
                    + (entry.text.length === 1 ? " character" : " characters");
        return lines > 1 ? lines + " lines · " + chars : chars;
    }

    function formatBytes(bytes) {
        if (!bytes)
            return "unknown size";
        if (bytes < 1024)
            return bytes + " B";
        if (bytes < 1024 * 1024)
            return Math.round(bytes / 1024) + " kB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }

    // What a query is matched against. An image has no text of its own, so it
    // answers to the word for what it is.
    function haystack(entry) {
        if (!entry)
            return "";
        return entry.kind === "image" ? "image" : entry.text;
    }

    // --- persistence ----------------------------------------------------------
    //
    // ~/.local/state is 0700, so this is as private as anything else in there --
    // but it is still plain text on disk, and a password pasted out of a manager
    // lands in it like anything else. `Del` drops a row; `qs ipc call clipboard
    // clear` empties the lot.

    FileView {
        id: stateFile
        path: Quickshell.statePath("clipboard.json")
        atomicWrites: true

        onLoaded: {
            try {
                const parsed = JSON.parse(stateFile.text());
                const list = Array.isArray(parsed.entries) ? parsed.entries : [];
                // Rows written before images existed have no kind.
                root.entries = list.map(e => Object.assign({ kind: "text" }, e));
            } catch (e) {
                console.warn("clipboard: could not parse clipboard.json:", e);
                root.entries = [];
            }
            root.sweep();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.save();
        }
    }

    function save() {
        stateFile.setText(JSON.stringify({
            entries: root.entries
        }, null, 2));
    }

    // Files can outlive their rows -- a shell killed between writing the image
    // and saving the history, an old cache from before the limit was what it
    // is now -- so the newest `historyLimit` files stay and the rest go. Bare
    // `rm` rather than anything cleverer, because the directory only ever
    // holds this module's own PNGs.
    function sweep() {
        Quickshell.execDetached(["sh", "-c",
            'cd "$1" 2>/dev/null && ls -1t | tail -n +$(($2 + 1)) | xargs -r rm -f',
            "sh", root.imageDir, String(root.historyLimit)]);
    }
}
