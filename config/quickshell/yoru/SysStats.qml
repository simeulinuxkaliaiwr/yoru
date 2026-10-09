pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// processor, memory and temperature, read from /proc and /sys while
// something is showing them (`watchers` counts who is)
Singleton {
    id: st

    property int watchers: 0
    property real cpu: 0                // 0..1
    property real mem: 0                // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0               // °C
    property var last: null

    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: st.watchers > 0
        onTriggered: { stat.reload(); meminfo.reload(); st.read(); sensor.running = true; }
    }
    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    // the Ryzen's own sensor if there is one, else the first thermal zone
    Process {
        id: sensor
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] || [ \"$(cat $h/name)\" = coretemp ] && cat $h/temp1_input && exit; done; cat /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector { onStreamFinished: { const v = parseInt(this.text); if (!isNaN(v)) st.temp = v / 1000; } }
    }

    function read() {
        const f = stat.text().split("\n")[0].split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
        if (last) {
            const dt = total - last.total;
            if (dt > 0) cpu = 1 - (idle - last.idle) / dt;
        }
        last = { idle: idle, total: total };
        const m = {};
        for (const l of meminfo.text().split("\n")) {
            const p = l.split(/:\s+/);
            if (p.length === 2) m[p[0]] = parseInt(p[1]);
        }
        memTotalGb = m.MemTotal / 1048576;
        memUsedGb = (m.MemTotal - m.MemAvailable) / 1048576;
        mem = memUsedGb / memTotalGb;
    }
}
