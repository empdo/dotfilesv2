// modules/notifications/NotificationService.qml -- the notification daemon.
//
// This owns org.freedesktop.Notifications, which is why dunst has to go: the
// name is D-Bus activated and whichever of the two claims it first wins, so
// having both installed makes which daemon you get a race.
//
// Everything on screen comes from two lists, both newest first. `entries` is
// the history behind the bar's bell, `popups` is the subset currently up as a
// toast; dismissing a toast only takes it out of the second.
//
// An entry outlives the Notification object it came from. Apps close and
// replace their own notifications all the time (Spotify rewriting "now
// playing"), and Quickshell deletes the object when they do -- so each entry
// keeps a snapshot of the fields it needs and simply drops the live reference,
// rather than having rows vanish out of the history by themselves.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // How long a toast stays up when the app does not ask for a time, in ms,
    // indexed by urgency (low, normal, critical). Critical sits there until it
    // is dismissed, the way dunst leaves it.
    readonly property var defaultTimeouts: [5000, 7000, 0]

    // Oldest rows fall off the end of the history past this many.
    readonly property int historyLimit: 50

    // Persisted, so it survives a shell restart -- silencing notifications and
    // then having them come back because quickshell reloaded is the one way
    // this feature can really fail.
    property alias dnd: adapter.dnd

    // Whether the bell wears its unread count. Persisted alongside do not
    // disturb, for the same reason: a preference about how loudly the shell
    // talks to you should not quietly reset when it reloads.
    property alias badge: adapter.badge

    property var entries: []
    property var popups: []

    // Badge count on the bell: how many have arrived since the list was opened.
    property int unseen: 0

    readonly property bool hasEntries: entries.length > 0

    // Read by formatAge, so the history's "5m" labels keep up without every
    // row owning a clock of its own.
    property double now: Date.now()

    Timer {
        running: root.hasEntries
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    signal opened

    // --- incoming ------------------------------------------------------------

    NotificationServer {
        id: server

        // Nothing here survives a config reload anyway, and keeping stale
        // objects around would double rows in the history.
        keepOnReload: false

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            // Without this Quickshell drops the notification the moment this
            // handler returns.
            notification.tracked = true;
            root.receive(notification);
        }
    }

    Component {
        id: entryComponent

        QtObject {
            property int nid: 0
            property string appName: ""
            property string appIcon: ""
            property string image: ""
            property string desktopEntry: ""
            property string summary: ""
            property string body: ""
            property int urgency: NotificationUrgency.Normal
            property var actions: []
            property double time: 0
            property int timeout: 0

            // Transient notifications (progress popups, volume OSDs) get a
            // toast but no row in the history, so they are thrown away as
            // soon as the toast goes rather than when the row is cleared.
            property bool keep: true

            // Null once the notification itself is gone; the row stays.
            property var notification: null

            // Set while we are the ones closing it, so the closed handler does
            // not try to remove the entry a second time.
            property bool closing: false

            // Bumped every time the notification behind this entry is replaced,
            // so a toast already on screen knows to start its clock over.
            property int revision: 0
        }
    }

    function receive(notification) {
        const entry = entryComponent.createObject(root, {
            nid: notification.id,
            time: Date.now(),
            notification: notification
        });

        root.refresh(entry);

        // An app replacing one of its own notifications (a download that keeps
        // rewriting its progress, a chat client collapsing a thread) updates
        // the Notification in place rather than sending a new one, so the
        // entry has to follow the object instead of keeping the snapshot it
        // was built from.
        const onChanged = function () {
            root.refresh(entry);
            root.show(entry);
        };
        for (const signal of ["appNameChanged", "appIconChanged", "imageChanged",
                              "summaryChanged", "bodyChanged", "urgencyChanged",
                              "actionsChanged", "transientChanged"])
            notification[signal].connect(onChanged);

        notification.closed.connect(function () {
            entry.notification = null;
            entry.actions = [];
            if (!entry.closing)
                root.forget(entry);
        });

        // Transient notifications are progress popups and volume OSDs: worth a
        // toast, not worth a row in the history.
        if (entry.keep) {
            root.entries = [entry].concat(root.entries);
            root.unseen++;
        }

        root.show(entry);
        root.trim();
    }

    // Copies the live notification across, which is all the entry has to go on
    // once the notification itself is gone.
    function refresh(entry) {
        const notification = entry.notification;
        if (!notification)
            return;

        entry.appName = notification.appName;
        entry.appIcon = notification.appIcon;
        entry.image = notification.image;
        entry.desktopEntry = notification.desktopEntry;
        entry.summary = notification.summary;
        entry.body = notification.body;
        entry.urgency = notification.urgency;
        entry.actions = notification.actions;
        entry.keep = !notification.transient;

        // expireTimeout is the raw spec value in milliseconds: -1 means "you
        // decide", 0 means never expire.
        const asked = notification.expireTimeout;
        entry.timeout = asked > 0 ? asked
                      : asked === 0 ? 0
                      : root.defaultTimeouts[entry.urgency];

        entry.revision++;
    }

    // Puts a toast up, if it is not already up and it is allowed to be.
    function show(entry) {
        if (root.popups.indexOf(entry) !== -1)
            return;

        // Critical notifications ignore do not disturb -- being impossible to
        // silence by accident is the whole point of the urgency.
        if (!root.dnd || entry.urgency === NotificationUrgency.Critical)
            root.popups = [entry].concat(root.popups);
        else if (!entry.keep)
            root.close(entry);   // silenced and unkept: nothing would ever show it
    }

    // --- dismissing ----------------------------------------------------------

    // Takes the toast off screen but leaves the row in the history -- unless
    // the notification was transient, in which case the toast was all of it.
    function dismissPopup(entry) {
        root.popups = root.popups.filter(e => e !== entry);
        if (!entry.keep) {
            root.close(entry);
            entry.destroy();
        }
    }

    function dismissPopups() {
        const shown = root.popups;
        root.popups = [];
        for (const entry of shown) {
            if (!entry.keep) {
                root.close(entry);
                entry.destroy();
            }
        }
    }

    // Drops the row entirely, and tells the sending app about it.
    function remove(entry) {
        root.popups = root.popups.filter(e => e !== entry);
        root.entries = root.entries.filter(e => e !== entry);
        root.close(entry);
        root.clampUnseen();
        entry.destroy();
    }

    function clear() {
        const all = root.entries;
        root.popups = [];
        root.entries = [];
        for (const entry of all) {
            root.close(entry);
            entry.destroy();
        }
        root.unseen = 0;
    }

    function invoke(entry, action) {
        if (action)
            action.invoke();
        root.remove(entry);
    }

    function markSeen() {
        root.unseen = 0;
    }

    // Rows can leave without being read -- an app closing its own notification,
    // or the oldest falling off the end -- and a badge promising more than the
    // list holds is worse than no badge.
    function clampUnseen() {
        root.unseen = Math.min(root.unseen, root.entries.length);
    }

    // Tell the app we are done with a notification, if it is still live.
    function close(entry) {
        if (!entry.notification)
            return;
        entry.closing = true;
        entry.notification.dismiss();
        entry.notification = null;
    }

    // Removal driven from the app's side: the object is already gone, so there
    // is nothing to close, only a row to take out.
    function forget(entry) {
        root.popups = root.popups.filter(e => e !== entry);
        root.entries = root.entries.filter(e => e !== entry);
        root.clampUnseen();
        entry.destroy();
    }

    function trim() {
        if (root.entries.length <= root.historyLimit)
            return;
        const dropped = root.entries.slice(root.historyLimit);
        root.entries = root.entries.slice(0, root.historyLimit);
        root.clampUnseen();
        for (const entry of dropped) {
            root.popups = root.popups.filter(e => e !== entry);
            root.close(entry);
            entry.destroy();
        }
    }

    // --- presentation helpers -------------------------------------------------

    // Notifications name their icon in three different ways depending on the
    // app: an image hint (album art, an avatar), a themed icon name, or only a
    // desktop entry to look one up from.
    function iconSource(entry) {
        if (entry.image)
            return entry.image;
        if (entry.appIcon)
            return Quickshell.iconPath(entry.appIcon, true);
        if (entry.desktopEntry) {
            const de = DesktopEntries.byId(entry.desktopEntry);
            if (de && de.icon)
                return Quickshell.iconPath(de.icon, true);
        }
        return "";
    }

    function formatAge(time) {
        const seconds = Math.max(0, Math.floor((root.now - time) / 1000));
        if (seconds < 60)
            return "now";
        if (seconds < 3600)
            return Math.floor(seconds / 60) + "m";
        if (seconds < 86400)
            return Math.floor(seconds / 3600) + "h";
        return Math.floor(seconds / 86400) + "d";
    }

    // --- persisted state -------------------------------------------------------

    FileView {
        id: stateFile
        path: Quickshell.statePath("notifications.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool dnd: false
            property bool badge: true
        }
    }
}
