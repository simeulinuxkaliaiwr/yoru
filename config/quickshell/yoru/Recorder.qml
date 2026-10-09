pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// screen recording with wl-screenrec (on the CPU, as kon does: the hardware
// encoder was unreliable here). The island shows it running; stopping it
// saves to ~/Videos/Recordings and copies the path.
Singleton {
    id: rec

    readonly property bool active: proc.running
    property int seconds: 0
    property string file: ""
    property real started: 0
    signal saved(string file, bool ok)

    // area: "" for the focused screen, or a slurp geometry
    function start(area) {
        if (active) return;
        const dir = Quickshell.env("HOME") + "/Videos/Recordings";
        file = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".mp4";
        const where = area !== "" ? ["-g", area] : ["-o", Aro.focusedOutput];
        proc.command = ["sh", "-c", 'mkdir -p "$1" && shift && exec wl-screenrec --no-hw "$@"', "sh", dir].concat(where, ["-f", file]);
        started = Date.now();
        seconds = 0;
        proc.running = true;
    }
    function stop() { if (active) proc.signal(2); }          // SIGINT: wl-screenrec finishes the file
    function toggle(area) { active ? stop() : start(area); }
    // pick an area first, then record it
    function area() {
        if (active) { stop(); return; }
        pick.running = true;
    }

    Process {
        id: pick
        command: ["slurp", "-d", "-b", "00000077", "-w", "2"]
        stdout: StdioCollector { onStreamFinished: { const g = this.text.trim(); if (g !== "") rec.start(g); } }
    }
    Process {
        id: proc
        onExited: (code) => {
            const ok = code === 0 || code === 130 || code === 2;
            if (ok) Quickshell.execDetached(["wl-copy", rec.file]);
            rec.saved(rec.file, ok);
        }
    }
    Timer {
        interval: 1000; repeat: true; running: rec.active
        onTriggered: rec.seconds = Math.round((Date.now() - rec.started) / 1000)
    }
}
