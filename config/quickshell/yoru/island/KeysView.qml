import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts
import "binds.js" as Binds

// every bind in the compositor's config, in words (mod+/). Type to search.
// Hyprland's and niri's binds are put into aro's form first (binds.js), so one reader does all three.
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "keys"
    property string query: ""
    property var binds: []              // [{ group, keys, what }]

    implicitWidth: 1020
    implicitHeight: Math.min(560, 70 + flick.contentHeight + 16)

    onShownChanged: if (shown) { query = ""; file.running = true; }

    // the main config and the files it pulls in (Hyprland's require/source =, niri's include);
    // the first line out names the file that was read
    property string where: ""
    Process {
        id: file
        command: ["sh", Quickshell.shellDir + "/island/binds.sh", Wm.name]
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const nl = this.text.indexOf("\n");
                v.where = (nl < 0 ? this.text : this.text.slice(0, nl)).replace(Quickshell.env("HOME"), "~");
                const body = nl < 0 ? "" : this.text.slice(nl + 1);
                v.binds = v.parse(Wm.name === "niri" ? Binds.fromNiri(body)
                    : Wm.name === "hyprland" ? (v.where.endsWith(".lua") ? Binds.fromHyprLua(body) : Binds.fromHyprConf(body))
                    : body);
            }
        }
    }

    function nice(combo) {
        return combo.split("+").map(k => ({ mod: "Super", shift: "Shift", ctrl: "Ctrl", alt: "Alt",
            apostrophe: "'", minus: "-", period: ".", slash: "/", bracketleft: "[", bracketright: "]",
            space: "Space", escape: "Esc", Print: "PrtSc", Tab: "Tab" })[k] ?? (k.length === 1 ? k.toUpperCase() : k)).join(" ");
    }

    // what a bind does, said plainly, and which group it belongs to
    function describe(action, arg) {
        const island = { launcher: "Launcher", clip: "Clipboard", control: "Control centre", media: "Player",
                         walls: "Wallpapers", power: "Power menu", windows: "Window picker", keys: "This cheatsheet", calendar: "Calendar",
                         projects: "Projects" };
        if (action === "spawn") {
            let m = arg.match(/island toggle (\w+)/);
            if (m) return ["yoru", island[m[1]] ?? m[1]];
            const spawns = [
                [/settings\.qml/, "yoru", "Settings"], [/yoru wall next/, "yoru", "Next wallpaper"], [/desktop toggle/, "yoru", "Edit the desktop"],
                [/yoru-lock|aro-lock/, "System", "Lock the screen"],
                [/yoru-shot full/, "Capture", "Screenshot"], [/yoru-shot area/, "Capture", "Screenshot an area"],
                [/record toggle/, "Capture", "Record the screen"], [/record area/, "Capture", "Record an area"],
                [/picker pick/, "Capture", "Pick a colour"], [/focus toggle/, "yoru", "Focus timer"],
                [/RaiseVolume|set-volume.*\+/, "Media keys", "Volume up"], [/set-volume.*-/, "Media keys", "Volume down"],
                [/set-mute @DEFAULT_AUDIO_SINK/, "Media keys", "Mute"], [/AUDIO_SOURCE/, "Media keys", "Mute the microphone"],
                [/brightnessctl.*\+/, "Media keys", "Brighter"], [/brightnessctl.*-/, "Media keys", "Dimmer"],
                [/play-pause/, "Media keys", "Play / pause"], [/playerctl next/, "Media keys", "Next track"],
                [/playerctl previous/, "Media keys", "Previous track"],
                [/^foot$/, "Apps", "Terminal"], [/^kehai-term/, "Apps", "Terminal (in the focused one's folder)"], [/^fuzzel/, "Apps", "fuzzel"],
            ];
            for (const [re, g, w] of spawns) if (re.test(arg)) return [g, w];
            // anything else by its program's name, not its path
            return ["Apps", arg.split(" ")[0].split("/").pop()];
        }
        const words = {
            close: "Close the window", float: "Float / tile", fullscreen: "Fullscreen", maximize: "Maximize",
            sticky: "Sticky on every workspace", overview: "Overview", ungroup: "Ungroup tabs", quit: "Log out",
            scratchpad: "Send to the scratchpad",
        };
        if (words[action]) return ["Windows", words[action]];
        const groups = { focus: "Windows", move: "Windows", resize: "Windows", move_workspace: "Workspaces", group: "Windows",
                         tab: "Windows", split: "Windows", layout: "Windows", width: "Windows", switch: "Windows",
                         workspace: "Workspaces", sendto: "Workspaces", scratchpad_show: "Windows", wallpapers: "yoru" };
        const say = { focus: "Focus", move: "Move", resize: "Resize", move_workspace: "Move workspace to the monitor",
                      group: "Group with the window", tab: "Tab", split: "Split", layout: "Layout", width: "Width",
                      switch: "Switch window", workspace: "Workspace", sendto: "Send to workspace",
                      scratchpad_show: "Show the scratchpad", wallpapers: "aro's wallpaper picker", show_hotkey_overlay: "niri's hotkey overlay" };
        return [groups[action] ?? "Other", ((say[action] ?? action) + " " + (arg ?? "")).trim()];
    }

    function parse(text) {
        const rows = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*bind\s*=\s*([^,]+),\s*([a-z_]+)\s*(?:,\s*(.*))?$/);
            if (!m) continue;
            const [group, what] = describe(m[2], (m[3] ?? "").trim());
            rows.push({ group: group, combo: m[1].trim(), what: what, action: m[2], arg: (m[3] ?? "").trim() });
        }
        // fold runs: mod+1..8 for workspaces, h/j/k/l and the arrows for directions
        const out = [], seen = new Set();
        for (const r of rows) {
            if (seen.has(r)) continue;
            const num = r.combo.match(/^(.*\+)(\d)$/);
            if (num && (r.action === "workspace" || r.action === "sendto")) {
                const same = rows.filter(x => x.action === r.action && new RegExp("^" + num[1].replace(/\+/g, "\\+") + "\\d$").test(x.combo));
                same.forEach(x => seen.add(x));
                const ns = same.map(x => x.combo.slice(-1));
                out.push({ group: r.group, keys: nice(num[1] + ns[0]) + "–" + ns[ns.length - 1], what: (r.action === "workspace" ? "Workspace " : "Send to workspace ") + ns[0] + "–" + ns[ns.length - 1] });
                continue;
            }
            const dir = r.arg.match(/^(left|right|up|down)$/);
            const base = r.combo.replace(/\+[^+]+$/, "+");
            const same = dir ? rows.filter(x => x.action === r.action && /^(left|right|up|down)$/.test(x.arg) && x.combo.startsWith(base)) : [];
            // only a full set of four folds into one row
            if (same.length === 4) {
                same.forEach(x => seen.add(x));
                const keys = same.map(x => x.combo.slice(base.length));
                const label = r.what.replace(/\s*(left|right|up|down)$/, "");
                out.push({ group: r.group, keys: nice(base.slice(0, -1)) + " " + keys.map(k => nice(k)).join(" "), what: label + " ← ↓ ↑ →" });
                continue;
            }
            seen.add(r);
            out.push({ group: r.group, keys: nice(r.combo), what: r.what });
        }
        return out;
    }

    readonly property var order: ["yoru", "Windows", "Workspaces", "Capture", "Apps", "Media keys", "System", "Other"]
    readonly property var groups: {
        const q = query.toLowerCase();
        const shownRows = binds.filter(b => q === "" || (b.keys + " " + b.what + " " + b.group).toLowerCase().includes(q));
        return order.map(g => ({ name: g, rows: shownRows.filter(b => b.group === g) })).filter(g => g.rows.length > 0);
    }

    Row {
        x: 24; y: 22
        spacing: 10
        Icon { name: "keyboard"; size: 22; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: v.query === "" ? "Keys" : v.query; size: 17; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: "from " + v.where + "  ·  type to search"; size: 12; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
    }

    Flickable {
        id: flick
        x: 18; y: 62
        width: parent.width - 36
        height: Math.min(contentHeight, 480)
        contentHeight: flow.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: flow
            width: flick.width
            spacing: 12
            Repeater {
                model: v.groups
                Rectangle {
                    required property var modelData
                    width: (flow.width - 24) / 3
                    height: col.implicitHeight + 24
                    radius: Theme.r(20)
                    color: Theme.surfaceMid
                    Column {
                        id: col
                        x: 14; y: 12
                        width: parent.width - 28
                        spacing: 4
                        Txt { text: parent.parent.modelData.name; size: 12; weight: Font.DemiBold; color: Theme.primary; bottomPadding: 2 }
                        Repeater {
                            model: parent.parent.modelData.rows
                            Item {
                                required property var modelData
                                width: col.width; height: 24
                                Txt {
                                    width: parent.width * 0.55
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.modelData.what; size: 12
                                }
                                Rectangle {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    width: Math.min(keyText.implicitWidth + 14, parent.width * 0.44); height: 22; radius: Theme.r(7)
                                    color: Theme.surfaceHighest
                                    Txt { id: keyText; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 10); text: parent.parent.modelData.keys; size: 10; font.family: Theme.mono; color: Theme.inkDim }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    WheelHandler { onWheel: e => flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - e.angleDelta.y)) }
    function key(e) {
        if (e.key === Qt.Key_Down || e.key === Qt.Key_PageDown) { flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY + 120); return true; }
        if (e.key === Qt.Key_Up || e.key === Qt.Key_PageUp) { flick.contentY = Math.max(0, flick.contentY - 120); return true; }
        return false;
    }
}
