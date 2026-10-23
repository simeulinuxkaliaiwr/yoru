import Quickshell
import Quickshell.Io
import QtQuick
import qs

// aro, through aroctl: its JSON is already the shape Wm wants
Scope {
    id: b

    function focusWorkspace(index) { Quickshell.execDetached(["aroctl", "dispatch", "workspace", String(index)]); }
    function quit() { Quickshell.execDetached(["aroctl", "dispatch", "quit"]); }

    Process {
        id: wsQuery
        command: ["aroctl", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: { try { Wm.workspaces = JSON.parse(this.text); } catch (e) {} }
        }
    }
    Process {
        id: winQuery
        command: ["aroctl", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ws;
                try { ws = JSON.parse(this.text); } catch (e) { return; }
                Wm.windows = ws;
                const f = ws.find(w => w.focused);
                if (f && !Wm.mru.includes(f.id)) Wm.touch(f.id);
                Wm.focusedTitle = f ? f.title : "";
                Wm.focusedApp = f ? f.app_id : "";
            }
        }
    }
    Process {
        id: monQuery
        command: ["aroctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const f = JSON.parse(this.text).find(m => m.focused);
                    if (f) Wm.focusedOutput = f.name;
                } catch (e) {}
            }
        }
    }
    function refresh() { wsQuery.running = true; winQuery.running = true; monQuery.running = true; }

    // events come in bursts; one query after the burst
    Timer { id: soon; interval: 30; onTriggered: b.refresh() }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: b.refresh() }
    Process {
        id: events
        running: true
        command: Tied.cmd(["aroctl", "subscribe"])
        stdout: SplitParser {
            onRead: line => {
                // focus changes carry the title already: no need to wait for the query
                const m = line.match(/^focus (\d+) (\S*) ?(.*)$/);
                if (m) { Wm.touch(parseInt(m[1])); Wm.focusedApp = m[2]; Wm.focusedTitle = m[3]; }
                soon.restart();
            }
        }
        onExited: retry.start()
    }
    Timer { id: retry; interval: 2000; onTriggered: events.running = true }
}
