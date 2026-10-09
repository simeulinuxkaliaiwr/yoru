pragma Singleton

import Quickshell
import QtQuick

// the focus timer: work, then a break, shown in the island as it runs
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
    function stop() { phase = ""; tick.stop(); }
    function toggle() { active ? stop() : start(0); }
    function begin(p, secs) {
        phase = p;
        total = secs;
        ends = Date.now() + secs * 1000;
        left = secs;
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
            if (was === "focus" && Config.o.focus.breakMinutes > 0) f.begin("break", Config.o.focus.breakMinutes * 60);
            else f.stop();
            f.finished(was);
        }
    }

    function clock(s) {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
