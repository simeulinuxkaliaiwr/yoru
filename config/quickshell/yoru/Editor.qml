import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.parts
import qs.desktop

// edit mode (mod+e): the desktop's widgets, live, over everything. Drag one to
// move it (it snaps to the grid, the screen's middle and edges, and the other
// widgets), drag a corner to resize it, pick its layout and look underneath,
// add more from the palette. Every change is saved as it's made; Ctrl+Z undoes.
Scope {
    id: ed

    // the working copy; Desk.items follows it on every change
    property var draft: []
    property var undos: []
    property var redos: []
    property string selected: ""
    property bool adding: false
    readonly property bool grid: Config.o.desktop.snapGrid
    readonly property int cell: 16

    Connections {
        target: Desk
        function onEditingChanged() {
            if (Desk.editing) {
                ed.draft = ed.copy(Desk.items);
                ed.undos = []; ed.redos = [];
            }
            ed.selected = ""; ed.adding = false;
        }
    }

    function copy(x) { return JSON.parse(JSON.stringify(x)); }
    function item(id) { return draft.find(i => i.id === id) ?? null; }
    // `run` names a change that comes in a stream (a slider drag, arrow
    // nudges): one undo step takes back the whole run
    property string lastRun: ""
    function commit(next, run) {
        if (!run || run !== lastRun || !undos.length) undos = undos.concat([JSON.stringify(draft)]).slice(-80);
        lastRun = run ?? "";
        redos = [];
        draft = next;
        Desk.save(next);
    }
    function step(from, to) {
        if (!from.length) return [from, to];
        to = to.concat([JSON.stringify(draft)]);
        draft = JSON.parse(from[from.length - 1]);
        lastRun = "";
        Desk.save(draft);
        if (!item(selected)) selected = "";
        return [from.slice(0, -1), to];
    }
    function undo() { [undos, redos] = step(undos, redos); }
    function redo() { [redos, undos] = step(redos, undos); }
    function change(id, fields, run) { commit(draft.map(i => i.id === id ? Object.assign({}, i, fields) : i), run); }
    function remove(id) { if (item(id)) { commit(draft.filter(i => i.id !== id)); selected = ""; } }

    // a new widget lands at `spot` (the free place nearest the middle)
    function add(type, layout, output, spot) {
        const x = spot.x, y = spot.y;
        const id = Desk.nextId(draft, type);
        commit(draft.concat([{ id: id, type: type, output: output, x: x, y: y, scale: 1, layout: layout, look: "" }]));
        selected = id;
        adding = false;
    }
    function duplicate(id) {
        const it = item(id);
        if (!it) return;
        const twin = Object.assign({}, it, { id: Desk.nextId(draft, it.type), x: it.x + 32, y: it.y + 32 });
        commit(draft.concat([twin]));
        selected = twin.id;
    }
    function nudge(id, dx, dy) {
        const it = item(id);
        if (it) change(id, { x: it.x + dx, y: it.y + dy }, "nudge " + id);
    }

    function key(e, output) {
        const ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier;
        const n = shift ? cell : 1;
        switch (e.key) {
        case Qt.Key_Escape:
            if (adding) adding = false;
            else if (selected) selected = "";
            else Desk.done();
            return true;
        case Qt.Key_Delete: case Qt.Key_Backspace: remove(selected); return true;
        case Qt.Key_G: Config.o.desktop.snapGrid = !grid; return true;
        case Qt.Key_A: if (!ctrl) { adding = !adding; return true; } return false;
        case Qt.Key_D: if (ctrl) { duplicate(selected); return true; } return false;
        case Qt.Key_Z: if (ctrl) { if (shift) redo(); else undo(); return true; } return false;
        case Qt.Key_Y: if (ctrl) { redo(); return true; } return false;
        case Qt.Key_Left: nudge(selected, -n, 0); return true;
        case Qt.Key_Right: nudge(selected, n, 0); return true;
        case Qt.Key_Up: nudge(selected, 0, -n); return true;
        case Qt.Key_Down: nudge(selected, 0, n); return true;
        case Qt.Key_Tab: {
            // through this screen's widgets, in order
            const ids = draft.filter(i => Desk.outputOf(i) === output).map(i => i.id);
            if (ids.length) selected = ids[(ids.indexOf(selected) + 1) % ids.length];
            return true;
        }
        }
        return false;
    }

    // ── small pieces ────────────────────────────────────────────────
    // a pill with an icon and a label; `on` fills it
    component Pill: Rectangle {
        id: pill
        property string icon: ""
        property string label: ""
        property bool on: false
        property bool primary: false
        signal clicked()
        height: 36
        width: row.implicitWidth + (label !== "" ? 28 : 18)
        radius: on ? 12 : height / 2
        color: primary ? Theme.primary : on ? Theme.secondaryContainer : "transparent"
        border.width: primary || on ? 0 : 1
        border.color: Theme.outlineVariant
        opacity: enabled ? 1 : 0.35
        readonly property color ink: primary ? Theme.inkPrimary : on ? Theme.inkSecondaryContainer : Theme.ink
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Icon { visible: pill.icon !== ""; name: pill.icon; size: 18; color: pill.ink; anchors.verticalCenter: parent.verticalCenter }
            Txt { visible: pill.label !== ""; text: pill.label; size: 13; weight: Font.Medium; color: pill.ink; anchors.verticalCenter: parent.verticalCenter }
        }
        StateLayer { enabled: pill.enabled; tint: pill.ink; onClicked: pill.clicked() }
    }
    component Tool: IconButton {
        property bool usable: true
        size: 36
        opacity: usable ? 1 : 0.35
        enabled: usable
    }
    component Divider: Rectangle { width: 1; height: 22; color: Theme.outlineVariant; anchors.verticalCenter: parent?.verticalCenter }

    // ── one overlay per screen ──────────────────────────────────────
    Variants {
        model: Desk.editing ? Quickshell.screens : []

        PanelWindow {
            id: ov
            required property var modelData
            readonly property string out: modelData.name
            // the keyboard goes to the screen you're on
            readonly property bool main: Aro.focusedOutput === out || !Quickshell.screens.some(s => s.name === Aro.focusedOutput)
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "yoru-edit"
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var mine: ed.draft.filter(i => Desk.outputOf(i) === out)
            readonly property var sel: ed.item(ed.selected)
            readonly property bool selHere: !!sel && Desk.outputOf(sel) === out
            // the boxes on screen by id, for snapping to each other
            property var boxes: ({})
            // the lines a drag is snapping to
            property var guidesX: []
            property var guidesY: []

            // the free place for a w×h widget nearest the middle of the screen,
            // on the grid and clear of the others (and the toolbar); the middle
            // itself if the screen is full
            function room(w, h) {
                const gap = 16, step = ed.cell * 2, cx = (width - w) / 2, cy = (height - h) / 2;
                const taken = Object.values(boxes).filter(b => b).map(b => ({ x: b.x, y: b.y, w: b.width, h: b.height }))
                    .concat([{ x: bar.x, y: bar.y, w: bar.width, h: bar.height }]);
                const free = (x, y) => x >= 24 && y >= 70 && x + w <= width - 24 && y + h <= height - 24
                    && !taken.some(t => x < t.x + t.w + gap && x + w + gap > t.x && y < t.y + t.h + gap && y + h + gap > t.y);
                const snapTo = v => Math.round(v / ed.cell) * ed.cell;
                for (let r = 0; r * step < Math.max(width, height); r++)
                    for (let i = -r; i <= r; i++)
                        for (const [dx, dy] of [[i, -r], [i, r], [-r, i], [r, i]]) {
                            const x = snapTo(cx + dx * step), y = snapTo(cy + dy * step);
                            if (free(x, y)) return { x: x, y: y };
                        }
                return { x: Math.round(cx), y: Math.round(cy) };
            }

            // where a box at x,y (w×h) settles: the nearest edge or middle within
            // reach of a guide, else the grid. Shift (free) turns it all off
            function snap(id, x, y, w, h, free) {
                const W = width, H = height, reach = 10;
                if (free) return { x: Math.round(x), y: Math.round(y), gx: [], gy: [] };
                const tx = [{ v: W / 2, at: [0.5] }, { v: 24, at: [0] }, { v: W - 24, at: [1] }];
                const ty = [{ v: H / 2, at: [0.5] }, { v: 70, at: [0] }, { v: H - 24, at: [1] }];
                for (const other in boxes) {
                    const b = boxes[other];
                    if (other === id || !b) continue;
                    tx.push({ v: b.x, at: [0, 1] }, { v: b.x + b.width, at: [0, 1] }, { v: b.x + b.width / 2, at: [0.5] },
                            { v: b.x + b.width + 12, at: [0] }, { v: b.x - 12, at: [1] });
                    ty.push({ v: b.y, at: [0, 1] }, { v: b.y + b.height, at: [0, 1] }, { v: b.y + b.height / 2, at: [0.5] },
                            { v: b.y + b.height + 12, at: [0] }, { v: b.y - 12, at: [1] });
                }
                function best(pos, size, targets) {
                    let pick = null;
                    for (const t of targets)
                        for (const a of t.at) {
                            const d = t.v - (pos + size * a);
                            if (Math.abs(d) <= reach && (!pick || Math.abs(d) < Math.abs(pick.d))) pick = { d: d, line: t.v };
                        }
                    return pick;
                }
                const bx = best(x, w, tx), by = best(y, h, ty);
                return {
                    x: bx ? Math.round(x + bx.d) : ed.grid ? Math.round(x / ed.cell) * ed.cell : Math.round(x),
                    y: by ? Math.round(y + by.d) : ed.grid ? Math.round(y / ed.cell) * ed.cell : Math.round(y),
                    gx: bx ? [bx.line] : [], gy: by ? [by.line] : []
                };
            }

            Item {
                id: root
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => { if (ed.key(e, ov.out)) e.accepted = true; }
                Component.onCompleted: forceActiveFocus()

                // the wallpaper, dimmed, so windows don't get in the way
                Image {
                    anchors.fill: parent
                    source: Theme.still ? "file://" + Theme.still : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(ov.width, ov.height)
                }
                Rectangle {
                    id: dim
                    anchors.fill: parent
                    color: "black"
                    opacity: 0
                    Component.onCompleted: opacity = 0.32
                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                }
                // the grid: a line every cell, a stronger one every four
                Canvas {
                    id: gridLines
                    anchors.fill: parent
                    visible: ed.grid
                    opacity: 0.9
                    onPaint: {
                        const g = getContext("2d");
                        g.reset();
                        for (let i = 0; i * ed.cell <= width; i++) {
                            g.fillStyle = i % 4 ? "rgba(255,255,255,0.05)" : "rgba(255,255,255,0.11)";
                            g.fillRect(i * ed.cell, 0, 1, height);
                        }
                        for (let j = 0; j * ed.cell <= height; j++) {
                            g.fillStyle = j % 4 ? "rgba(255,255,255,0.05)" : "rgba(255,255,255,0.11)";
                            g.fillRect(0, j * ed.cell, width, 1);
                        }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }
                // the middle, always marked
                Rectangle { x: Math.round(parent.width / 2); width: 1; height: parent.height; color: Theme.alpha(Theme.primary, 0.35) }
                Rectangle { y: Math.round(parent.height / 2); height: 1; width: parent.width; color: Theme.alpha(Theme.primary, 0.35) }

                // clicking the desktop itself lets go of the selection
                MouseArea {
                    anchors.fill: parent
                    onClicked: { ed.selected = ""; ed.adding = false; }
                }

                // ── the widgets ─────────────────────────────────────
                // by count, so a change updates the boxes in place; only adding or
                // removing one rebuilds them
                Repeater {
                    model: ov.mine.length
                    Item {
                        id: box
                        required property int index
                        readonly property var modelData: ov.mine[index] ?? ({ id: "", type: "", x: 0, y: 0, scale: 1 })
                        readonly property string wid: modelData.id
                        readonly property bool sel: ed.selected === wid
                        // a drag in progress: where it is and how big, before it's saved
                        property bool moving: false
                        property real liveX: modelData.x
                        property real liveY: modelData.y
                        property real liveScale: modelData.scale ?? 1
                        x: moving ? liveX : modelData.x
                        y: moving ? liveY : modelData.y
                        width: view.width; height: view.height
                        z: sel ? 2 : 1

                        Component.onCompleted: ov.boxes[wid] = box
                        Component.onDestruction: if (ov.boxes[wid] === box) delete ov.boxes[wid]

                        Placed {
                            id: view
                            item: box.modelData
                            force: true
                            k: box.moving ? box.liveScale : (box.modelData.scale ?? 1)
                            opacity: live ? 1 : 0.55
                        }
                        // shows only sometimes: say when
                        Rectangle {
                            visible: !view.live
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 8 }
                            width: why.implicitWidth + 20; height: 24; radius: 12
                            color: Theme.alpha(Theme.surfaceLowest, 0.85)
                            Txt { id: why; anchors.centerIn: parent; size: 11; color: Theme.inkDim
                                  text: box.modelData.type === "media" ? "Shows while music plays" : "Shows once the forecast is in" }
                        }

                        // move: drag anywhere on it
                        MouseArea {
                            id: body
                            anchors.fill: parent
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            property point grab
                            property bool dragged: false
                            onPressed: m => {
                                ed.selected = box.wid; ed.adding = false;
                                grab = Qt.point(m.x * 1, m.y * 1);
                                box.liveX = box.modelData.x; box.liveY = box.modelData.y; box.liveScale = box.modelData.scale ?? 1;
                                dragged = false;
                            }
                            onPositionChanged: m => {
                                if (!pressed) return;
                                const p = mapToItem(root, m.x, m.y);
                                const s = ov.snap(box.wid, p.x - grab.x, p.y - grab.y, box.width, box.height, m.modifiers & Qt.ShiftModifier);
                                if (!dragged && Math.abs(s.x - box.modelData.x) + Math.abs(s.y - box.modelData.y) < 3) return;
                                dragged = true; box.moving = true;
                                box.liveX = s.x; box.liveY = s.y;
                                ov.guidesX = s.gx; ov.guidesY = s.gy;
                            }
                            onReleased: {
                                ov.guidesX = []; ov.guidesY = [];
                                if (dragged) ed.change(box.wid, { x: box.liveX, y: box.liveY });
                                box.moving = false;
                            }
                        }

                        // selected: a ring and four corners to pull
                        Rectangle {
                            visible: box.sel
                            anchors { fill: parent; margins: -6 }
                            radius: (view.card?.radius ?? 28) * view.k + 6
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.primary
                        }
                        Repeater {
                            model: box.sel ? 4 : 0
                            Rectangle {
                                id: corner
                                required property int index
                                readonly property bool atRight: index % 2 === 1
                                readonly property bool atBottom: index >= 2
                                width: 16; height: 16; radius: 8
                                x: (atRight ? box.width + 6 : -6) - width / 2
                                y: (atBottom ? box.height + 6 : -6) - height / 2
                                color: Theme.primary
                                border.width: 2; border.color: Theme.surfaceLowest
                                scale: pull.containsMouse || pull.pressed ? 1.3 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.fast } }
                                MouseArea {
                                    id: pull
                                    anchors { fill: parent; margins: -8 }
                                    hoverEnabled: true
                                    cursorShape: corner.atRight === corner.atBottom ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                                    // the opposite corner stays put
                                    property point anchor
                                    onPressed: {
                                        anchor = Qt.point(corner.atRight ? box.x : box.x + box.width, corner.atBottom ? box.y : box.y + box.height);
                                        box.liveX = box.x; box.liveY = box.y; box.liveScale = view.k;
                                        box.moving = true;
                                    }
                                    onPositionChanged: m => {
                                        if (!pressed) return;
                                        const p = mapToItem(root, m.x, m.y);
                                        let s = Math.max(Math.abs(p.x - anchor.x) / view.baseWidth, Math.abs(p.y - anchor.y) / view.baseHeight);
                                        s = Math.min(2.5, Math.max(0.5, s));
                                        if (!(m.modifiers & Qt.ShiftModifier)) s = Math.round(s * 20) / 20;
                                        box.liveScale = s;
                                        box.liveX = Math.round(corner.atRight ? anchor.x : anchor.x - view.baseWidth * s);
                                        box.liveY = Math.round(corner.atBottom ? anchor.y : anchor.y - view.baseHeight * s);
                                    }
                                    onReleased: {
                                        ed.change(box.wid, { x: box.liveX, y: box.liveY, scale: box.liveScale });
                                        box.moving = false;
                                    }
                                }
                            }
                        }
                        // what it is, above it
                        Rectangle {
                            visible: box.sel
                            anchors { left: parent.left; bottom: parent.top; bottomMargin: 14 }
                            width: tag.implicitWidth + 20; height: 26; radius: 13
                            color: Theme.primary
                            Txt {
                                id: tag
                                anchors.centerIn: parent
                                size: 12; weight: Font.DemiBold; color: Theme.inkPrimary
                                text: view.kind.name + "  ·  " + Math.round(view.k * 100) + "%"
                            }
                        }
                    }
                }

                // the lines a drag is snapping to
                Repeater {
                    model: ov.guidesX
                    Rectangle { required property real modelData; x: Math.round(modelData); width: 1; height: root.height; color: Theme.primary }
                }
                Repeater {
                    model: ov.guidesY
                    Rectangle { required property real modelData; y: Math.round(modelData); height: 1; width: root.width; color: Theme.primary }
                }

                // ── the toolbar: under the island, can be dragged aside ──
                Rectangle {
                    id: bar
                    property real px: (root.width - width) / 2
                    property real py: 62
                    x: Math.max(8, Math.min(root.width - width - 8, px))
                    y: Math.max(8, Math.min(root.height - height - 8, py))
                    width: tools.implicitWidth + 16
                    height: 52
                    radius: 26
                    color: Theme.island
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.6)
                    z: 10

                    Row {
                        id: tools
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        // the handle
                        Item {
                            width: handle.implicitWidth + 16; height: 36
                            Row {
                                id: handle
                                anchors.centerIn: parent
                                spacing: 6
                                Icon { name: "drag_indicator"; size: 18; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                                Txt { text: "Edit desktop"; size: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                property point grab
                                onPressed: m => grab = mapToItem(bar, m.x, m.y)
                                onPositionChanged: m => {
                                    if (!pressed) return;
                                    const p = mapToItem(root, m.x, m.y);
                                    bar.px = p.x - grab.x; bar.py = p.y - grab.y;
                                }
                            }
                        }
                        Divider {}
                        Pill { icon: "add"; label: "Add"; on: ed.adding; onClicked: ed.adding = !ed.adding }
                        Tool { icon: "content_copy"; usable: ov.selHere; onClicked: ed.duplicate(ed.selected) }
                        Tool { icon: "delete"; usable: ov.selHere; onClicked: ed.remove(ed.selected) }
                        Divider {}
                        Tool { icon: "undo"; usable: ed.undos.length > 0; onClicked: ed.undo() }
                        Tool { icon: "redo"; usable: ed.redos.length > 0; onClicked: ed.redo() }
                        Tool { icon: "grid_4x4"; active: ed.grid; onClicked: Config.o.desktop.snapGrid = !ed.grid }
                        Divider {}
                        Pill { icon: "check"; label: "Done"; primary: true; onClicked: Desk.done() }
                    }
                }

                // ── the palette: every widget in every layout ──────
                Rectangle {
                    id: palette
                    visible: ed.adding
                    z: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: bar.y + bar.height + 10
                    width: Math.min(root.width - 80, 1180)
                    height: Math.min(root.height - y - 40, list.contentHeight + 32)
                    radius: 30
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.6)
                    // clicks inside don't reach the desktop
                    MouseArea { anchors.fill: parent }

                    Flickable {
                        id: list
                        anchors { fill: parent; margins: 16 }
                        contentHeight: kinds.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: kinds
                            width: list.width
                            spacing: 18
                            Repeater {
                                model: ed.adding ? Desk.types : []
                                Row {
                                    id: kindRow
                                    required property var modelData
                                    spacing: 14
                                    Column {
                                        width: 130
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Icon { name: kindRow.modelData.icon; size: 26; color: Theme.primary }
                                        Txt { text: kindRow.modelData.name; size: 15; weight: Font.DemiBold }
                                    }
                                    Repeater {
                                        model: kindRow.modelData.layouts
                                        // a small live copy; click to place it
                                        Rectangle {
                                            id: tile
                                            required property var modelData
                                            readonly property real k: 0.42
                                            width: Math.max(prev.width, 110) + 20
                                            height: prev.height + 44
                                            radius: 20
                                            color: pick.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow
                                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                                            Placed {
                                                id: prev
                                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
                                                item: ({ id: "preview", type: kindRow.modelData.type, layout: tile.modelData[0], look: "", scale: tile.k })
                                                force: true
                                            }
                                            Txt { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 9 }
                                                  text: tile.modelData[1]; size: 12; color: Theme.inkDim }
                                            MouseArea {
                                                id: pick
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ed.add(kindRow.modelData.type, tile.modelData[0], ov.out,
                                                                  ov.room(prev.baseWidth, prev.baseHeight))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── the selected widget's layout, look and size ───
                Rectangle {
                    id: inspector
                    visible: ov.selHere && !ed.adding
                    z: 10
                    readonly property var it: ov.sel
                    readonly property var kind: Desk.kind(it?.type ?? "")
                    anchors.horizontalCenter: parent.horizontalCenter
                    // out of the way of the widget it's about
                    readonly property bool low: !it || it.y < root.height / 2
                    y: low ? root.height - height - 28 : bar.y + bar.height + 12
                    width: Math.min(root.width - 80, 1060)
                    height: fields.implicitHeight + 32
                    radius: 28
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.6)
                    MouseArea { anchors.fill: parent }

                    Column {
                        id: fields
                        x: 20; y: 16
                        width: parent.width - 40
                        spacing: 10
                        Row {
                            spacing: 10
                            Icon { name: inspector.kind.icon; size: 22; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            Txt { text: inspector.kind.name; size: 16; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Row {
                            spacing: 12
                            Txt { width: 64; text: "Layout"; size: 13; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                            Flow {
                                width: fields.width - 76
                                spacing: 6
                                Repeater {
                                    model: inspector.kind.layouts
                                    Pill {
                                        required property var modelData
                                        label: modelData[1]
                                        on: (inspector.it?.layout || Config.o.desktop[inspector.kind.key]) === modelData[0]
                                        onClicked: ed.change(ed.selected, { layout: modelData[0] })
                                    }
                                }
                            }
                        }
                        Row {
                            spacing: 12
                            Txt { width: 64; text: "Look"; size: 13; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                            Flow {
                                width: fields.width - 76
                                spacing: 6
                                Pill { label: "Like the rest"; on: !inspector.it?.look; onClicked: ed.change(ed.selected, { look: "" }) }
                                Repeater {
                                    model: Desk.looks
                                    Pill {
                                        required property var modelData
                                        label: modelData[1]
                                        on: inspector.it?.look === modelData[0]
                                        onClicked: ed.change(ed.selected, { look: modelData[0] })
                                    }
                                }
                            }
                        }
                        Row {
                            spacing: 12
                            Txt { width: 64; text: "Size"; size: 13; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                            Slider {
                                id: sizer
                                width: 300; h: 30
                                anchors.verticalCenter: parent.verticalCenter
                                value: ((inspector.it?.scale ?? 1) - 0.5) / 2
                                onMoved: v => ed.change(ed.selected, { scale: Math.round((0.5 + v * 2) * 20) / 20 }, "size " + ed.selected)
                            }
                            Txt { text: Math.round((inspector.it?.scale ?? 1) * 100) + "%"; size: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter; width: 48 }
                            Pill { label: "100%"; visible: (inspector.it?.scale ?? 1) !== 1; onClicked: ed.change(ed.selected, { scale: 1 }) }
                        }
                    }
                }

                // what the keys do, while nothing's chosen
                Rectangle {
                    visible: !ov.selHere && !ed.adding
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 26 }
                    width: hints.implicitWidth + 32; height: 36; radius: 18
                    color: Theme.alpha(Theme.island, 0.9)
                    Txt {
                        id: hints
                        anchors.centerIn: parent
                        size: 12; color: Theme.inkDim
                        text: "Drag to move  ·  pull a corner to resize  ·  Shift: no snapping  ·  G grid  ·  A add  ·  Tab next  ·  Del remove  ·  Ctrl+D duplicate  ·  Ctrl+Z undo  ·  Esc done"
                    }
                }
            }
        }
    }
}
