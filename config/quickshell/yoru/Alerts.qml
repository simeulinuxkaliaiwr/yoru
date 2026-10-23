pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// what's worth interrupting for, as island toasts: the battery running low
// while it isn't charging (20, 10 and 5%, each once a discharge), and memory
// nearly full (90% for 15s, with what is using the most; once, until it has
// eased below 80%); battery saver starting, and a Bluetooth device connecting (with its
// battery). `qs -c yoru ipc call alerts preview battery|memory|saver` shows one now.
Singleton {
    id: al

    signal raised(var toast)

    // battery
    property int warned: 100            // the lowest step warned of this discharge
    readonly property int pct: Math.round(Status.charge * 100)
    onPctChanged: battery()
    Connections {
        target: Status
        function onChargingChanged() { al.battery(); }
        function onHasBatteryChanged() { al.battery(); }
    }
    function battery() {
        if (!Status.hasBattery) return;
        if (Status.charging) { warned = 100; return; }
        for (const step of [5, 10, 20]) {
            if (pct <= step && warned > step) {
                warned = step;
                batteryToast(pct);
                return;
            }
        }
    }
    function batteryToast(p) {
        raised({
            icon: p <= 10 ? "battery_alert" : "battery_2_bar", app: "Battery",
            title: p + "% left",
            body: p <= 5 ? "Plug in now" : p <= 10 ? "Plug in soon" : "Time to find the charger"
        });
    }

    // memory
    property bool memWarned: false
    property int highFor: 0             // seconds above 90%
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    Timer {
        interval: 5000; repeat: true; running: true
        onTriggered: { meminfo.reload(); al.memory(); }
    }
    function memory() {
        let total = 0, avail = 0;
        for (const l of meminfo.text().split("\n")) {
            if (l.startsWith("MemTotal:")) total = parseInt(l.split(/\s+/)[1]);
            else if (l.startsWith("MemAvailable:")) avail = parseInt(l.split(/\s+/)[1]);
        }
        if (!total) return;
        const used = 1 - avail / total;
        if (used >= 0.9) {
            highFor += 5;
            if (!memWarned && highFor >= 15) { memWarned = true; hog.running = true; }
        } else {
            highFor = 0;
            if (used < 0.8) memWarned = false;      // eased off: it may warn again
        }
    }
    // what uses the most, its processes added up by name (Firefox is many)
    Process {
        id: hog
        command: ["ps", "-eo", "rss=,comm="]
        stdout: StdioCollector {
            onStreamFinished: {
                const by = {};
                for (const l of this.text.split("\n")) {
                    const m = l.trim().match(/^(\d+)\s+(.+)$/);
                    if (m) by[m[2]] = (by[m[2]] ?? 0) + parseInt(m[1]);
                }
                const top = Object.keys(by).sort((a, b) => by[b] - by[a])[0];
                al.raised({
                    icon: "memory", app: "Memory", title: "Memory is nearly full",
                    body: top ? top + " is using " + (by[top] / 1048576).toFixed(1) + " GB" : ""
                });
            }
        }
    }

    // battery saver starting: once each time it does
    readonly property bool saving: Status.saving
    onSavingChanged: if (saving && settled) raised({
        icon: "energy_savings_leaf", app: "Battery saver",
        title: "Saving the battery", body: "The sky, the video wallpaper and the visualizer rest until you plug in"
    })
    // not for what's already so as the shell starts
    property bool settled: false
    Timer { interval: 4000; running: true; onTriggered: al.settled = true }

    // a Bluetooth device coming in: its name, and its battery once it says (a moment after)
    property var known: []              // addresses connected last time we looked
    readonly property var connected: Status.btConnected
    onConnectedChanged: {
        const now = connected.map(d => d.address);
        const fresh = connected.filter(d => !known.includes(d.address));
        known = now;
        if (!settled || fresh.length === 0) return;
        btSoon.devices = fresh;
        btSoon.restart();
    }
    Timer {
        id: btSoon
        interval: 2500
        property var devices: []
        onTriggered: {
            for (const d of devices) if (d.connected) al.raised({
                icon: /audio-head|headset|headphone/.test(d.icon ?? "") ? "headphones" : /audio/.test(d.icon ?? "") ? "speaker" : "bluetooth_connected",
                app: "Bluetooth", title: d.name + " is connected",
                body: d.batteryAvailable ? "Battery " + Math.round(d.battery * 100) + "%" : ""
            });
        }
    }

    function preview(kind) {
        if (kind === "memory") hog.running = true;
        else if (kind === "saver") raised({ icon: "energy_savings_leaf", app: "Battery saver", title: "Saving the battery",
                                           body: "The sky, the video wallpaper and the visualizer rest until you plug in" });
        else batteryToast(20);          // what the first warning looks like
    }
}
