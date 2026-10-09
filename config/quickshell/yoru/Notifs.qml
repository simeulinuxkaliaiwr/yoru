pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// the notification daemon (instead of mako while yoru runs): new ones drop
// out of the island, the rest wait in the control centre
Singleton {
    id: notifs

    // do not disturb: by hand, during quiet hours, or while focusing
    property bool manualDnd: false
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
    readonly property int count: list.length
    signal arrived(var n)

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            if (!notifs.dnd || n.urgency === NotificationUrgency.Critical) notifs.arrived(n);
        }
    }

    function clear() { for (const n of server.trackedNotifications.values.slice()) n.dismiss(); }

    // an icon for a notification: its image, its app's icon, or nothing
    function image(n) {
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon) return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:") ? n.appIcon : Quickshell.iconPath(n.appIcon, true);
        const e = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        return e ? Quickshell.iconPath(e.icon, true) : "";
    }
}
