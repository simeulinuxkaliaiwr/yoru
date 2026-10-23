pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your real phone, through KDE Connect (`yoru kdeconnect`): its name, battery and
// notifications, asked every half minute while something shows them (`users`: the yoru
// phone's control page); ringing it, pinging it, sending it the clipboard. Nothing while
// KDE Connect isn't running or no phone is in reach
Singleton {
    id: kc

    property int users: 0
    property var phones: []
    readonly property var device: phones[0] ?? null
    readonly property bool on: Config.o.phone.kdeconnect && users > 0

    Timer { interval: 30000; repeat: true; running: kc.on; triggeredOnStart: true; onTriggered: if (!ask.running) ask.running = true }
    onOnChanged: if (!on) phones = []
    Process {
        id: ask
        command: ["yoru", "kdeconnect"]
        stdout: StdioCollector { onStreamFinished: { try { kc.phones = JSON.parse(this.text) ?? []; } catch (e) { kc.phones = []; } } }
    }
    // ring, ping or clipboard; then a fresh look a moment later
    function act(what) {
        if (!device) return;
        Quickshell.execDetached(["yoru", "kdeconnect", what, device.id]);
        soon.restart();
    }
    Timer { id: soon; interval: 1500; onTriggered: if (kc.on && !ask.running) ask.running = true }
}
