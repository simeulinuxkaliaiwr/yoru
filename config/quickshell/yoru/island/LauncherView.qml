import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

// apps, fuzzy-matched and ranked by how often you open them; maths too, things yoru does
// (lock, restart, next wallpaper, …) and settings by name. An open app's Enter goes to it,
// Shift+Enter opens another; → shows an app's own actions (a private window), ← folds them.
// A first character picks something else: ":" emoji, "?" the web, ">" a command
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "launcher"
    property string query: ""
    property string answer: ""

    implicitWidth: 620
    implicitHeight: 64 + (list.count > 0 ? Math.min(list.count, 7) * 54 + 14 : 0) + (answer !== "" ? 58 : 0)

    onShownChanged: if (shown) { query = ""; list.currentIndex = 0; opened = ""; SettingsIndex.want(); }
    property string opened: ""          // the app whose own actions show under it

    // keys from the island's keyboard sheet; typing arrives as `query`
    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_J) || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) {
            list.incrementCurrentIndex(); return true;
        }
        if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_K) || e.key === Qt.Key_Backtab) {
            list.decrementCurrentIndex(); return true;
        }
        if (e.key === Qt.Key_Right) {
            const r = list.currentItem?.modelData;
            if (r?.kind !== "app" || (r.e.actions?.length ?? 0) === 0) return false;
            unfold(r.e.id);
            return true;
        }
        if (e.key === Qt.Key_Left && opened !== "") { unfold(""); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (answer !== "" && (list.count === 0 || query.trim().startsWith("="))) {
                Quickshell.execDetached(["wl-copy", answer]); isle.close();
            } else if (list.currentItem) launch(list.currentItem.modelData, e.modifiers & Qt.ShiftModifier);
            return true;
        }
        return false;
    }

    // an app's actions open under it, or fold back, keeping it picked
    function unfold(id) {
        const at = results.findIndex(x => x.kind === "app" && x.e.id === (id || opened));
        opened = opened === id ? "" : id;
        list.currentIndex = Math.max(0, at);
    }

    // a row: { kind: app|action|do|setting|emoji|web|run, name, sub, icon or glyph, e (the app), text }
    function launch(r, shift) {
        if (r.kind === "do") { act(r.d); return; }
        if (r.kind === "action") {
            r.a.execute();
        } else if (r.kind === "setting") {
            SettingsIndex.open(r.r.page, r.r.label);
        } else if (r.kind === "emoji") {
            Quickshell.execDetached(["wl-copy", r.glyph]);
        } else if (r.kind === "web") {
            Qt.openUrlExternally(r.text);
        } else if (r.kind === "run") {
            // Shift keeps it in your terminal, to see what it says: any terminal waits for a key
            // this way, where only some have a --hold
            const held = r.text + '; printf "\\n[%s] Enter closes this" "$?"; read _';
            Quickshell.execDetached(shift ? Apps.inTerminal(["sh", "-c", held], "") : ["sh", "-c", r.text]);
        } else if (!shift && Apps.raise(r.e)) {
            Apps.count(r.e);            // open already: go there
        } else {
            Apps.launch(r.e);
        }
        isle.close();
    }

    // what yoru does, by name. The power ones open the power menu on themselves (one Enter
    // more to go), so a slip never shuts the computer down; the rest wait for the island to
    // go, so a screenshot doesn't catch it
    readonly property var doings: [
        { icon: "lock", name: "Lock the screen", words: "lock screen away", run: () => Quickshell.execDetached(["yoru-lock"]) },
        { icon: "bedtime", name: "Sleep", words: "sleep suspend", power: 1 },
        { icon: "logout", name: "Log out", words: "log out logout exit quit session", power: 2 },
        { icon: "restart_alt", name: "Restart", words: "restart reboot", power: 3 },
        { icon: "power_settings_new", name: "Shut down", words: "shut down shutdown power off poweroff turn off", power: 4 },
        { icon: "wallpaper", name: "Next wallpaper", words: "next wallpaper change wallpaper another wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "next"]) },
        { icon: "casino", name: "A random wallpaper", words: "random wallpaper shuffle", run: () => Quickshell.execDetached(["yoru", "wall", "random"]) },
        { icon: "undo", name: "The wallpaper before", words: "previous wallpaper back undo last wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "back"]) },
        { icon: "favorite", name: "Love this wallpaper", words: "favourite favorite heart like love wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "fav"]) },
        { icon: "visibility_off", name: "Never this wallpaper again", words: "hide never again dislike skip ban wallpaper", run: () => Quickshell.execDetached(["yoru", "wall", "hide"]) },
        { icon: "imagesmode", name: "Wallpapers", words: "wallpapers picker choose wallpaper", island: "walls" },
        { icon: "edit", name: "Edit the desktop", words: "edit desktop widgets edit mode arrange", run: () => Desk.edit() },
        { icon: "screenshot_region", name: "Screenshot an area", words: "screenshot capture print screen area", run: () => Quickshell.execDetached(["yoru-shot", "area"]) },
        { icon: "screenshot_monitor", name: "Screenshot the screen", words: "screenshot capture print screen whole full", run: () => Quickshell.execDetached(["yoru-shot", "full"]) },
        { icon: "colorize", name: "Pick a colour", words: "colour color picker pick eyedropper hex", run: () => Picker.pick() },
        { icon: "screen_record", name: "Record the screen", words: "record screen recording video capture", run: () => Recorder.toggle("") },
        { icon: "timer", name: "Focus", words: "focus pomodoro timer work", run: () => Focus.toggle() },
        { icon: "coffee", name: "Caffeine", words: "caffeine awake keep awake no sleep", run: () => { Status.caffeine = !Status.caffeine; } },
        { icon: "nightlight", name: "Night light", words: "night light warm blue light", run: () => Status.toggleNight() },
        { icon: "notifications_off", name: "Do not disturb", words: "do not disturb dnd quiet silence notifications mute", run: () => Notifs.toggleDnd() },
        { icon: "graphic_eq", name: "Play or pause the music", words: "play pause music song media", run: () => Media.toggle() },
        { icon: "settings", name: "Settings", words: "settings preferences config configure", run: () => SettingsIndex.open("", "") },
    ]
    function act(d) {
        if (d.power) { isle.powerPick = d.power; isle.open("power", isle.output); return; }
        if (d.island) { isle.open(d.island, isle.output); return; }
        isle.close();
        later.fn = d.run;
        later.restart();
    }
    Timer { id: later; interval: 280; property var fn: null; onTriggered: { const f = fn; fn = null; if (f) f(); } }
    // a word of its name or its other words starting with what was typed; strong when the
    // name itself does (and it's long enough to mean it)
    function doRows(q) {
        const out = [];
        for (const d of doings) {
            const name = d.name.toLowerCase(), all = name + " " + d.words;
            const word = new RegExp("(^|\\s)" + q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
            if (!word.test(all)) continue;
            out.push({ kind: "do", d: d, icon: d.icon, name: d.name, strong: q.length >= 3 && word.test(name),
                       sub: d.power ? "Opens the power menu on it" : d.island ? "In the island" : "yoru" });
        }
        return out.slice(0, 3);
    }
    function setRow(r) {
        return { kind: "setting", r: r, icon: r.icon, name: r.label,
                 sub: "Settings  ›  " + r.pageName + (r.section && r.section !== r.pageName ? "  ›  " + r.section : "") };
    }

    // the other kinds of search
    readonly property string mode: {
        const c = query.replace(/^\s+/, "")[0];
        return c === ":" ? "emoji" : c === "?" ? "web" : c === ">" ? "run" : "apps";
    }
    readonly property string rest: query.replace(/^\s+/, "").slice(1).trim()
    // the same engines as the start page, and its choice
    readonly property var engines: ({
        google: ["Google", "https://www.google.com/search?q="],
        duckduckgo: ["DuckDuckGo", "https://duckduckgo.com/?q="],
        youtube: ["YouTube", "https://www.youtube.com/results?search_query="],
        github: ["GitHub", "https://github.com/search?q="],
        wikipedia: ["Wikipedia", "https://en.wikipedia.org/w/index.php?search="]
    })
    function webRow(text) {
        const en = engines[Config.o.start.engine] ?? engines.google;
        return { kind: "web", icon: "travel_explore", name: text, sub: "Search " + en[0], text: en[1] + encodeURIComponent(text) };
    }
    // emoji names, read the first time they're asked for
    property var emoji: []
    FileView {
        path: v.mode === "emoji" || v.emoji.length ? Quickshell.shellDir + "/island/emoji.json" : ""
        printErrors: false
        onLoaded: { try { v.emoji = JSON.parse(text()); } catch (e) {} }
    }

    readonly property var apps: Apps.entries
    function appRow(e) {
        const open = Apps.windowsOf(e).length > 0;
        return { kind: "app", e: e, name: e.name, image: e.icon, open: open,
                 sub: (open ? "Open  ·  " : "") + (e.genericName || e.comment || "") };
    }
    // an app's row, with its own actions under it when they're open
    function withActions(e) {
        const r = [appRow(e)];
        if (e.id === opened)
            for (const a of e.actions ?? [])
                r.push({ kind: "action", a: a, e: e, name: a.name, sub: e.name, image: a.icon || e.icon });
        return r;
    }
    readonly property var results: {
        if (mode === "emoji") {
            const q = rest.toLowerCase();
            if (q === "") return emoji.slice(0, 30).map(x => ({ kind: "emoji", glyph: x[0], name: x[1], sub: "Enter copies it" }));
            const out = [];
            for (const x of emoji) {
                // whole words first: "cat" before "scatter"
                const at = x[1].indexOf(q);
                if (at < 0) continue;
                const word = at === 0 || x[1][at - 1] === " ";
                out.push({ x: x, s: (word ? 100 : 50) - at - x[1].length * 0.2 });
            }
            return out.sort((a, b) => b.s - a.s).slice(0, 40)
                      .map(r => ({ kind: "emoji", glyph: r.x[0], name: r.x[1], sub: "Enter copies it" }));
        }
        if (mode === "web") return rest === "" ? [] : [webRow(rest)];
        if (mode === "run")
            return rest === "" ? [] : [{ kind: "run", icon: "terminal", name: rest, sub: "Enter runs it  ·  Shift+Enter in a terminal", text: rest }];

        const q = query.trim().toLowerCase();
        const used = e => Math.log2(1 + (Apps.counts[e.id] ?? 0)) * 6;
        if (q === "")
            return [].concat(...apps.slice().sort((a, b) => used(b) - used(a) || a.name.localeCompare(b.name)).slice(0, 7).map(withActions));
        // in tiers: apps whose name starts so, things to do named so, apps with it anywhere,
        // settings named so, apps that only match letter by letter, then the rest
        const found = Apps.search(q, 30);
        const has = e => (e.name + " " + (e.genericName ?? "") + " " + (e.keywords ?? []).join(" ") + " " + e.id).toLowerCase().includes(q);
        const starts = found.filter(e => e.name.toLowerCase().startsWith(q));
        const within = found.filter(e => !starts.includes(e) && has(e));
        const loose = found.filter(e => !starts.includes(e) && !within.includes(e));
        const rows = list => [].concat(...list.map(withActions));
        const dos = doRows(q);
        const sets = q.length >= 3 ? SettingsIndex.search(q, 3) : [];
        const named = r => new RegExp("(^|\\s)" + q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).test(r.label.toLowerCase());
        const out = rows(starts).concat(dos.filter(d => d.strong), rows(within), sets.filter(named).map(setRow), rows(loose),
                                        dos.filter(d => !d.strong), sets.filter(r => !named(r)).map(setRow));
        // nothing by that name: offer the web instead
        return out.length || answer !== "" ? out : [webRow(query.trim())];
    }

    // maths, through qalc
    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: {
                const r = this.text.trim();
                v.answer = r !== "" && r !== v.query.trim() && !/error|warning/i.test(r) ? r : "";
            }
        }
    }
    Timer {
        id: calcSoon; interval: 120
        onTriggered: {
            const q = v.query.trim().replace(/^=/, "");
            if (v.mode === "apps" && /[0-9]/.test(q) && /[-+*/^%()]|\b(sqrt|sin|cos|to|in)\b/.test(q)) {
                calc.command = ["qalc", "-t", "-e", q];
                calc.running = true;
            } else v.answer = "";
        }
    }
    onQueryChanged: { calcSoon.restart(); list.currentIndex = 0; }

    // the search field: shows what the island's keyboard sheet typed
    Rectangle {
        id: field
        x: 12; y: 12
        width: parent.width - 24; height: 44
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Icon {
            id: glass; x: 14; anchors.verticalCenter: parent.verticalCenter; size: 20; color: Theme.primary
            name: ({ emoji: "mood", web: "travel_explore", run: "terminal", apps: "search" })[v.mode]
        }
        Txt {
            id: typed
            anchors { left: glass.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: Math.min(implicitWidth, field.width - 70)
            text: v.query
            size: 15
            elide: Text.ElideLeft
        }
        Rectangle {
            id: caret
            anchors { left: typed.right; leftMargin: 1; verticalCenter: parent.verticalCenter }
            width: 2; height: 20; radius: Theme.r(1)
            color: Theme.primary
            visible: v.shown
            SequentialAnimation on opacity {
                running: v.shown; loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 0 }
                PauseAnimation { duration: 530 }
                NumberAnimation { to: 0; duration: 0 }
                PauseAnimation { duration: 530 }
            }
        }
        Txt {
            anchors { left: glass.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
            visible: v.query === ""
            text: "Apps and maths  ·  :emoji  ?web  >command"
            size: 15
            color: Theme.outline
        }
    }

    // the answer, when the query is a sum
    Rectangle {
        id: answerRow
        visible: v.answer !== ""
        x: 12; y: field.y + field.height + 8
        width: parent.width - 24; height: 50
        radius: Theme.r(18)
        color: Theme.tertiaryContainer
        Icon { id: eq; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "calculate"; size: 22; fill: 1; color: Theme.inkTertiaryContainer }
        Txt {
            anchors { left: eq.right; leftMargin: 12; right: hint.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: v.answer; size: 17; weight: Font.DemiBold; color: Theme.inkTertiaryContainer
            font.family: Theme.mono
        }
        Txt { id: hint; anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
              text: "click to copy"; size: 11; color: Theme.inkTertiaryContainer; opacity: 0.7 }
        StateLayer { tint: Theme.inkTertiaryContainer; onClicked: { Quickshell.execDetached(["wl-copy", v.answer]); v.isle.close(); } }
    }

    // results
    ListView {
        id: list
        x: 12
        y: (answerRow.visible ? answerRow.y + answerRow.height : field.y + field.height) + 8
        width: parent.width - 24
        height: Math.min(count, 7) * 54
        clip: true
        model: v.results
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.normal
        highlightMoveVelocity: -1
        highlight: Rectangle {
            radius: Theme.r(18)
            color: Theme.secondaryContainer
        }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: 54
            readonly property string kind: modelData.kind
            readonly property bool sub: kind === "action"        // under its app
            Item {
                id: ico
                x: row.sub ? 30 : 12
                anchors.verticalCenter: parent.verticalCenter
                width: row.sub ? 24 : 32; height: width
                Image {
                    anchors.fill: parent
                    visible: row.kind === "app" || row.kind === "action"
                    sourceSize: Qt.size(64, 64)
                    source: visible ? Quickshell.iconPath(row.modelData.image, "application-x-executable") : ""
                    asynchronous: true
                }
                // open already: a dot, as a dock has
                Rectangle {
                    visible: row.modelData.open === true
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 3 }
                    width: 5; height: 5; radius: 2.5
                    color: Theme.primary
                }
                Text {
                    anchors.centerIn: parent
                    visible: row.modelData.kind === "emoji"
                    text: row.modelData.glyph ?? ""
                    font.family: "Noto Color Emoji"
                    font.pixelSize: 26
                }
                Rectangle {
                    anchors.fill: parent
                    visible: ["web", "run", "do", "setting"].includes(row.kind)
                    radius: Theme.r(12)
                    color: row.kind === "do" ? Theme.tertiaryContainer : row.kind === "setting" ? Theme.secondaryContainer : Theme.primaryContainer
                    Icon {
                        anchors.centerIn: parent; name: row.modelData.icon ?? ""; size: 20
                        color: row.kind === "do" ? Theme.inkTertiaryContainer : row.kind === "setting" ? Theme.inkSecondaryContainer : Theme.inkPrimaryContainer
                    }
                }
            }
            Column {
                anchors { left: ico.right; leftMargin: 14; right: more.visible ? more.left : parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                Txt {
                    width: parent.width; text: row.modelData.name; size: 14; weight: Font.Medium
                    color: row.ListView.isCurrentItem ? Theme.inkSecondaryContainer : Theme.ink
                    font.family: row.modelData.kind === "run" ? Theme.mono : Theme.sans
                }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.sub
                    size: 11
                    color: Theme.inkDim
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: v.launch(row.modelData, false)
            }
            // an app's own actions: the arrow opens them under it
            IconButton {
                id: more
                visible: row.kind === "app" && (row.modelData.e.actions?.length ?? 0) > 0
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                size: 32
                icon: v.opened === row.modelData.e?.id ? "expand_less" : "chevron_right"
                inkColour: row.ListView.isCurrentItem ? Theme.inkSecondaryContainer : Theme.inkDim
                onClicked: { list.currentIndex = row.index; v.unfold(row.modelData.e.id); }
            }
        }
    }
}
