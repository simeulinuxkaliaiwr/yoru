pragma Singleton

import Quickshell
import QtQuick

// a stopwatch and a kitchen timer for the timers widget (the focus timer is Focus)
Singleton {
    id: t

    // stopwatch: `base` ms banked from earlier runs, plus the run since `since`
    property bool watching: false
    property real since: 0
    property real base: 0
    property real watched: 0            // seconds, ticking while it runs
    function watchToggle() {
        if (watching) { base += Date.now() - since; watching = false; }
        else { since = Date.now(); watching = true; }
        tick();
    }
    function watchReset() { watching = false; base = 0; watched = 0; }

    // countdown: add minutes, it starts at once; a notification when it's done
    property real ends: 0
    property int total: 0               // seconds it was set for
    property int left: 0
    readonly property bool counting: ends > 0
    function add(minutes) {
        const now = Date.now();
        if (!counting) { ends = now; total = 0; }
        ends += minutes * 60000;
        total += minutes * 60;
        tick();
    }
    function cancel() { ends = 0; total = 0; left = 0; }

    function tick() {
        watched = (base + (watching ? Date.now() - since : 0)) / 1000;
        if (counting) {
            left = Math.max(0, Math.ceil((ends - Date.now()) / 1000));
            if (left === 0) {
                Quickshell.execDetached(["notify-send", "-a", "yoru", "-i", "timer", "Time's up", Math.round(total / 60) + " minute timer"]);
                cancel();
            }
        }
    }
    Timer { interval: 250; repeat: true; running: t.watching || t.counting; onTriggered: t.tick() }

    function clock(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, sec = s % 60;
        return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(sec).padStart(2, "0");
    }
}
