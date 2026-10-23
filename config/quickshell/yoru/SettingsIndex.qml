pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "settings/pages.js" as Pages

// every setting by name, for finding one: the settings window's search and the launcher.
// Read from the pages themselves (each SetRow's label and hint, under its section's title),
// so it never falls behind them; only labels written out as text count. Read once someone
// may search (want()). open() shows one in the settings window, starting it if it isn't open
Singleton {
    id: ix

    property var rows: []               // [{ page, pageName, icon, section, label, hint }]
    property bool asked: false
    function want() { if (!asked) { asked = true; read.running = true; } }

    Process {
        id: read
        command: ["sh", "-c", 'for f in "$1"/settings/*Page.qml; do printf "\\n@@FILE %s\\n" "${f##*/}"; cat "$f"; done', "sh", Quickshell.shellDir]
        stdout: StdioCollector { onStreamFinished: ix.rows = ix.parse(this.text) }
    }

    function parse(text) {
        const out = [];
        const files = text.split("\n@@FILE ").slice(1);
        for (const chunk of files) {
            const nl = chunk.indexOf("\n");
            const file = chunk.slice(0, nl).trim(), body = chunk.slice(nl + 1);
            const id = file.replace(/Page\.qml$/, "");
            const page = Pages.list.find(p => p.id.toLowerCase() === id.toLowerCase());
            if (!page) continue;
            // sections and rows in the order they come
            const marks = [];
            const re = /\b(Section|SetRow)\s*\{/g;
            let m;
            while ((m = re.exec(body)) !== null) marks.push({ kind: m[1], at: m.index + m[0].length });
            let section = "";
            for (let i = 0; i < marks.length; i++) {
                const end = i + 1 < marks.length ? marks[i + 1].at : body.length;
                const piece = body.slice(marks[i].at, Math.min(end, marks[i].at + 600));
                const str = key => { const r = piece.match(new RegExp("\\b" + key + ':\\s*"((?:[^"\\\\]|\\\\.)*)"')); return r ? r[1] : ""; };
                if (marks[i].kind === "Section") { section = str("title"); continue; }
                const label = str("label");
                if (label === "") continue;
                out.push({ page: page.id, pageName: page.name, icon: page.icon, section: section, label: label, hint: str("hint") });
            }
        }
        return out;
    }

    // the best rows for what was typed (once want() has read them): whole words in the label count most
    function search(q, n) {
        q = q.trim().toLowerCase();
        if (q.length < 2) return [];
        const out = [];
        for (const r of rows) {
            const label = r.label.toLowerCase(), more = (r.section + " " + r.hint + " " + r.pageName).toLowerCase();
            let s = 0;
            if (label.startsWith(q)) s = 100;
            else if (new RegExp("\\b" + q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).test(label)) s = 80;
            else if (label.includes(q)) s = 60;
            else if (more.includes(q)) s = 30;
            if (s > 0) out.push({ r: r, s: s - label.length * 0.1 });
        }
        return out.sort((a, b) => b.s - a.s).slice(0, n).map(x => x.r);
    }

    // the settings window on that page, that row shining: told over IPC if one is open (found
    // by its command line and this HOME: `qs -p FILE ipc` doesn't find it), else started there
    function open(page, label) {
        Quickshell.execDetached(["sh", "-c", `
for p in $(pgrep -x qs); do
    case "$(tr '\\0' ' ' < /proc/$p/cmdline)" in *" -p "*settings.qml" ") ;; *) continue ;; esac
    grep -qzx "HOME=$HOME" /proc/$p/environ 2>/dev/null || continue
    qs ipc --pid "$p" call settings open "$2" "$3" >/dev/null 2>&1 && exit 0
done
YORU_SETTINGS_PAGE="$2" YORU_SETTINGS_FIND="$3" exec qs -n -p "$1"`,
            "sh", Quickshell.shellDir + "/settings.qml", page, label ?? ""]);
    }
}
