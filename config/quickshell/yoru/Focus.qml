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

    // finished focus sessions today, kept across restarts
    property int today: 0
    property string day: ""
    FileView {
        id: store
        path: Theme.cacheDir + "/focus.json"
        blockLoading: true
        printErrors: false
        onLoaded: { try { const d = JSON.parse(text()); f.day = d.day; f.today = d.day === f.date() ? d.today : 0; } catch (e) {} }
    }
    function date() { return new Date().toDateString(); }
    // from the file, not the properties: a restart can count one before they're read
    function count() {
        let d = {};
        try { d = JSON.parse(store.text()); } catch (e) {}
        day = date();
        today = (d.day === day ? d.today ?? 0 : 0) + 1;
        store.setText(JSON.stringify({ day: day, today: today }));
    }

    function clock(s) {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
