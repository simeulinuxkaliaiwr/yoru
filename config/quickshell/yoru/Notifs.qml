pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// the notification daemon (instead of mako while yoru runs): new ones drop
// out of the island, the rest wait in the control centre. Each is also kept
// in a history (~/.cache/yoru/notifications.json, the last notifications.keep), grouped
// by app there, so one that came during do not disturb or a restart isn't lost. Each app
// can be shown, kept quietly (no pop-up) or never kept (notifications.apps); a sound can
// come with them
Singleton {
    id: notifs

    // do not disturb: by hand, during quiet hours, or while focusing
    property bool manualDnd: false
    onManualDndChanged: Saved.setThisBoot("dnd", manualDnd)
    Component.onCompleted: manualDnd = Saved.getThisBoot("dnd", false)
    readonly property bool dnd: manualDnd || quietHours || (Focus.phase === "focus" && Config.o.focus.quiet)
    property bool quietHours: false
    function toggleDnd() { manualDnd = !dnd; }
    function inQuiet() {
        const q = Config.o.quiet;
        if (!q.schedule) return false;
        const m = s => { const [h, mi] = s.split(":").map(Number); return h * 60 + (mi || 0); };
        const d = new Date(), now = d.getHours() * 60 + d.getMinutes(), a = m(q.from), b = m(q.to);
        return a <= b ? now >= a && now < b : now >= a || now < b;     // overnight wraps
    }
    Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: notifs.quietHours = notifs.inQuiet() }
    Connections { target: Config.o.quiet; function onScheduleChanged() { notifs.quietHours = notifs.inQuiet(); } }
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    signal arrived(var n)

    // the history: [{ key, app, icon, summary, body, time }], newest first
    property var history: []
    readonly property int count: history.length
    property int serial: 0
    FileView {
        id: store
        path: Theme.cacheDir + "/notifications.json"
        printErrors: false
        onLoaded: {
            try { notifs.history = JSON.parse(text()); } catch (e) {}
            notifs.serial = notifs.history.reduce((m, h) => Math.max(m, h.key), 0);
        }
    }
    function save() { store.setText(JSON.stringify(history)); }
    // the live notification behind a record, while it's still around (for its actions)
    property var live: ({})
    function remember(n) {
        const key = ++serial;
        const icon = image(n);
        const rec = {
            key: key,
            app: n.appName || n.desktopEntry || "Unknown",
            entry: n.desktopEntry || "",
            // images handed over in memory don't outlive the shell
            icon: icon.startsWith("image://") ? "" : icon,
            summary: n.summary, body: n.body, time: Date.now()
        };
        const l = Object.assign({}, live); l[key] = n; live = l;
        n.closed.connect(() => { const m = Object.assign({}, notifs.live); delete m[key]; notifs.live = m; });
        history = [rec].concat(history).slice(0, Math.max(10, Config.o.notifications.keep));
        save();
        unseen++;
    }
    // new since the control centre was last opened: the island's dot
    property int unseen: 0
    function forget(key) {
        live[key]?.dismiss();
        history = history.filter(h => h.key !== key);
        save();
    }
    // one clicked in the history: its default action while the app still holds it,
    // else the app itself. False when there was nothing to open
    function open(rec) {
        const def = live[rec.key]?.actions?.find(a => a.identifier === "default");
        if (def) def.invoke();
        else {
            const e = (rec.entry ? Apps.entry(rec.entry) : null)
                   ?? Apps.entries.find(x => x.name.toLowerCase() === String(rec.app).toLowerCase()) ?? null;
            if (!e) return false;
            if (!Apps.raise(e)) Apps.run(e);
        }
        forget(rec.key);
        return true;
    }
    function forgetApp(app) {
        for (const h of history) if (h.app === app) live[h.key]?.dismiss();
        history = history.filter(h => h.app !== app);
        save();
    }
    // what an app's notifications do: show, quiet (kept, no pop-up) or never (not kept)
    function rule(app) { return Config.o.notifications.apps[app] ?? "show"; }
    function setRule(app, r) {
        const a = Object.assign({}, Config.o.notifications.apps);
        if (r === "show") delete a[app]; else a[app] = r;
        Config.o.notifications.apps = a;
    }

    // [{ app, icon, items }], the app with the newest one first
    readonly property var groups: {
        const by = {}, order = [];
        for (const h of history) {
            if (!by[h.app]) { by[h.app] = { app: h.app, icon: "", items: [] }; order.push(h.app); }
            by[h.app].items.push(h);
            if (!by[h.app].icon && h.icon) by[h.app].icon = h.icon;
        }
        return order.map(a => by[a]);
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        persistenceSupported: true
        onNotification: n => {
            const rule = notifs.rule(n.appName || n.desktopEntry || "");
            if (rule === "never") return;              // not tracked: it's gone
            n.tracked = true;
            notifs.remember(n);
            const critical = n.urgency === NotificationUrgency.Critical;
            if ((notifs.dnd || rule === "quiet") && !critical) return;
            notifs.arrived(n);
            if (Config.o.notifications.sound)
                Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/" + (critical ? "dialog-warning.oga" : "message-new-instant.oga")]);
        }
    }

    function clear() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        history = [];
        save();
    }

    // an icon for a notification: its image, its app's icon, or nothing
    function image(n) {
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon) return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:") ? n.appIcon : Quickshell.iconPath(n.appIcon, true);
        const e = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        return e ? Quickshell.iconPath(e.icon, true) : "";
    }
}
