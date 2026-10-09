pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// aro, through aroctl: workspaces, the focused window, and a nudge on every change
Singleton {
    id: aro

    property var workspaces: []         // aroctl -j workspaces
    property var windows: []            // aroctl -j windows
    property string focusedTitle: ""
    property string focusedApp: ""
    property string focusedOutput: Quickshell.screens[0]?.name ?? ""
    // foreign-toplevel handles, for activate() and close(): the list only fills
    // in after first use, so it is bound here, at startup
    readonly property var toplevels: ToplevelManager.toplevels.values
    property var mru: []                // window ids, the most recently focused first
    function touch(id) {
        if (!id) return;
        mru = [id].concat(mru.filter(x => x !== id)).slice(0, 200);
    }

    function wsFor(output) { return workspaces.filter(w => w.output === output); }
    function current(output) {
        const w = workspaces.find(w => w.output === output && w.visible);
        return w ? w.index : 1;
    }
    // windows on the workspace shown on this output, scratchpad aside
    function busy(output) {
        return windows.some(w => w.output === output && w.visible && w.state !== "scratchpad" && !w.floating);
    }
    function fullscreen(output) { return windows.some(w => w.output === output && w.visible && w.fullscreen); }

    function dispatch(...args) { Quickshell.execDetached(["aroctl", "dispatch", ...args]); }

    Process {
        id: wsQuery
        command: ["aroctl", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: { try { aro.workspaces = JSON.parse(this.text); } catch (e) {} }
        }
    }
    Process {
        id: winQuery
        command: ["aroctl", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ws;
                try { ws = JSON.parse(this.text); } catch (e) { return; }
                aro.windows = ws;
                const f = ws.find(w => w.focused);
                if (f && !aro.mru.includes(f.id)) aro.touch(f.id);
                aro.focusedTitle = f ? f.title : "";
                aro.focusedApp = f ? f.app_id : "";
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
                    if (f) aro.focusedOutput = f.name;
                } catch (e) {}
            }
        }
    }
    function refresh() { wsQuery.running = true; winQuery.running = true; monQuery.running = true; }

    // events come in bursts; one query after the burst
    Timer { id: soon; interval: 30; onTriggered: aro.refresh() }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: aro.refresh() }
    Process {
        id: events
        running: true
        command: ["aroctl", "subscribe"]
        stdout: SplitParser {
            onRead: line => {
                // focus changes carry the title already: no need to wait for the query
                const m = line.match(/^focus (\d+) (\S*) ?(.*)$/);
                if (m) { aro.touch(parseInt(m[1])); aro.focusedApp = m[2]; aro.focusedTitle = m[3]; }
                soon.restart();
            }
        }
        onExited: retry.start()
    }
    Timer { id: retry; interval: 2000; onTriggered: events.running = true }
}
