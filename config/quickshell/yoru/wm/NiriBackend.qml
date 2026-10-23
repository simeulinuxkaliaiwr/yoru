import Quickshell
import Quickshell.Io
import QtQuick
import qs

// niri, through `niri msg`: its workspaces already count from 1 per output
Scope {
    id: b

    function focusWorkspace(index) { Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(index)]); }
    function quit() { Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]); }

    property var rawWs: []
    property var rawWins: []

    // put the answers together once all of them are in
    function build() {
        const byId = {};
        for (const w of rawWs) byId[w.id] = w;
        Wm.workspaces = rawWs.slice().sort((a, c) => a.output === c.output ? a.idx - c.idx : (a.output < c.output ? -1 : 1)).map(w => ({
            index: w.idx, output: w.output ?? "", visible: w.is_active,
            windows: rawWins.filter(x => x.workspace_id === w.id).length
        }));
        const ws = rawWins.map(x => {
            const w = byId[x.workspace_id];
            return {
                id: x.id, title: x.title ?? "", app_id: x.app_id ?? "",
                output: w?.output ?? "", workspace: w?.idx ?? 0,
                visible: !!w?.is_active, focused: x.is_focused,
                floating: x.is_floating, fullscreen: !!x.is_fullscreen,
                state: x.is_floating ? "floating" : "tiled"
            };
        });
        Wm.windows = ws;
        // newer niri stamps each window's last focus: the exact order, even for windows from before the shell
        const t = x => x.focus_timestamp ? x.focus_timestamp.secs * 1e9 + x.focus_timestamp.nanos : -1;
        if (rawWins.some(x => x.focus_timestamp)) Wm.mru = rawWins.slice().sort((a, c) => t(c) - t(a)).map(x => x.id);
        const f = ws.find(w => w.focused);
        if (f && Wm.mru[0] !== f.id) Wm.touch(f.id);
        Wm.focusedTitle = f ? f.title : "";
        Wm.focusedApp = f ? f.app_id : "";
        const fw = rawWs.find(w => w.is_focused);
        if (fw?.output) Wm.focusedOutput = fw.output;
    }

    property int pending: 0
    property real asked: 0
    function answered() { if (--pending === 0) build(); }
    function refresh() {
        // a query that never answered doesn't hold the next ones back for long
        if (pending > 0 && Date.now() - asked < 3000) return;
        pending = 2; asked = Date.now();
        wsQuery.running = true; winQuery.running = true;
    }

    Process {
        id: wsQuery
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector { onStreamFinished: { try { b.rawWs = JSON.parse(this.text); } catch (e) {} b.answered(); } }
    }
    Process {
        id: winQuery
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector { onStreamFinished: { try { b.rawWins = JSON.parse(this.text); } catch (e) {} b.answered(); } }
    }

    // events come in bursts; one query after the burst
    Timer { id: soon; interval: 30; onTriggered: b.refresh() }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: b.refresh() }
    Process {
        id: events
        running: true
        command: Tied.cmd(["niri", "msg", "-j", "event-stream"])
        stdout: SplitParser {
            onRead: line => {
                // focus changes name the window: keep the recency order exact
                const m = line.match(/^\{"WindowFocusChanged":\{"id":(\d+)/);
                if (m) Wm.touch(parseInt(m[1]));
                soon.restart();
            }
        }
        onExited: retry.start()
    }
    Timer { id: retry; interval: 2000; onTriggered: events.running = true }
}
