import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// the wallpaper picker: a grid of nights; picking one re-themes everything.
// Type to search: names, and words like blue, dark or live (most walls are
// called wallhaven-xxxxxx, so colour is what finds one); the chips do the same.
// Folders inside the wallpaper folders come first as cards: open one to see
// what's in it, Backspace (or the arrow) to go back up. A search looks in the
// open folder and every folder below it. A heart makes one a favourite (Ctrl+F), the eye
// keeps one from ever coming up again (Ctrl+H; it waits under Hidden).
Item {
    id: v
    required property var isle
    required property var screen
    readonly property bool shown: isle?.mode === "walls"
    property var walls: []
    property bool loading: false
    property string query: ""
    property string kind: "all"        // all | still | live | fav | hidden
    property string colour: ""         // one of hues' names, dark, light, or ""
    property string sort: "name"       // name | new | light
    property string folder: ""         // the open folder, relative ("" the top)
    readonly property bool filtering: query.trim() !== "" || kind !== "all" || colour !== ""
    function inside(w) { return folder === "" || w.dir === folder || w.dir.startsWith(folder + "/"); }

    readonly property int cols: Math.max(3, Math.floor((width - 24) / 236))
    readonly property int rows: 3
    readonly property real cellW: (width - 24) / cols
    readonly property real cellH: Math.round((cellW - 12) * 9 / 16) + 12

    implicitWidth: Math.min(screen.width - 120, 1240)
    implicitHeight: grid.y + rows * cellH + 14

    readonly property var hues: [
        { name: "red", hue: 0 }, { name: "orange", hue: 28 }, { name: "yellow", hue: 52 },
        { name: "green", hue: 120 }, { name: "cyan", hue: 185 }, { name: "blue", hue: 222 },
        { name: "purple", hue: 272 }, { name: "pink", hue: 320 }
    ]

    function words(w) {
        return (w.name + " " + w.colours.join(" ") + (w.video ? " live video" : " still picture")
            + (w.light < 0.36 ? " dark" : w.light > 0.62 ? " light bright" : "")).toLowerCase();
    }
    function fits(w, c) {
        return c === "dark" ? w.light < 0.36 : c === "light" ? w.light > 0.62 : w.colours.includes(c);
    }
    readonly property var items: {
        const terms = query.trim().toLowerCase().split(/\s+/).filter(t => t !== "");
        const found = walls.filter(w => (filtering ? inside(w) : w.dir === folder)
            && (kind === "hidden") === !!w.hidden
            && (kind === "all" || kind === "hidden" || (kind === "fav" ? !!w.fav : (kind === "live") === w.video))
            && (colour === "" || fits(w, colour))
            && terms.every(t => words(w).includes(t)));
        if (sort === "new") found.sort((a, b) => b.added - a.added);
        else if (sort === "light") found.sort((a, b) => a.light - b.light);
        return found;
    }
    // the folders right inside the open one, each with a few of its pictures
    readonly property var folders: {
        if (filtering) return [];
        const by = {};
        for (const w of walls) {
            if (!inside(w) || w.dir === folder) continue;
            const name = w.dir.slice(folder === "" ? 0 : folder.length + 1).split("/")[0];
            const f = by[name] ?? (by[name] = { isFolder: true, name: name, rel: folder === "" ? name : folder + "/" + name, count: 0, thumbs: [] });
            f.count++;
            if (f.thumbs.length < 4 && w.thumb) f.thumbs.push(w.thumb);
        }
        return Object.keys(by).sort((a, b) => a.toLowerCase() < b.toLowerCase() ? -1 : 1).map(k => by[k]);
    }
    readonly property var entries: folders.concat(items)
    function open(rel) { picked = ""; folder = rel; }
    function up() {
        if (folder === "") return;
        const was = folder;
        folder = folder.includes("/") ? folder.slice(0, folder.lastIndexOf("/")) : "";
        picked = was;               // back on the folder you came out of
    }
    // keep the same wallpaper selected while the filter narrows around it
    property string picked: ""
    // (a tick later: the grid takes its new model after this and starts over at 0)
    onEntriesChanged: Qt.callLater(reselect)
    function reselect() {
        const i = entries.findIndex(w => (w.isFolder ? w.rel : w.path) === picked);
        grid.currentIndex = i >= 0 ? i : 0;
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }
    onShownChanged: if (shown) {
        query = ""; kind = "all"; colour = "";
        if (walls.length === 0) loading = true;
        query_.running = true;
    }

    function key(e) {
        const n = grid.count;
        const step = d => {
            grid.currentIndex = Math.max(0, Math.min(n - 1, grid.currentIndex + d));
            reveal(grid.currentIndex);
            const e = entries[grid.currentIndex];
            picked = e ? (e.isFolder ? e.rel : e.path) : "";
        };
        if (e.key === Qt.Key_Left) { step(-1); return true; }
        if (e.key === Qt.Key_Right) { step(1); return true; }
        if (e.key === Qt.Key_Up) { step(-cols); return true; }
        if (e.key === Qt.Key_Down) { step(cols); return true; }
        if (e.key === Qt.Key_PageUp) { step(-cols * rows); return true; }
        if (e.key === Qt.Key_PageDown) { step(cols * rows); return true; }
        if (e.key === Qt.Key_Home && (e.modifiers & Qt.ControlModifier)) { step(-n); return true; }
        if (e.key === Qt.Key_End && (e.modifiers & Qt.ControlModifier)) { step(n); return true; }
        if (e.key === Qt.Key_Tab) { kind = ({ all: "still", still: "live", live: "fav", fav: "all", hidden: "all" })[kind]; return true; }
        if (e.key === Qt.Key_Backtab) { kind = ({ all: "fav", fav: "live", live: "still", still: "all", hidden: "all" })[kind]; return true; }
        const ctrl = e.modifiers & Qt.ControlModifier, here = entries[grid.currentIndex];
        if (ctrl && e.key === Qt.Key_F) { if (here && !here.isFolder) mark(here, "fav"); return true; }
        if (ctrl && e.key === Qt.Key_H) { if (here && !here.isFolder) mark(here, "hidden"); return true; }
        if (e.key === Qt.Key_R && (e.modifiers & Qt.ControlModifier)) { shuffle(); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (n > 0) choose(entries[grid.currentIndex]);
            return true;
        }
        if (e.key === Qt.Key_Backspace && query === "" && folder !== "") { up(); return true; }
        return false;
    }

    Process {
        id: query_
        command: ["yoru", "walls"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ws;
                try { ws = JSON.parse(this.text); } catch (e) { return; }
                v.walls = ws.map(w => Object.assign({ colours: [], light: 0.5, added: 0, dir: "" }, w));
                // open where the wallpaper you have on lives
                v.folder = v.walls.find(w => w.path === Theme.wallpaper)?.dir ?? "";
                v.picked = Theme.wallpaper;
                v.loading = false;
            }
        }
    }
    // the cards draw their own selection, so the grid has no highlight to follow
    // down the list: scroll to the one you're on, gliding there
    function reveal(i) {
        const from = grid.contentY;
        glide.stop();
        grid.positionViewAtIndex(i, GridView.Contain);
        const to = grid.contentY;
        if (to === from) return;
        grid.contentY = from;
        glide.to = to;
        glide.start();
    }
    function choose(e) { if (e.isFolder) open(e.rel); else apply(e); }
    // a favourite, or hidden: yoru keeps it in yoru.json; the grid shows it at once
    function mark(w, what) {
        Quickshell.execDetached(["yoru", "wall", what === "fav" ? "fav" : "hide", w.path]);
        walls = walls.map(x => x.path === w.path ? Object.assign({}, x, { [what]: !x[what] }) : x);
    }
    function apply(w) {
        picked = w.path;
        Quickshell.execDetached(["yoru", "wall", w.path]);
    }
    // a surprise from what's showing, so "blue" then shuffle stays blue
    function shuffle() {
        if (items.length) apply(items[Math.floor(Math.random() * items.length)]);
    }

    Row {
        x: v.folder !== "" ? 14 : 26; y: 14
        spacing: 6
        IconButton {
            visible: v.folder !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: "arrow_back"; size: 32
            onClicked: v.up()
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            text: v.folder === "" ? "Wallpapers" : v.folder.split("/").join("  ›  ")
            size: 18; weight: Font.DemiBold
        }
    }
    Txt {
        x: 26; y: 44
        readonly property int here: v.walls.filter(w => v.inside(w)).length
        text: v.loading ? "Making thumbnails…"
            : v.kind === "hidden" ? v.items.length + " hidden: they never come up on their own  ·  Ctrl+H brings one back"
            : v.filtering ? v.items.length + " of " + here + "  ·  Ctrl+R picks one of these"
            : v.folder !== "" ? here + " nights  ·  Backspace to go back"
            : v.items.length + " nights" + (v.folders.length ? " and " + v.folders.length + (v.folders.length === 1 ? " folder" : " folders") : "")
              + "  ·  type to search, Tab for live ones, Ctrl+F a favourite"
        size: 12; color: Theme.inkDim
    }
    Row {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 18 }
        spacing: 6
        Pill {
            icon: ({ name: "sort_by_alpha", new: "schedule", light: "contrast" })[v.sort]
            label: ({ name: "A–Z", new: "Newest", light: "Dark first" })[v.sort]
            onClicked: v.sort = ({ name: "new", new: "light", light: "name" })[v.sort]
        }
        IconButton { icon: "shuffle"; filled: true; onClicked: v.shuffle() }
    }

    // what was typed, like the launcher's field
    Rectangle {
        id: field
        x: 12; y: 70
        width: parent.width - 24; height: 44
        radius: Theme.r(22)
        color: Theme.surfaceMid
        Icon { id: glass; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 20; color: Theme.primary }
        Txt {
            id: typed
            anchors { left: glass.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: Math.min(implicitWidth, field.width - 70)
            text: v.query
            size: 15
            elide: Text.ElideLeft
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
            text: "A name, or a colour: blue, red, dark…"
            size: 15
            color: Theme.outline
        }
    }

    // the filters as chips: what kind, then a colour
    Row {
        id: chips
        x: 12; y: 124
        spacing: 6
        Repeater {
            model: [{ id: "all", icon: "photo_library", label: "All" }, { id: "still", icon: "image", label: "Pictures" },
                    { id: "live", icon: "play_circle", label: "Live" }, { id: "fav", icon: "favorite", label: "Favourites" },
                    { id: "hidden", icon: "visibility_off", label: "Hidden" }]
            Pill {
                required property var modelData
                height: 32
                icon: modelData.icon; label: modelData.label
                on: v.kind === modelData.id
                onClicked: v.kind = modelData.id
            }
        }
        Item { width: 10; height: 1 }
        Repeater {
            model: v.hues.concat([{ name: "dark" }, { name: "light" }])
            Rectangle {
                id: dot
                required property var modelData
                readonly property bool on: v.colour === modelData.name
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32; radius: Theme.r(on ? 11 : 16)
                color: "transparent"
                border.width: on ? 2 : 0
                border.color: Theme.ink
                Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: Theme.r(dot.on ? 7 : 11)
                    color: dot.modelData.hue !== undefined ? Qt.hsla(dot.modelData.hue / 360, 0.62, 0.6, 1)
                        : dot.modelData.name === "dark" ? "#16181d" : "#eef0f4"
                    border.width: 1
                    border.color: Theme.alpha(Theme.ink, 0.18)
                    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                }
                StateLayer { onClicked: v.colour = dot.on ? "" : dot.modelData.name }
            }
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: grid.top; topMargin: 60 }
        visible: !v.loading && grid.count === 0
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bedtime"; size: 26; color: Theme.outline }
        Txt {
            text: !v.walls.length ? "No wallpapers in wallpaper.dirs"
                : v.kind === "fav" && !v.walls.some(w => w.fav) ? "No favourites yet: a heart on one (Ctrl+F) brings it here"
                : v.kind === "hidden" && !v.walls.some(w => w.hidden) ? "Nothing hidden: the eye on one (Ctrl+H) keeps it from coming up"
                : "No wallpaper matches"
            size: 12; color: Theme.outline
        }
    }

    GridView {
        id: grid
        x: 12; y: 168
        width: parent.width - 24
        height: v.rows * v.cellH
        cellWidth: v.cellW
        cellHeight: v.cellH
        clip: true
        model: v.entries
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false
        NumberAnimation on contentY {
            id: glide
            running: false
            duration: Theme.normal
            easing.type: Easing.OutCubic
        }
        // only what's near the screen is made, however many walls there are
        cacheBuffer: v.cellH * 2
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool isFolder: !!modelData.isFolder
            readonly property bool current: !isFolder && modelData.path === Theme.wallpaper
            readonly property bool sel: GridView.isCurrentItem
            width: v.cellW; height: v.cellH
            ClippingRectangle {
                id: frame
                anchors.centerIn: parent
                width: parent.width - 12; height: parent.height - 12
                radius: Theme.r(18)
                scale: card.sel ? 1 : hover.containsMouse ? 0.97 : 0.94
                opacity: card.sel || hover.containsMouse ? 1 : 0.7
                color: Theme.surfaceHigh
                border.width: card.current ? 3 : card.sel ? 2 : 0
                border.color: card.current ? Theme.primary : Theme.ink
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                // a folder: up to four of its pictures, side by side
                Grid {
                    visible: card.isFolder
                    anchors.fill: parent
                    readonly property int n: card.isFolder ? card.modelData.thumbs.length : 0
                    columns: n > 1 ? 2 : 1
                    spacing: 2
                    Repeater {
                        model: card.isFolder ? card.modelData.thumbs : []
                        Image {
                            required property string modelData
                            required property int index
                            readonly property int n: parent.n
                            width: n > 1 ? (frame.width - 2) / 2 : frame.width
                            height: n > 2 ? (frame.height - 2) / 2 : frame.height
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(240, 135)
                            asynchronous: true
                        }
                    }
                }
                // its name on a band along the bottom, readable over any pictures
                Rectangle {
                    visible: card.isFolder
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 40
                    color: Theme.alpha(Theme.island, 0.88)
                    Row {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: 20; fill: 1; color: Theme.primary }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, frame.width - 110)
                            text: card.isFolder ? card.modelData.name : ""
                            size: 13; weight: Font.DemiBold
                        }
                    }
                    Txt {
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: card.isFolder ? card.modelData.count : ""
                        size: 12; color: Theme.inkDim
                    }
                }
                Image {
                    visible: !card.isFolder
                    anchors.fill: parent
                    source: !card.isFolder && card.modelData.thumb ? "file://" + card.modelData.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 180)
                    asynchronous: true
                }
                // the name, on the one you're on
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 34
                    visible: !card.isFolder && (card.sel || hover.containsMouse)
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Theme.alpha(Theme.island, 0.85) }
                    }
                    Txt {
                        // clear of the heart and the eye
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 7; rightMargin: 70 }
                        text: card.modelData.name
                        size: 11; weight: Font.Medium
                    }
                }
                Rectangle {
                    visible: !card.isFolder && !!card.modelData.video
                    anchors { left: parent.left; top: parent.top; margins: 8 }
                    width: 56; height: 22; radius: Theme.r(11)
                    color: Theme.alpha(Theme.island, 0.8)
                    Row {
                        anchors.centerIn: parent; spacing: 2
                        Icon { name: "play_arrow"; size: 14; fill: 1; color: Theme.ink }
                        Txt { text: "Live"; size: 10; weight: Font.DemiBold }
                    }
                }
                Rectangle {
                    visible: card.current
                    anchors { right: parent.right; top: parent.top; margins: 8 }
                    width: 24; height: 24; radius: Theme.r(12)
                    color: Theme.primary
                    Icon { anchors.centerIn: parent; name: "check"; size: 16; weight: 700; color: Theme.inkPrimary }
                }
                // a favourite wears a heart
                Rectangle {
                    visible: !card.isFolder && !!card.modelData.fav && !(card.sel || hover.containsMouse)
                    anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                    width: 24; height: 24; radius: Theme.r(12)
                    color: Theme.alpha(Theme.island, 0.8)
                    Icon { anchors.centerIn: parent; name: "favorite"; size: 15; fill: 1; color: Theme.primary }
                }
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { grid.currentIndex = card.index; v.choose(card.modelData); }
            }
            // on the one you're on: a heart, and never again
            Row {
                visible: !card.isFolder && (card.sel || hover.containsMouse)
                anchors { right: frame.right; bottom: frame.bottom; margins: 6 }
                spacing: 2
                IconButton {
                    size: 28; icon: "favorite"; active: !!card.modelData.fav
                    tone: card.modelData.fav ? Theme.primary : Theme.alpha(Theme.island, 0.8)
                    onClicked: v.mark(card.modelData, "fav")
                }
                IconButton {
                    size: 28; icon: card.modelData.hidden ? "visibility" : "visibility_off"
                    tone: Theme.alpha(Theme.island, 0.8)
                    onClicked: v.mark(card.modelData, "hidden")
                }
            }
        }
    }
    // how far down the list the grid is
    Rectangle {
        visible: grid.contentHeight > grid.height
        x: parent.width - 8; y: grid.y + grid.visibleArea.yPosition * grid.height
        width: 4; height: Math.max(24, grid.visibleArea.heightRatio * grid.height)
        radius: Theme.r(2)
        color: Theme.alpha(Theme.ink, 0.28)
    }
}
