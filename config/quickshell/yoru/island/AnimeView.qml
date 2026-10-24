import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// anime pictures from image boards (`yoru booru`; end-4's anime sidebar had it first).
// Type tags to search: Tab takes the tag it suggests, Ctrl+←/→ another board. Enter (or a
// click) opens one large with its tags, and a click on a tag searches it. Ctrl+S saves it
// to anime.folder, Ctrl+B makes it the wallpaper (on trial, like the picker's Online tab),
// Ctrl+O opens its page, Ctrl+P pins the search under the field. Safe for work unless
// anime.nsfw (anime.blur keeps those blurred until the pointer's on one). Closing keeps what was found: it opens again where it was left.
Item {
    id: v
    required property var isle
    required property var screen
    readonly property bool shown: isle?.mode === "anime"
    readonly property var c: Config.o.anime
    property string query: ""

    implicitWidth: Math.min(screen.width - 120, 1240)
    implicitHeight: Math.min(screen.height - 60, 690)

    readonly property var boards: [
        { id: "danbooru", icon: "draw", label: "Danbooru" }, { id: "safebooru", icon: "shield", label: "Safebooru" },
        { id: "yandere", icon: "brush", label: "yande.re" }, { id: "konachan", icon: "landscape", label: "Konachan" }
    ]
    readonly property string board: boards.some(b => b.id === c.source) ? c.source : "danbooru"
    readonly property string boardName: boards.find(b => b.id === board)?.label ?? board
    readonly property string layout: ["masonry", "grid", "strip"].includes(c.layout) ? c.layout : "masonry"
    readonly property bool strip: layout === "strip"
    onLayoutChanged: {
        Qt.callLater(() => reveal(sel, true));
        if (strip) fetchBig();
    }

    // what was found: the posts, a page at a time, more as the end comes near
    property var found: []
    property int page: 0
    property bool more: false
    property string error: ""
    property string searched: ""            // the tags the posts are for
    property int sel: 0
    property bool viewing: false            // one picture large
    readonly property var here: found[sel] ?? null
    readonly property string asked: query.trim()

    // back after a while: what was found stays, the field starts empty and isn't a search yet
    property bool fresh: false
    onShownChanged: if (shown) {
        fresh = query !== "";
        query = "";
        note = "";
        if (!found.length && !search.running) look(1);
    }
    // another board or order from the settings while it's closed: looked up when it opens
    function again() {
        if (shown) { look(1); return; }
        found = []; page = 0; more = false; searched = ""; viewing = false;
        slots.clear();
    }
    onBoardChanged: again()
    readonly property string order: c.order
    onOrderChanged: again()
    onAskedChanged: {
        if (fresh) { fresh = false; return; }
        typing.restart();
    }
    Timer { id: typing; interval: 650; onTriggered: v.look(1) }

    // the newest search asked for: one still running finishes first, then this one runs
    property var wanted: []
    function look(n) {
        typing.stop();
        if (n === 1) error = "";
        wanted = ["yoru", "booru", "search", board].concat(asked.split(/\s+/).filter(w => w !== ""))
            .concat(["--page", String(n), "--order", order]);
        if (!search.running) search.ask();
    }
    function further() {
        if (more && !search.running && found.length && sel >= found.length - 12) look(page + 1);
    }
    Process {
        id: search
        property string ran: ""
        property string words: ""
        readonly property bool current: ran === v.wanted.join("\n")
        readonly property bool pageOne: ran.indexOf("\n--page\n1\n") >= 0
        readonly property bool first: running && pageOne
        function ask() {
            ran = v.wanted.join("\n");
            words = v.wanted.slice(4, v.wanted.indexOf("--page")).join(" ");
            command = v.wanted;
            running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (!search.current) return;
                let d;
                try { d = JSON.parse(this.text); } catch (e) { return; }
                if (d.page === 1) {
                    v.found = d.items;
                    v.sel = 0;
                    v.viewing = false;
                    v.searched = search.words;
                    slots.clear();
                    area.contentY = 0; area.contentX = 0;
                } else {
                    v.found = v.found.concat(d.items.filter(p => !v.found.some(x => x.id === p.id)));
                }
                v.page = d.page; v.more = d.more;
                while (slots.count < v.found.length) slots.append({ n: slots.count });
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "" || !search.current) return;
                v.error = this.text.trim().split("\n").pop().replace(/^yoru: /, "");
                if (search.pageOne) { v.found = []; v.more = false; v.page = 0; v.searched = search.words; slots.clear(); }
            }
        }
        onExited: Qt.callLater(() => { if (!search.current) search.ask(); })
    }
    // one delegate per post, kept as pages are added (a new array for a model would make them all again)
    ListModel { id: slots }

    // tags as you type the last word: Tab (or a click) takes one
    readonly property string stem: { const m = query.match(/([^\s,]+)$/); return m ? m[1] : ""; }
    property var hints: []
    onStemChanged: {
        if (stem.length < 2) { hints = []; hinting.stop(); return; }
        hinting.restart();
    }
    Timer {
        id: hinting; interval: 220
        onTriggered: {
            tags.want = ["yoru", "booru", "tags", v.board, v.stem];
            if (!tags.running) tags.ask();
        }
    }
    Process {
        id: tags
        property var want: []
        property string ran: ""
        function ask() { ran = want.join("\n"); command = want; running = true; }
        stdout: StdioCollector {
            onStreamFinished: {
                if (tags.ran !== tags.want.join("\n")) return;
                let d;
                try { d = JSON.parse(this.text); } catch (e) { return; }
                v.hints = v.stem.length >= 2 ? d.filter(t => t.name !== v.stem) : [];
            }
        }
        onExited: Qt.callLater(() => { if (tags.ran !== tags.want.join("\n")) tags.ask(); })
    }
    function take(name) {
        query = query.slice(0, query.length - stem.length) + name + " ";
        hints = [];
        look(1);
    }
    function searchTag(name) {
        viewing = false;
        query = name + " ";
        look(1);
    }
    readonly property bool pinned: asked !== "" && c.pinned.includes(asked)
    function pin() {
        if (asked === "") return;
        c.pinned = pinned ? c.pinned.filter(x => x !== asked) : c.pinned.concat([asked]);
        say(pinned ? "Pinned: it waits under the field" : "Unpinned");
    }
    function cycle(list, now, d) { return list[(list.indexOf(now) + d + list.length) % list.length]; }
    function nextBoard(d) { c.source = cycle(boards.map(b => b.id), board, d); }

    // a word on what just happened, for a few seconds
    property string note: ""
    function say(t) { note = t; noteTimer.restart(); }
    Timer { id: noteTimer; interval: 4500; onTriggered: v.note = "" }

    // where each one goes: columns (masonry: each its own shape, the shortest column next;
    // grid: even squares, row by row) or one row (strip)
    readonly property real gap: 8
    readonly property int cols: strip ? 1 : layout === "grid" ? Math.max(4, Math.floor(area.width / 190)) : Math.max(3, Math.floor(area.width / 230))
    readonly property real colW: (area.width - gap * (cols - 1)) / cols
    readonly property var plan: {
        const at = [];
        if (strip) {
            let x = 0;
            for (const p of found) {
                const w = Math.round(area.height * Math.max(0.45, Math.min(1.8, p.w && p.h ? p.w / p.h : 0.7)));
                at.push({ x: x, y: 0, w: w, h: area.height, col: 0 });
                x += w + gap;
            }
            return { at: at, extent: Math.max(0, x - gap) };
        }
        const tops = Array(cols).fill(0);
        for (const p of found) {
            let k = 0;
            for (let i = 1; i < cols; i++) if (tops[i] < tops[k] - 0.5) k = i;
            const h = Math.round(colW * (layout === "grid" ? 1 : Math.max(0.42, Math.min(2.4, p.w && p.h ? p.h / p.w : 1.3))));
            at.push({ x: k * (colW + gap), y: tops[k], w: colW, h: h, col: k });
            tops[k] += h + gap;
        }
        return { at: at, extent: Math.max(0, ...tops) };
    }

    // the arrows: across the columns to the one nearest in height, up and down a column
    function move(key) {
        const at = plan.at, n = at.length;
        if (!n) return;
        const i = Math.max(0, Math.min(n - 1, sel)), a = at[i];
        let j = i;
        if (strip || viewing) {
            if (key === Qt.Key_Left) j = i - 1;
            else if (key === Qt.Key_Right) j = i + 1;
        } else if (layout === "grid") {
            j = i + ({ [Qt.Key_Left]: -1, [Qt.Key_Right]: 1, [Qt.Key_Up]: -cols, [Qt.Key_Down]: cols })[key];
        } else if (key === Qt.Key_Up || key === Qt.Key_Down) {
            const d = key === Qt.Key_Up ? -1 : 1;
            for (let k = i + d; k >= 0 && k < n; k += d) if (at[k].col === a.col) { j = k; break; }
        } else {
            const col = a.col + (key === Qt.Key_Left ? -1 : 1), mid = a.y + a.h / 2;
            let best = Infinity;
            for (let k = 0; k < n; k++) {
                if (at[k].col !== col) continue;
                const off = Math.abs(at[k].y + at[k].h / 2 - mid);
                if (off < best) { best = off; j = k; }
            }
        }
        go(Math.max(0, Math.min(n - 1, j)));
    }
    function go(i) {
        sel = i;
        reveal(i);
        further();
    }
    // scroll to the one you're on, gliding there
    // (the strip keeps it in the middle; at once after a change of layout)
    function reveal(i, now) {
        const a = plan.at[i];
        if (!a) return;
        const pos = strip ? area.contentX : area.contentY, size = strip ? area.width : area.height;
        const from = strip ? a.x : a.y, len = strip ? a.w : a.h;
        let to = pos;
        if (strip) to = from + len / 2 - size / 2;
        else if (from < pos) to = from - (from > 0 ? gap : 0);
        else if (from + len > pos + size) to = from + len - size;
        to = Math.max(0, Math.min(to, (strip ? area.contentWidth : area.contentHeight) - size));
        if (to === pos) return;
        glide.stop();
        if (now) { area[strip ? "contentX" : "contentY"] = to; return; }
        glide.property = strip ? "contentX" : "contentY";
        glide.from = pos; glide.to = to;
        glide.start();
    }
    function open(i) {
        if (i < 0 || i >= found.length) return;
        sel = i;
        viewing = true;
        further();
    }

    // the picture large: the board's sample, fetched into yoru's cache (Danbooru turns
    // Qt's own loader away), the one after it fetched meanwhile
    property var bigs: ({})
    readonly property string bigFile: here ? bigs[here.sample] ?? "" : ""
    onHereChanged: if (viewing || strip) fetchBig()
    onViewingChanged: if (viewing) fetchBig()
    function fetchBig() {
        if (!here || bigs[here.sample] !== undefined) { ahead(); return; }
        big.want = here.sample;
        if (!big.running) big.ask();
    }
    function ahead() {
        const next = found[sel + 1];
        if (next && bigs[next.sample] === undefined) Quickshell.execDetached(["yoru", "booru", "cache", next.sample]);
    }
    Process {
        id: big
        property string want: ""
        property string ran: ""
        function ask() { ran = want; command = ["yoru", "booru", "cache", want]; running = true; }
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim();
                if (f !== "") v.bigs = Object.assign({}, v.bigs, { [big.ran]: f });
                v.ahead();
            }
        }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim() !== "") v.say("Couldn't fetch it: " + this.text.trim().split("\n").pop().replace(/^yoru: /, "")) }
        onExited: Qt.callLater(() => { if ((v.viewing || v.strip) && big.want !== big.ran && v.bigs[big.want] === undefined) big.ask(); })
    }

    // the one you're on: saved, made the wallpaper, its page opened, its link copied
    function save() {
        const p = here;
        if (!p || saver.running) return;
        if (p.have) { say("Already saved: " + p.have.split("/").pop()); return; }
        saver.id_ = p.id;
        saver.command = ["yoru", "booru", "save", p.source, p.id, p.full];
        saver.running = true;
    }
    Process {
        id: saver
        property string id_: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim();
                if (f === "") return;
                v.found = v.found.map(p => p.id === saver.id_ ? Object.assign({}, p, { have: f }) : p);
                v.say("Saved to " + f.replace(Quickshell.env("HOME"), "~"));
            }
        }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim() !== "") v.say("Couldn't save it: " + this.text.trim().split("\n").pop().replace(/^yoru: /, "")) }
    }
    function wallpaper() {
        const p = here;
        if (!p || waller.running) return;
        waller.command = ["yoru", "wall", "get", p.source, p.id];
        waller.running = true;
    }
    Process {
        id: waller
        stdout: StdioCollector {
            onStreamFinished: if (this.text.trim() !== "") v.say(Config.o.wallpaper.online.keep === "all" ? "Your wallpaper now, kept in the download folder"
                : "Your wallpaper now, on trial: Keep in the wallpaper picker's Online tab keeps it")
        }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim() !== "") v.say("Couldn't make it the wallpaper: " + this.text.trim().split("\n").pop().replace(/^yoru: /, "")) }
    }
    function openPage() {
        if (!here) return;
        Qt.openUrlExternally(here.post);
        isle.close();
    }
    function copyLink() {
        if (!here) return;
        Quickshell.execDetached(["wl-copy", here.post]);
        say("Link copied");
    }

    function key(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Escape && viewing) { viewing = false; reveal(sel); return true; }
        if (ctrl && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) { nextBoard(e.key === Qt.Key_Left ? -1 : 1); return true; }
        if (e.key === Qt.Key_Tab) { if (hints.length) take(hints[0].name); else nextBoard(1); return true; }
        if (e.key === Qt.Key_Backtab) { nextBoard(-1); return true; }
        if (ctrl && e.key === Qt.Key_S) { save(); return true; }
        if (ctrl && e.key === Qt.Key_B) { wallpaper(); return true; }
        if (ctrl && e.key === Qt.Key_O) { openPage(); return true; }
        if (ctrl && e.key === Qt.Key_C) { copyLink(); return true; }
        if (ctrl && e.key === Qt.Key_P) { pin(); return true; }
        if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(e.key)) { move(e.key); return true; }
        if (e.key === Qt.Key_PageDown || e.key === Qt.Key_PageUp) {
            const d = e.key === Qt.Key_PageDown ? 1 : -1;
            go(Math.max(0, Math.min(found.length - 1, sel + d * (strip ? 4 : cols * 3))));
            return true;
        }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (viewing) viewing = false;
            else open(sel);
            return true;
        }
        return false;
    }

    // the title, and what's going on
    Row {
        x: v.viewing ? 14 : 26; y: 14
        spacing: 6
        IconButton {
            visible: v.viewing
            anchors.verticalCenter: parent.verticalCenter
            icon: "arrow_back"; size: 32
            onClicked: v.viewing = false
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            text: v.searched !== "" ? v.searched.split(/\s+/).map(t => t.replace(/_/g, " ")).join(", ") : "Anime"
            size: 18; weight: Font.DemiBold
            width: Math.min(implicitWidth, v.width - 520)
        }
    }
    Txt {
        x: 26; y: 44
        width: v.width - 470
        readonly property string count: v.found.length + (v.more ? "+" : "")
        text: v.error !== "" ? v.error
            : v.note !== "" ? v.note
            : search.first && !v.found.length ? "Looking on " + v.boardName + "…"
            : !v.found.length ? "Nothing on " + v.boardName
            : v.viewing ? (v.sel + 1) + " of " + count + "  ·  ←/→ the next one, Ctrl+S saves, Ctrl+B wallpaper, Ctrl+O its page, Esc back"
            : count + (v.searched === "" ? " newest" : "") + " on " + v.boardName + (search.running ? "  ·  looking…" : "")
              + "  ·  type tags, Tab takes one, Enter opens, Ctrl+←/→ another board"
        size: 12; color: v.error !== "" ? Theme.danger : Theme.inkDim
    }
    Row {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 18 }
        spacing: 6
        Pill {
            icon: ({ new: "schedule", top: "trending_up", random: "casino" })[v.order] ?? "schedule"
            label: ({ new: "Newest", top: "Top", random: "Random" })[v.order] ?? "Newest"
            onClicked: v.c.order = v.cycle(["new", "top", "random"], v.order, 1)
        }
        Pill {
            icon: ({ masonry: "dashboard", grid: "grid_view", strip: "view_carousel" })[v.layout]
            label: ({ masonry: "Masonry", grid: "Grid", strip: "Strip" })[v.layout]
            onClicked: v.c.layout = v.cycle(["masonry", "grid", "strip"], v.layout, 1)
        }
        IconButton {
            icon: "push_pin"; active: v.pinned
            opacity: v.asked !== "" ? 1 : 0.35
            onClicked: v.pin()
        }
    }

    // what was typed, like the launcher's field
    Rectangle {
        id: field
        x: 12; y: 70
        width: parent.width - 24; height: 44
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Icon { id: glass; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "sell"; size: 20; color: Theme.primary }
        Txt {
            id: typed
            anchors { left: glass.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: Math.min(implicitWidth, field.width - 70)
            text: v.query
            size: 15
            elide: Text.ElideLeft
        }
        // the tag it would take, after what's typed
        Txt {
            anchors { left: typed.right; verticalCenter: parent.verticalCenter }
            visible: v.hints.length > 0 && v.hints[0].name.startsWith(v.stem)
            text: visible ? v.hints[0].name.slice(v.stem.length) : ""
            size: 15; color: Theme.outline
        }
        Rectangle {
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
            text: v.board === "danbooru" ? "Tags, like hatsune_miku or scenery (two at most here)"
                : v.board === "konachan" ? "Tags, like night sky or scenery: wallpaper-sized ones"
                : "Tags, like hatsune_miku, scenery or cat_ears"
            size: 15
            color: Theme.outline
        }
    }

    // the boards, then the tags it suggests (or your pinned searches)
    Item {
        x: 12; y: 124
        width: parent.width - 24; height: 32
        clip: true
        Row {
            spacing: 6
            Repeater {
                model: v.boards
                Pill {
                    required property var modelData
                    height: 32
                    icon: modelData.icon; label: modelData.label
                    on: v.board === modelData.id
                    onClicked: v.c.source = modelData.id
                }
            }
            Item { width: 10; height: 1 }
            Repeater {
                model: v.hints.length ? v.hints : v.c.pinned
                Pill {
                    required property var modelData
                    required property int index
                    readonly property bool hint: v.hints.length > 0
                    height: 32
                    icon: hint ? (index === 0 ? "keyboard_tab" : "sell") : "push_pin"
                    label: hint ? modelData.name.replace(/_/g, " ") + "  " + v.many(modelData.count) : modelData
                    on: !hint && modelData === v.asked
                    onClicked: {
                        if (hint) { v.take(modelData.name); return; }
                        v.query = modelData;
                        v.look(1);
                    }
                }
            }
        }
    }
    function many(n) { return n >= 1000000 ? (n / 1000000).toFixed(1) + "M" : n >= 1000 ? Math.round(n / 1000) + "k" : String(n); }

    // nothing yet, or nothing there
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: area.top; topMargin: 80 }
        visible: !v.found.length && !v.viewing
        spacing: 6
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: search.running ? "progress_activity" : v.error !== "" ? "cloud_off" : "image_search"
            size: 28; color: Theme.outline
            RotationAnimation on rotation { running: search.running; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
            onVisibleChanged: rotation = 0
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: search.running ? "Looking on " + v.boardName + "…"
                : v.error !== "" ? "Couldn't search: " + v.error
                : v.searched !== "" ? "Nothing on " + v.boardName + " for \"" + v.searched + "\": Tab takes a tag it knows"
                : "Nothing there"
            size: 12; color: Theme.outline
        }
    }

    Flickable {
        id: area
        x: 12; y: 168
        width: parent.width - 24; height: parent.height - y - 14
        contentWidth: v.strip ? v.plan.extent : width
        contentHeight: v.strip ? height : v.plan.extent
        flickableDirection: v.strip ? Flickable.HorizontalFlick : Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        opacity: v.viewing ? 0 : search.first ? 0.45 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        NumberAnimation { id: glide; target: area; duration: Theme.normal; easing.type: Easing.OutCubic }
        // the strip scrolls sideways with the wheel too
        WheelHandler {
            enabled: v.strip
            onWheel: e => {
                const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x;
                area.contentX = Math.max(0, Math.min(area.contentWidth - area.width, area.contentX - d));
            }
        }
        onContentYChanged: if (!v.strip && v.more && !search.running && contentY + height > contentHeight - height) v.look(v.page + 1)
        onContentXChanged: if (v.strip && v.more && !search.running && contentX + width > contentWidth - width) v.look(v.page + 1)

        Repeater {
            model: slots
            delegate: Item {
                id: card
                required property int index
                readonly property var post: v.found[index] ?? null
                readonly property var at: v.plan.at[index] ?? { x: 0, y: 0, w: 0, h: 0 }
                x: at.x; y: at.y; width: at.w; height: at.h
                // only what's near the screen holds its picture
                readonly property bool near: v.strip ? x + width > area.contentX - area.width && x < area.contentX + 2 * area.width
                                                     : y + height > area.contentY - area.height && y < area.contentY + 2 * area.height
                readonly property bool sel: v.sel === index
                // not unveiled by the arrows: only the pointer, or opening it, shows one
                readonly property bool veiled: !!post && post.nsfw && v.c.blur && !hover.containsMouse
                visible: near

                ClippingRectangle {
                    id: frame
                    anchors.fill: parent
                    radius: Theme.r(16)
                    color: Theme.surfaceHigh
                    border.width: card.sel ? 2 : 0
                    border.color: Theme.ink
                    scale: card.sel ? 1 : hover.containsMouse ? 0.985 : 0.965
                    opacity: card.sel || hover.containsMouse ? 1 : 0.84
                    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    Image {
                        id: pic
                        anchors.fill: parent
                        source: card.near && card.post?.thumb ? "file://" + card.post.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(Math.round(card.width), Math.round(card.height))
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                        layer.enabled: card.veiled
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 48; autoPaddingEnabled: false }
                    }
                    // in the strip the one you're on is big enough to want the picture itself
                    Image {
                        id: sharp
                        anchors.fill: parent
                        readonly property string file: v.strip && card.sel && card.post ? v.bigs[card.post.sample] ?? "" : ""
                        source: file !== "" ? "file://" + file : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(Math.round(card.width * 1.5), Math.round(card.height * 1.5))
                        asynchronous: true
                        visible: !card.veiled
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                    }
                    Icon {
                        visible: pic.status !== Image.Ready
                        anchors.centerIn: parent
                        name: card.post && !card.post.thumb ? "broken_image" : "image"; size: 26; color: Theme.outline
                    }
                    // its rating, when it isn't safe for work
                    Rectangle {
                        visible: !!card.post && card.post.nsfw
                        anchors { left: parent.left; top: parent.top; margins: 8 }
                        width: rated.implicitWidth + 16; height: 22; radius: Theme.r(11)
                        color: Theme.alpha(Theme.island, 0.82)
                        Txt { id: rated; anchors.centerIn: parent; text: card.post?.rating === "e" ? "Explicit" : "Questionable"; size: 10; weight: Font.DemiBold; color: Theme.danger }
                    }
                    // saved already
                    Rectangle {
                        visible: !!card.post?.have
                        anchors { right: parent.right; top: parent.top; margins: 8 }
                        width: 24; height: 24; radius: Theme.r(12)
                        color: Theme.alpha(Theme.island, 0.82)
                        Icon { anchors.centerIn: parent; name: "download_done"; size: 15; color: Theme.primary }
                    }
                    // who drew it, on the one you're on
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 34
                        visible: (card.sel || hover.containsMouse) && card.height > 90
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Theme.alpha(Theme.island, 0.88) }
                        }
                        Txt {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 7 }
                            text: card.post ? (card.post.artist.length ? card.post.artist[0].replace(/_/g, " ") + "  ·  " : "") + card.post.w + "×" + card.post.h : ""
                            size: 11; weight: Font.Medium
                        }
                    }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: v.open(card.index)
                }
            }
        }
    }
    // how far along the list is
    Rectangle {
        visible: !v.viewing && (v.strip ? area.contentWidth > area.width : area.contentHeight > area.height)
        x: v.strip ? area.x + area.visibleArea.xPosition * area.width : parent.width - 8
        y: v.strip ? parent.height - 8 : area.y + area.visibleArea.yPosition * area.height
        width: v.strip ? Math.max(24, area.visibleArea.widthRatio * area.width) : 4
        height: v.strip ? 4 : Math.max(24, area.visibleArea.heightRatio * area.height)
        radius: Theme.r(2)
        color: Theme.alpha(Theme.ink, 0.28)
    }

    // one picture large, its tags beside it
    Item {
        id: viewer
        x: 12; y: 168
        width: parent.width - 24; height: parent.height - y - 14
        opacity: v.viewing ? 1 : 0
        visible: opacity > 0.01
        scale: v.viewing ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        readonly property var p: v.here
        readonly property bool board: p && (p.source === "danbooru" || p.source === "safebooru")

        Item {
            id: stage
            width: parent.width - 316; height: parent.height
            readonly property real r: viewer.p && viewer.p.w && viewer.p.h ? viewer.p.w / viewer.p.h : 1
            readonly property real fw: Math.min(width, height * r)
            ClippingRectangle {
                anchors.centerIn: parent
                width: stage.fw; height: stage.fw / stage.r
                radius: Theme.r(20)
                color: Theme.surfaceHigh
                // the thumbnail at once, the picture over it once it's here
                Image {
                    anchors.fill: parent
                    source: v.viewing && viewer.p?.thumb ? "file://" + viewer.p.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 0.5; blurMax: 24; autoPaddingEnabled: false }
                }
                Image {
                    id: large
                    anchors.fill: parent
                    source: v.viewing && v.bigFile !== "" ? "file://" + v.bigFile : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                }
                Rectangle {
                    visible: large.status !== Image.Ready
                    anchors.centerIn: parent
                    width: 48; height: 48; radius: Theme.r(24)
                    color: Theme.alpha(Theme.island, 0.7)
                    Icon {
                        anchors.centerIn: parent
                        name: "progress_activity"; size: 26; color: Theme.primary
                        RotationAnimation on rotation { running: v.viewing && large.status !== Image.Ready; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                    }
                }
            }
            // a click either side: the one before or after
            MouseArea { width: parent.width / 2; height: parent.height; onClicked: v.move(Qt.Key_Left); cursorShape: Qt.PointingHandCursor }
            MouseArea { x: parent.width / 2; width: parent.width / 2; height: parent.height; onClicked: v.move(Qt.Key_Right); cursorShape: Qt.PointingHandCursor }
        }

        // what it is: who drew it, who's in it, from what, and its tags (a click searches one)
        Rectangle {
            x: parent.width - 300; width: 300; height: parent.height
            radius: Theme.r(20)
            color: Theme.surfaceMid
            Flickable {
                id: info
                x: 16; y: 16
                width: parent.width - 32; height: parent.height - 32 - acts.height - 12
                contentHeight: about.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: about
                    width: info.width
                    spacing: 10
                    Row {
                        spacing: 8
                        Txt { text: viewer.p ? (v.boards.find(b => b.id === viewer.p.source)?.label ?? viewer.p.source) + "  #" + viewer.p.id : ""; size: 13; weight: Font.DemiBold }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: ratedBig.implicitWidth + 14; height: 20; radius: Theme.r(10)
                            color: viewer.p?.nsfw ? Theme.alpha(Theme.danger, 0.2) : Theme.secondaryContainer
                            Txt {
                                id: ratedBig
                                anchors.centerIn: parent
                                text: !viewer.p ? "" : viewer.board ? ({ g: "General", s: "Sensitive", q: "Questionable", e: "Explicit" })[viewer.p.rating] ?? ""
                                                              : ({ s: "Safe", q: "Questionable", e: "Explicit" })[viewer.p.rating] ?? ""
                                size: 10; weight: Font.DemiBold
                                color: viewer.p?.nsfw ? Theme.danger : Theme.inkSecondaryContainer
                            }
                        }
                    }
                    Txt { text: viewer.p ? viewer.p.w + " × " + viewer.p.h : ""; size: 12; color: Theme.inkDim }
                    Repeater {
                        model: viewer.p ? [["Drawn by", viewer.p.artist], ["Who", viewer.p.characters], ["From", viewer.p.series], ["Tags", viewer.p.tags]]
                                          .filter(g => g[1].length) : []
                        Column {
                            required property var modelData
                            width: about.width
                            spacing: 6
                            Txt { text: modelData[0]; size: 11; weight: Font.DemiBold; color: Theme.outline }
                            Flow {
                                width: parent.width
                                spacing: 5
                                Repeater {
                                    model: modelData[1].slice(0, 60)
                                    Rectangle {
                                        id: tag
                                        required property string modelData
                                        readonly property bool lead: parent.parent.modelData[0] !== "Tags"
                                        width: Math.min(tagText.implicitWidth + 18, about.width); height: 26
                                        radius: Theme.r(13)
                                        color: lead ? Theme.secondaryContainer : Theme.alpha(Theme.ink, 0.06)
                                        Txt {
                                            id: tagText
                                            anchors.centerIn: parent
                                            width: Math.min(implicitWidth, about.width - 18)
                                            text: tag.modelData.replace(/_/g, " ")
                                            size: 11
                                            color: tag.lead ? Theme.inkSecondaryContainer : Theme.ink
                                        }
                                        StateLayer { onClicked: v.searchTag(tag.modelData) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // more tags below: they fade out rather than stop at a line
            Rectangle {
                x: info.x; y: info.y + info.height - 28
                width: info.width; height: 28
                visible: info.contentY + info.height < info.contentHeight - 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.surfaceMid, 0) }
                    GradientStop { position: 1; color: Theme.surfaceMid }
                }
            }
            Column {
                id: acts
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                spacing: 6
                Row {
                    spacing: 6
                    Pill {
                        width: (acts.width - 6) / 2
                        icon: viewer.p?.have ? "download_done" : saver.running ? "progress_activity" : "download"
                        label: viewer.p?.have ? "Saved" : "Save"
                        primary: !viewer.p?.have
                        on: !!viewer.p?.have
                        onClicked: v.save()
                    }
                    Pill {
                        width: (acts.width - 6) / 2
                        icon: waller.running ? "progress_activity" : "wallpaper"
                        label: "Wallpaper"
                        onClicked: v.wallpaper()
                    }
                }
                Row {
                    spacing: 6
                    Pill { width: (acts.width - 6) / 2; icon: "open_in_new"; label: "Its page"; onClicked: v.openPage() }
                    Pill { width: (acts.width - 6) / 2; icon: "link"; label: "Copy link"; onClicked: v.copyLink() }
                }
            }
        }
    }
}
