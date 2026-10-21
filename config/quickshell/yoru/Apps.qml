pragma Singleton

import Quickshell
import QtQuick

// starting a desktop entry. Quickshell's execute() ignores Terminal=true, so nvim,
// yazi or htop would start with no terminal and quit at once: those open in
// launcher.terminal, foot naming the window after the entry so the ring finds it open
Singleton {
    function run(e) {
        if (!e) return;
        if (!e.runInTerminal) { e.execute(); return; }
        // in home unless the entry says otherwise, not wherever the shell was started
        Quickshell.execDetached({ command: inTerminal(e.command, e.id), workingDirectory: e.workingDirectory || Quickshell.env("HOME") });
    }
    // a command in the terminal; other terminals than foot get the usual -e
    function inTerminal(cmd, id) {
        const t = Config.o.launcher.terminal || "foot";
        return t.split("/").pop() === "foot" ? [t].concat(id ? ["--app-id", id] : [], cmd) : [t, "-e"].concat(cmd);
    }
}
