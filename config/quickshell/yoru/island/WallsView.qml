import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// the wallpaper picker: a grid of nights; picking one re-themes everything.
// Type to search: names, and words like blue, dark or live (most walls are
// called wallhaven-xxxxxx, so colour is what finds one); the chips do the same.
Item {
    id: v
    required property var isle
    required property var screen
    readonly property bool shown: isle?.mode === "walls"
    property var walls: []
    property bool loading: false
    property string query: ""
    property string kind: "all"        // all | still | live
    property string colour: ""         // one of hues' names, dark, light, or ""
    property string sort: "name"       // name | new | light

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
        const found = walls.filter(w => (kind === "all" || (kind === "live") === w.video)
            && (colour === "" || fits(w, colour))
            && terms.every(t => words(w).includes(t)));
        if (sort === "new") found.sort((a, b) => b.added - a.added);
        else if (sort === "light") found.sort((a, b) => a.light - b.light);
        return found;
    }
    // keep the same wallpaper selected while the filter narrows around it
    property string picked: ""
    // (a tick later: the grid takes its new model after this and starts over at 0)
    onItemsChanged: Qt.callLater(reselect)
    function reselect() {
        const i = items.findIndex(w => w.path === picked);
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
        const step = d => { grid.currentIndex = Math.max(0, Math.min(n - 1, grid.currentIndex + d)); picked = items[grid.currentIndex]?.path ?? ""; };
        if (e.key === Qt.Key_Left) { step(-1); return true; }
        if (e.key === Qt.Key_Right) { step(1); return true; }
        if (e.key === Qt.Key_Up) { step(-cols); return true; }
        if (e.key === Qt.Key_Down) { step(cols); return true; }
        if (e.key === Qt.Key_PageUp) { step(-cols * rows); return true; }
        if (e.key === Qt.Key_PageDown) { step(cols * rows); return true; }
        if (e.key === Qt.Key_Home && (e.modifiers & Qt.ControlModifier)) { step(-n); return true; }
        if (e.key === Qt.Key_End && (e.modifiers & Qt.ControlModifier)) { step(n); return true; }
        if (e.key === Qt.Key_Tab) { kind = ({ all: "still", still: "live", live: "all" })[kind]; return true; }
        if (e.key === Qt.Key_Backtab) { kind = ({ all: "live", live: "still", still: "all" })[kind]; return true; }
        if (e.key === Qt.Key_R && (e.modifiers & Qt.ControlModifier)) { shuffle(); return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (n > 0) apply(items[grid.currentIndex]);
            return true;
        }
        return false;
    }

    Process {
        id: query_
        command: ["yoru", "walls"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ws;
                try { ws = JSON.parse(this.text); } catch (e) { return; }
                v.picked = Theme.wallpaper;
                v.walls = ws.map(w => Object.assign({ colours: [], light: 0.5, added: 0 }, w));
                v.loading = false;
            }
        }
    }
    function apply(w) {
        picked = w.path;
        Quickshell.execDetached(["yoru", "wall", w.path]);
    }
    // a surprise from what's showing, so "blue" then shuffle stays blue
    function shuffle() {
        if (items.length) apply(items[Math.floor(Math.random() * items.length)]);
    }

    Txt { x: 26; y: 20; text: "Wallpapers"; size: 18; weight: Font.DemiBold }
    Txt {
        x: 26; y: 44
        text: v.loading ? "Making thumbnails…"
            : v.items.length === v.walls.length ? v.walls.length + " nights  ·  type to search, Tab for live ones, Enter to pick"
            : v.items.length + " of " + v.walls.length + "  ·  Ctrl+R picks one of these"
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
                    { id: "live", icon: "play_circle", label: "Live" }]
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
        Txt { text: v.walls.length ? "No wallpaper matches" : "No wallpapers in wallpaper.dirs"; size: 12; color: Theme.outline }
    }

    GridView {
        id: grid
        x: 12; y: 168
        width: parent.width - 24
        height: v.rows * v.cellH
        cellWidth: v.cellW
        cellHeight: v.cellH
        clip: true
        model: v.items
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false
        // only what's near the screen is made, however many walls there are
        cacheBuffer: v.cellH * 2
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool current: modelData.path === Theme.wallpaper
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
                Image {
                    anchors.fill: parent
                    source: card.modelData.thumb ? "file://" + card.modelData.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 180)
                    asynchronous: true
                }
                // the name, on the one you're on
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 34
                    visible: card.sel || hover.containsMouse
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Theme.alpha(Theme.island, 0.85) }
                    }
                    Txt {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 7 }
                        text: card.modelData.name
                        size: 11; weight: Font.Medium
                    }
                }
                Rectangle {
                    visible: card.modelData.video
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
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { grid.currentIndex = card.index; v.apply(card.modelData); }
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
