pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// the focus timer: work, then a break, shown in the island as it runs; in
// rounds if the settings say so, with the music paused for each break
Singleton {
    id: f

    property string phase: ""           // "", "focus" or "break"
    property int total: 0               // seconds in this phase
    property real ends: 0               // when it ends, ms since the epoch
    property int left: 0                // seconds to go
    readonly property bool active: phase !== ""
    readonly property real progress: total > 0 ? 1 - left / total : 0
    signal finished(string phase)

    function start(minutes) {
        begin("focus", (minutes > 0 ? minutes : Config.o.focus.minutes) * 60);
    }
    function stop() {
        if (phase === "break") resume();
        phase = ""; tick.stop();
        save();
    }
    function toggle() { active ? stop() : start(0); }
    function begin(p, secs) {
        if (p === "break" && Config.o.focus.music && Media.playing) { paused = Media.player; paused.pause(); }
        if (p === "focus") resume();
        phase = p;
        total = secs;
        ends = Date.now() + secs * 1000;
        left = secs;
        tick.restart();
        save();
    }

    // a restart picks up where it was: it counts against the clock anyway. One that ended
    // while the shell was away is counted, and stops there
    function save() { Saved.set("focus", phase === "" ? null : { phase: phase, total: total, ends: ends }); }
    Component.onCompleted: {
        const s = Saved.get("focus", null);
        if (!s || !s.phase) return;
        if (s.ends <= Date.now()) {
            if (s.phase === "focus") count();
            Saved.set("focus", null);
            return;
        }
        phase = s.phase;
        total = s.total;
        ends = s.ends;
        left = Math.max(0, Math.round((ends - Date.now()) / 1000));
        tick.restart();
    }

    // counts against the clock, so a suspend in the middle doesn't stretch it
    Timer {
        id: tick
        interval: 1000; repeat: true
        onTriggered: {
            f.left = Math.max(0, Math.round((f.ends - Date.now()) / 1000));
            if (f.left > 0) return;
            const was = f.phase;
            if (was === "focus") f.count();
            if (was === "focus" && Config.o.focus.breakMinutes > 0) f.begin("break", Config.o.focus.breakMinutes * 60);
            else if (Config.o.focus.rounds) f.begin("focus", Config.o.focus.minutes * 60);
            else f.stop();
            f.finished(was);
        }
    }

    // the player a break paused, to play again after it (not one you paused yourself)
    property var paused: null
    function resume() {
        if (paused && !paused.isPlaying) paused.play();
        paused = null;
    }

    // finished focus sessions, kept across restarts: today's, and a count for each day of
    // the last year (the focus history widget's heatmap and streak)
    property int today: 0
    property string day: ""
    property var days: ({})             // "2026-10-23": 3
    FileView {
        id: store
        path: Theme.cacheDir + "/focus.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                f.day = d.day;
                f.today = d.day === f.date() ? d.today : 0;
                f.days = d.days ?? {};
                // from before there were days: today's count is a start
                if (!d.days && d.day && d.today) f.days = { [f.iso(new Date(d.day))]: d.today };
            } catch (e) {}
        }
    }
    function date() { return new Date().toDateString(); }
    function iso(d) { return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0"); }
    // from the file, not the properties: a restart can count one before they're read
    function count() {
        let d = {};
        try { d = JSON.parse(store.text()); } catch (e) {}
        day = date();
        today = (d.day === day ? d.today ?? 0 : 0) + 1;
        const all = Object.assign({}, d.days ?? {});
        all[iso(new Date())] = (all[iso(new Date())] ?? 0) + 1;
        // a year is enough
        const keep = iso(new Date(Date.now() - 370 * 86400000));
        for (const k of Object.keys(all)) if (k < keep) delete all[k];
        days = all;
        store.setText(JSON.stringify({ day: day, today: today, days: all }));
    }
    // days in a row with at least one, up to today (or yesterday, while today has none yet)
    readonly property int streak: {
        let n = 0;
        const t = new Date();
        let at = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        if (!(days[iso(at)] > 0)) at = new Date(at.getTime() - 86400000);
        while (days[iso(at)] > 0) { n++; at = new Date(at.getFullYear(), at.getMonth(), at.getDate() - 1); }
        return n;
    }
    function countOn(d) { return days[iso(d)] ?? 0; }

    function clock(s) {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
