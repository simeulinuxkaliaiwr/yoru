pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// starting a desktop entry. Quickshell's execute() ignores Terminal=true, so nvim,
// yazi or htop would start with no terminal and quit at once: those open in
// launcher.terminal, foot naming the window after the entry so the ring finds it open.
// Also what every launcher shares (the list, the ring, the phone): how often each app
// was opened, the matching, and an app's open windows
Singleton {
    id: apps

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    function entry(id) {
        const want = String(id).replace(/\.desktop$/, "");
        return entries.find(e => e.id === want) ?? entries.find(e => e.id.toLowerCase() === want.toLowerCase()) ?? null;
    }

    // how often each app was opened (~/.cache/yoru/launches.json): one copy for all of them,
    // so a launch from one isn't written over by another's older counts
    property var counts: ({})
    FileView {
        id: store
        path: Theme.cacheDir + "/launches.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { apps.counts = JSON.parse(text()); } catch (e) {} }
    }
    // the ones opened most, most first
    function most() {
        return entries.filter(e => (counts[e.id] ?? 0) > 0).sort((a, b) => counts[b.id] - counts[a.id]);
    }

    function run(e) {
        if (!e) return;
        if (!e.runInTerminal) { e.execute(); return; }
        // in home unless the entry says otherwise, not wherever the shell was started
        Quickshell.execDetached({ command: inTerminal(e.command, e.id), workingDirectory: e.workingDirectory || Quickshell.env("HOME") });
    }
    // run it, and count it
    function launch(e) {
        if (!e) return;
        count(e);
        run(e);
    }
    // going back to an open one counts too
    function count(e) {
        const c = Object.assign({}, counts);
        c[e.id] = (c[e.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
    }
    // a command in the terminal; other terminals than foot get the usual -e
    function inTerminal(cmd, id) {
        const t = Config.o.launcher.terminal || "foot";
        return t.split("/").pop() === "foot" ? [t].concat(id ? ["--app-id", id] : [], cmd) : [t, "-e"].concat(cmd);
    }

    // the matching: consecutive letters and word starts score highest
    function score(text, q) {
        text = (text ?? "").toLowerCase();
        if (text === "") return -1;
        if (text.startsWith(q)) return 100 - text.length * 0.1;
        const at = text.indexOf(q);
        if (at >= 0) return 70 - at;
        let ti = 0, s = 0, run = 0;
        for (const ch of q) {
            const found = text.indexOf(ch, ti);
            if (found < 0) return -1;
            run = found === ti ? run + 1 : 0;
            s += 2 + run * 3 + (found === 0 || " -_.".includes(text[found - 1]) ? 6 : 0);
            ti = found + 1;
        }
        return s / 2;
    }
    // apps for what was typed, best first: names, then what they are, their keywords, their ids
    function search(q, n) {
        q = q.trim().toLowerCase();
        const used = e => Math.log2(1 + (counts[e.id] ?? 0)) * 6;
        const out = [];
        for (const e of entries) {
            const s = Math.max(score(e.name, q), score(e.genericName, q) - 20,
                               score((e.keywords ?? []).join(" "), q) - 30, score(e.id, q) - 25);
            if (s > 0) out.push({ e: e, s: s + used(e) });
        }
        return out.sort((a, b) => b.s - a.s).slice(0, n).map(r => r.e);
    }

    // an app's windows: its app_id is the desktop id, its last part, or the WM class
    function windowsOf(e) {
        if (!e) return [];
        const ids = [e.id, e.startupClass ?? ""].filter(s => s).map(s => s.toLowerCase());
        const tail = ids.map(s => s.split(".").pop());
        return Wm.windows.filter(w => {
            const a = (w.app_id ?? "").toLowerCase();
            return a !== "" && w.state !== "scratchpad" && (ids.includes(a) || tail.includes(a) || tail.includes(a.split(".").pop()));
        });
    }
    // brings back the window of it used last; false when it has none open
    function raise(e) {
        const ws = windowsOf(e);
        if (ws.length === 0) return false;
        const w = ws.slice().sort((a, b) => {
            const ia = Wm.mru.indexOf(a.id), ib = Wm.mru.indexOf(b.id);
            return (ia < 0 ? 1e9 : ia) - (ib < 0 ? 1e9 : ib);
        })[0];
        const t = Wm.toplevels.find(t => t.appId === w.app_id && t.title === w.title)
               ?? Wm.toplevels.find(t => t.appId === w.app_id);
        if (t) t.activate();
        return true;
    }
}
