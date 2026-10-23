pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your calendars' events (`yoru events`: calendar.feeds, .ics links or files), asked for every
// quarter of an hour and when the feeds change; what's on a day, what's next, and a word
// (`due`) a few minutes before each starts (calendar.remind)
Singleton {
    id: ev

    property var list: []               // [{ title, start, end, allDay, where, cal }], by start
    readonly property var feeds: Config.o.calendar.feeds
    onFeedsChanged: again.restart()
    Timer { id: again; interval: 800; onTriggered: ev.refresh() }
    Timer { interval: 15 * 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ev.refresh() }
    function refresh() {
        if (feeds.length === 0) { list = []; return; }
        if (!ask.running) ask.running = true;
    }
    Process {
        id: ask
        command: ["yoru", "events"]
        stdout: StdioCollector { onStreamFinished: { try { ev.list = JSON.parse(this.text); } catch (e) {} } }
    }

    // its times are local: "2026-10-23" or "2026-10-23T14:00" (Date() would take the first for UTC)
    function when(s) {
        const m = String(s).match(/^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}))?/);
        return m ? new Date(+m[1], +m[2] - 1, +m[3], +(m[4] ?? 0), +(m[5] ?? 0)) : new Date(NaN);
    }
    // what touches a day: an all-day one from its start up to (not on) its end
    function onDay(d) {
        const a = new Date(d.getFullYear(), d.getMonth(), d.getDate()), b = new Date(a.getTime() + 86400000);
        return list.filter(e => {
            const s = when(e.start), t = when(e.end);
            return e.allDay ? s < b && (t > a || t.getTime() === s.getTime() && s >= a) : s < b && (t > a || s >= a);
        });
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    // what hasn't ended yet, soonest first
    readonly property var upcoming: list.filter(e => when(e.end) > clock.date || (!e.allDay && when(e.start) >= clock.date))
    function words(e) {
        const s = when(e.start), now = clock.date;
        const day = d => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
        const days = Math.round((day(s) - day(now)) / 86400000);
        const time = e.allDay ? "all day" : Qt.formatTime(s, Config.o.island.clock24 ? "HH:mm" : "h:mm AP");
        if (!e.allDay && s <= now) return "now, until " + Qt.formatTime(when(e.end), Config.o.island.clock24 ? "HH:mm" : "h:mm AP");
        const mins = Math.round((s - now) / 60000);
        if (!e.allDay && mins < 60) return "in " + mins + (mins === 1 ? " minute" : " minutes");
        return (days === 0 ? "today" : days === 1 ? "tomorrow" : days < 7 ? Qt.formatDate(s, "dddd") : Qt.formatDate(s, "d MMMM")) + ", " + time;
    }

    // a few minutes before each starts, once
    signal due(var e)
    property var told: ({})
    Timer {
        interval: 30000; repeat: true; running: Config.o.calendar.remind > 0 && ev.list.length > 0
        onTriggered: {
            const ahead = Config.o.calendar.remind * 60000, now = Date.now();
            for (const e of ev.list) {
                if (e.allDay) continue;
                const t = ev.when(e.start).getTime() - now, key = e.start + e.title;
                if (t > 0 && t <= ahead && !ev.told[key]) {
                    ev.told[key] = true;
                    ev.due(e);
                }
            }
        }
    }
}
