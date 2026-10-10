import Quickshell
import Quickshell.Io
import QtQuick
import qs

// Hyprland, through hyprctl and its event socket. Its workspace ids are global,
// so they serve as the index; special workspaces count as the scratchpad.
Scope {
    id: b

    // 0.56 dispatches Lua (and a Lua config refuses the old words); older ones only know the words
    function dispatch(lua, ...old) {
        Quickshell.execDetached(["sh", "-c", 'hyprctl dispatch "$1" | grep -q "^ok" || { shift; hyprctl dispatch "$@"; }', "sh", lua, ...old]);
    }
    function focusWorkspace(index) { dispatch(`hl.dsp.focus({ workspace = ${index} })`, "workspace", String(index)); }
    function quit() { dispatch("hl.dsp.exit()", "exit"); }

    property var monitors: []
    property var rawWs: []
    property var rawClients: []

    // put the three answers together once all of them are in
    function build() {
        const shown = new Set();
        const outName = {};
        for (const m of monitors) {
            outName[m.id] = m.name;
            shown.add(m.activeWorkspace?.id);
            if (m.specialWorkspace?.id) shown.add(m.specialWorkspace.id);
            if (m.focused) Wm.focusedOutput = m.name;
        }
        Wm.workspaces = rawWs.filter(w => w.id > 0).sort((a, c) => a.id - c.id).map(w => ({
            index: w.id, output: w.monitor, visible: shown.has(w.id), windows: w.windows
        }));
        const ws = rawClients.filter(c => c.mapped !== false).map(c => ({
            id: parseInt(c.address, 16),
            title: c.title, app_id: c.class,
            output: outName[c.monitor] ?? "",
            workspace: c.workspace.id,
            visible: shown.has(c.workspace.id) && !c.hidden,
            focused: c.focusHistoryID === 0,
            floating: c.floating,
            fullscreen: !!c.fullscreen,
            state: c.workspace.id < 0 ? "scratchpad" : (c.floating ? "floating" : "tiled")
        }));
        Wm.windows = ws;
        Wm.mru = rawClients.slice().sort((a, c) => a.focusHistoryID - c.focusHistoryID).map(c => parseInt(c.address, 16));
        const f = ws.find(w => w.focused);
        Wm.focusedTitle = f ? f.title : "";
        Wm.focusedApp = f ? f.app_id : "";
    }

    property int pending: 0
    property real asked: 0
    function answered() { if (--pending === 0) build(); }
    function refresh() {
        // a query that never answered doesn't hold the next ones back for long
        if (pending > 0 && Date.now() - asked < 3000) return;
        pending = 3; asked = Date.now();
        monQuery.running = true; wsQuery.running = true; winQuery.running = true;
    }

    Process {
        id: monQuery
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector { onStreamFinished: { try { b.monitors = JSON.parse(this.text); } catch (e) {} b.answered(); } }
    }
    Process {
        id: wsQuery
        command: ["hyprctl", "-j", "workspaces"]
        stdout: StdioCollector { onStreamFinished: { try { b.rawWs = JSON.parse(this.text); } catch (e) {} b.answered(); } }
    }
    Process {
        id: winQuery
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: { try { b.rawClients = JSON.parse(this.text); } catch (e) {} b.answered(); } }
    }

    // events come in bursts; one query after the burst
    Timer { id: soon; interval: 30; onTriggered: b.refresh() }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: b.refresh() }
    Socket {
        id: events
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: line => {
                // focus changes carry the class and title: no need to wait for the query
                const m = line.match(/^activewindow>>([^,]*),(.*)$/);
                if (m) { Wm.focusedApp = m[1]; Wm.focusedTitle = m[2]; }
                soon.restart();
            }
        }
        onConnectedChanged: if (!connected) retry.start()
    }
    Timer { id: retry; interval: 2000; onTriggered: events.connected = true }
}
