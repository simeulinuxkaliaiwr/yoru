pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// the colour picker: hyprpicker, then the colour shown in the island and copied
Singleton {
    id: p
    signal picked(string hex)
    function pick() { proc.running = true; }
    Process {
        id: proc
        command: ["hyprpicker", "-f", "hex", "-a", "-q"]
        stdout: StdioCollector {
            onStreamFinished: { const h = this.text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(h)) p.picked(h); }
        }
    }
}
