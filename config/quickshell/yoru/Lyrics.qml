pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// synced lyrics for what's playing (`yoru lyrics`, from lrclib.net, cached).
// Fetched only while a lyrics widget is on the desktop: they count themselves in `users`
Singleton {
    id: ly
    property int users: 0
    property var lines: []              // [[seconds, line], …]
    property string status: ""          // "", "loading", "none" or "ok"
    property int tries: 0
    readonly property string song: Media.title + "\n" + Media.artist
    // the line being sung: a little early, so it's there as it starts
    readonly property int index: {
        const p = Media.position + 0.35;
        let i = -1;
        for (let j = 0; j < lines.length && lines[j][0] <= p; j++) i = j;
        return i;
    }
    readonly property string line: index >= 0 ? lines[index][1] : ""

    onSongChanged: { lines = []; status = ""; tries = 0; again.stop(); wait.restart(); }
    onUsersChanged: if (users > 0 && status === "") wait.restart()
    // a moment's grace: players change the title and artist one after the other
    Timer { id: wait; interval: 700; onTriggered: ly.load() }
    // lrclib is often busy: `yoru lyrics` says null then, and it's worth asking again
    Timer { id: again; interval: 20000; onTriggered: ly.load() }

    function load() {
        if (users <= 0 || Media.title === "") return;
        status = "loading";
        proc.command = ["yoru", "lyrics", Media.title, Media.artist, String(Math.round(Media.length))];
        proc.running = true;
    }
    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                let d = [];
                try { d = JSON.parse(text); } catch (e) {}
                if (d === null && ++ly.tries < 4) { again.restart(); return; }
                ly.lines = d ?? [];
                ly.status = ly.lines.length ? "ok" : "none";
            }
        }
    }
}
