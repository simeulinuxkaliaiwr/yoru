pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// the notification daemon (instead of mako while yoru runs): new ones drop
// out of the island, the rest wait in the control centre
Singleton {
    id: notifs

    property bool dnd: false
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
