pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// what should outlive a restart of the shell (yoru-watch restarts it whenever its files
// change, and it can crash): the night light, caffeine, do not disturb and the timers as
// they were. ~/.cache/yoru/state.json; each part reads its own back as it starts.
// Caffeine and do not disturb only last the boot they were turned on in: a new day
// shouldn't start with the screen never locking
Singleton {
    id: saved

    property var data: ({})
    readonly property string boot: bootId.text().trim()

    FileView { id: file; path: Theme.cacheDir + "/state.json"; blockLoading: true; printErrors: false }
    FileView { id: bootId; path: "/proc/sys/kernel/random/boot_id"; blockLoading: true; printErrors: false }
    // read the first time anyone asks, which is as the others start
    property bool loaded: false
    function load() {
        if (loaded) return;
        loaded = true;
        try { data = JSON.parse(file.text()) ?? {}; } catch (e) { data = {}; }
    }

    function get(key, fallback) { load(); return data[key] !== undefined ? data[key] : fallback; }
    function set(key, value) {
        load();
        const d = Object.assign({}, data);
        d[key] = value;
        data = d;
        writeSoon.restart();
    }
    // kept with the boot it was set in, and only given back in that one
    function getThisBoot(key, fallback) { load(); return data[key]?.boot === boot ? data[key].value : fallback; }
    function setThisBoot(key, value) { set(key, { value: value, boot: boot }); }
    Timer { id: writeSoon; interval: 300; onTriggered: file.setText(JSON.stringify(saved.data)) }
}
