import Quickshell
import Quickshell.Io
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
    property string selected: ""         // the main one: the inspector's
    property var extra: []               // more, picked with Ctrl or a lasso
    readonly property var picked: selected ? [selected].concat(extra.filter(i => i !== selected)) : extra
    // a drag carried onto another screen: { output, x, y, w, h } there (its ghost),
    // and what lands: { ids, x0, y0 } (the dragged one's place before)
    property var crossing: null
    signal dragEnded()
    // land a crossing drag on its screen, the picked keeping their places around the dragged one
    function drop() {
        const c = crossing;
        if (!c) return;
        crossing = null;
        // the drag ends before the move: moving rebuilds the screen it left
        dragEnded();
        changeMany(c.ids, i => ({ output: c.output, x: c.x + i.x - c.x0, y: c.y + i.y - c.y0 }));
    }
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
            ed.selected = ""; ed.extra = []; ed.adding = false; ed.crossing = null;
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
        extra = extra.filter(id => item(id));
        return [from.slice(0, -1), to];
    }
    function undo() { [undos, redos] = step(undos, redos); }
    function redo() { [redos, undos] = step(redos, undos); }
    function change(id, fields, run) { commit(draft.map(i => i.id === id ? Object.assign({}, i, fields) : i), run); }
    // a widget's own setting (EditorOptions)
    function set(id, key, value, run) {
        const it = item(id);
        if (it) change(id, { settings: Object.assign({}, it.settings ?? {}, { [key]: value }) }, run ? run + " " + id : undefined);
    }
    // a file or folder from zenity. The overlay steps aside while it's open:
    // it sits above windows, the dialog would be under it
    property bool picking: false
    property var whenPicked: null
    function pick(folder, done) {
        whenPicked = done;
        picker.command = ["zenity", "--file-selection", "--title=" + (folder ? "A folder of pictures" : "A picture")]
            .concat(folder ? ["--directory"] : ["--file-filter=Pictures | *.jpg *.jpeg *.png *.webp *.gif *.avif *.bmp"]);
        picking = true;
        picker.running = true;
    }
    Process {
        id: picker
        stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p && ed.whenPicked) ed.whenPicked(p); } }
        onExited: ed.picking = false
    }
    // ── what's picked ───────────────────────────────────────────────
    function isPicked(id) { return id !== "" && (id === selected || extra.includes(id)); }
    function pickOnly(id) { selected = id; extra = []; }
    // make one the main pick, keeping the rest
    function promote(id) { extra = picked.filter(i => i !== id); selected = id; }
    function pickToggle(id) {
        if (!isPicked(id)) { if (selected) extra = extra.concat([id]); else selected = id; return; }
        const rest = picked.filter(i => i !== id);
        selected = rest[0] ?? ""; extra = rest.slice(1);
    }
    function pickAll(ids, add) {
        const all = add ? picked.concat(ids.filter(i => !picked.includes(i))) : ids;
        selected = all[0] ?? ""; extra = all.slice(1);
    }
    function changeMany(ids, fields, run) {
        commit(draft.map(i => ids.includes(i.id) ? Object.assign({}, i, typeof fields === "function" ? fields(i) : fields) : i), run);
    }

    function remove(ids) {
        if (!ids.length) return;
        commit(draft.filter(i => !ids.includes(i.id)));
        pickOnly("");
    }

    // a new widget lands at `spot` (the free place nearest the middle)
    function add(type, layout, output, spot) {
        const x = spot.x, y = spot.y;
        const id = Desk.nextId(draft, type);
        const kind = Desk.kind(type);
        commit(draft.concat([{ id: id, type: type, output: output, x: x, y: y, scale: 1, layout: layout, look: "",
                               settings: copy(kind.defaults ?? {}) }]));
        selected = id;
        adding = false;
    }
    function duplicate(ids) {
        const twins = [];
        for (const id of ids) {
            const it = item(id);
            if (it) twins.push(Object.assign(copy(it), { id: Desk.nextId(draft.concat(twins), it.type), x: it.x + 32, y: it.y + 32 }));
        }
        if (!twins.length) return;
        commit(draft.concat(twins));
        pickAll(twins.map(t => t.id));
    }
    function nudge(ids, dx, dy) {
        if (ids.length) changeMany(ids, i => ({ x: i.x + dx, y: i.y + dy }), "nudge " + ids.join(" "));
    }

    function key(e, output) {
        const ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier;
        const n = shift ? cell : 1;
        switch (e.key) {
        case Qt.Key_Escape:
            if (adding) adding = false;
            else if (picked.length) pickOnly("");
            else Desk.done();
            return true;
        case Qt.Key_Delete: case Qt.Key_Backspace: remove(picked); return true;
        case Qt.Key_G: Config.o.desktop.snapGrid = !grid; return true;
        case Qt.Key_A:
            // Ctrl+A: everything on this screen
            if (ctrl) pickAll(draft.filter(i => Desk.outputOf(i) === output).map(i => i.id));
            else adding = !adding;
            return true;
        case Qt.Key_D: if (ctrl) { duplicate(picked); return true; } return false;
        case Qt.Key_Z: if (ctrl) { if (shift) redo(); else undo(); return true; } return false;
        case Qt.Key_Y: if (ctrl) { redo(); return true; } return false;
        case Qt.Key_Left: nudge(picked, -n, 0); return true;
        case Qt.Key_Right: nudge(picked, n, 0); return true;
        case Qt.Key_Up: nudge(picked, 0, -n); return true;
        case Qt.Key_Down: nudge(picked, 0, n); return true;
        case Qt.Key_Tab: {
            // through this screen's widgets, in order
            const ids = draft.filter(i => Desk.outputOf(i) === output).map(i => i.id);
            if (ids.length) pickOnly(ids[(ids.indexOf(selected) + 1) % ids.length]);
            return true;
        }
        }
        return false;
    }

    // ── small pieces ────────────────────────────────────────────────
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
            readonly property bool main: Wm.focusedOutput === out || !Quickshell.screens.some(s => s.name === Wm.focusedOutput)
            screen: modelData
            visible: !ed.picking
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
            // a group drag: how far the picked ones have moved, before it's saved
            property bool groupMoving: false
            property real groupDx: 0
            property real groupDy: 0
            // the lasso, while one is drawn
            property rect lasso: Qt.rect(0, 0, 0, 0)
            property bool lassoing: false
            // the screen under a point in the layout (for drags that leave this one)
            function screenAt(gx, gy) {
                return Quickshell.screens.find(sc => gx >= sc.x && gx < sc.x + sc.width && gy >= sc.y && gy < sc.y + sc.height) ?? null;
            }
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
            function snap(moving, x, y, w, h, free) {
                const W = width, H = height, reach = 10;
                if (free) return { x: Math.round(x), y: Math.round(y), gx: [], gy: [] };
                const tx = [{ v: W / 2, at: [0.5] }, { v: 24, at: [0] }, { v: W - 24, at: [1] }];
                const ty = [{ v: H / 2, at: [0.5] }, { v: 70, at: [0] }, { v: H - 24, at: [1] }];
                for (const other in boxes) {
                    const b = boxes[other];
                    if (moving.includes(other) || !b) continue;
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
                // keys a text field (the inspector's) didn't take: Escape leaves the field
                Keys.onPressed: e => {
                    if (!root.activeFocus) {
                        if (e.key === Qt.Key_Escape) { root.forceActiveFocus(); e.accepted = true; }
                        return;
                    }
                    if (ed.key(e, ov.out)) e.accepted = true;
                }
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

                // the desktop itself: a click lets go of what's picked, a drag draws a
                // lasso around widgets (Ctrl adds them to what's picked)
                MouseArea {
                    anchors.fill: parent
                    property point from
                    onPressed: m => { from = Qt.point(m.x, m.y); ov.lassoing = false; root.forceActiveFocus(); }
                    onPositionChanged: m => {
                        if (!pressed) return;
                        if (!ov.lassoing && Math.abs(m.x - from.x) + Math.abs(m.y - from.y) < 6) return;
                        ov.lassoing = true;
                        ov.lasso = Qt.rect(Math.min(from.x, m.x), Math.min(from.y, m.y), Math.abs(m.x - from.x), Math.abs(m.y - from.y));
                    }
                    onReleased: m => {
                        if (ov.lassoing) {
                            const r = ov.lasso, hit = [];
                            for (const id in ov.boxes) {
                                const b = ov.boxes[id];
                                if (b && b.x < r.x + r.width && b.x + b.width > r.x && b.y < r.y + r.height && b.y + b.height > r.y) hit.push(id);
                            }
                            ed.pickAll(hit, m.modifiers & Qt.ControlModifier);
                            ed.adding = false;
                        } else {
                            if (!(m.modifiers & Qt.ControlModifier)) ed.pickOnly("");
                            ed.adding = false;
                        }
                        ov.lassoing = false;
                    }
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
                        readonly property bool sel: ed.isPicked(wid)
                        readonly property bool main: ed.selected === wid
                        // a drag in progress: where it is and how big, before it's saved
                        property bool moving: false
                        property real liveX: modelData.x
                        property real liveY: modelData.y
                        property real liveScale: modelData.scale ?? 1
                        x: moving ? liveX : modelData.x + (ov.groupMoving && sel ? ov.groupDx : 0)
                        y: moving ? liveY : modelData.y + (ov.groupMoving && sel ? ov.groupDy : 0)
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
                                // Ctrl picks it too (or lets it go); a plain press picks it alone,
                                // unless it's already among the picked: then they all go
                                if (m.modifiers & Qt.ControlModifier) ed.pickToggle(box.wid);
                                else if (box.sel) ed.promote(box.wid);
                                else ed.pickOnly(box.wid);
                                ed.adding = false;
                                root.forceActiveFocus();
                                grab = Qt.point(m.x * 1, m.y * 1);
                                box.liveX = box.modelData.x; box.liveY = box.modelData.y; box.liveScale = box.modelData.scale ?? 1;
                                dragged = false;
                            }
                            readonly property bool group: ed.picked.length > 1 && box.sel
                            onPositionChanged: m => {
                                if (!pressed || !box.sel) return;
                                const p = mapToItem(root, m.x, m.y);
                                // past the edge, over another screen: a ghost there shows where it lands
                                const sc = p.x < 0 || p.y < 0 || p.x >= ov.width || p.y >= ov.height
                                    ? ov.screenAt(ov.modelData.x + p.x, ov.modelData.y + p.y) : null;
                                if (sc && sc.name !== ov.out) {
                                    dragged = true;
                                    ed.crossing = { output: sc.name, w: box.width, h: box.height,
                                                    x: Math.round(ov.modelData.x + p.x - sc.x - grab.x), y: Math.round(ov.modelData.y + p.y - sc.y - grab.y),
                                                    ids: group ? ed.picked : [box.wid], x0: box.modelData.x, y0: box.modelData.y };
                                    return;
                                }
                                ed.crossing = null;
                                const s = ov.snap(group ? ed.picked : [box.wid], p.x - grab.x, p.y - grab.y, box.width, box.height, m.modifiers & Qt.ShiftModifier);
                                if (!dragged && Math.abs(s.x - box.modelData.x) + Math.abs(s.y - box.modelData.y) < 3) return;
                                dragged = true;
                                if (group) {
                                    ov.groupDx = s.x - box.modelData.x; ov.groupDy = s.y - box.modelData.y;
                                    ov.groupMoving = true;
                                } else {
                                    box.moving = true;
                                    box.liveX = s.x; box.liveY = s.y;
                                }
                                ov.guidesX = s.gx; ov.guidesY = s.gy;
                            }
                            onReleased: finish()
                            Connections { target: ed; function onDragEnded() { box.moving = false; body.dragged = false; ov.groupMoving = false; } }
                            onCanceled: finish()
                            function finish() {
                                ov.guidesX = []; ov.guidesY = [];
                                const ids = group ? ed.picked : [box.wid];
                                if (ed.crossing) {
                                    // this box is rebuilt by the move: nothing of it to touch after
                                    ed.drop();
                                    return;
                                } else if (dragged && group) {
                                    ed.changeMany(ids, i => ({ x: i.x + ov.groupDx, y: i.y + ov.groupDy }));
                                } else if (dragged) {
                                    ed.change(box.wid, { x: box.liveX, y: box.liveY });
                                }
                                box.moving = false; dragged = false;
                                ov.groupMoving = false; ov.groupDx = 0; ov.groupDy = 0;
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
                            // resizing is one at a time
                            model: box.main && ed.picked.length === 1 ? 4 : 0
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
                            visible: box.main
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

                // an aro without the implicit-grab fix gives the release to the screen the
                // drag ended on, not the one it started on: the pointer arriving here with a
                // drop pending is the sign it was let go
                HoverHandler {
                    onHoveredChanged: if (hovered && ed.crossing && ed.crossing.output === ov.out) ed.drop()
                }

                // the lasso being drawn
                Rectangle {
                    visible: ov.lassoing
                    x: ov.lasso.x; y: ov.lasso.y; width: ov.lasso.width; height: ov.lasso.height
                    radius: 8
                    color: Theme.alpha(Theme.primary, 0.12)
                    border.width: 1.5; border.color: Theme.primary
                }
                // a widget dragged here from another screen: where it will land
                Rectangle {
                    readonly property var c: ed.crossing
                    visible: !!c && c.output === ov.out
                    x: c?.x ?? 0; y: c?.y ?? 0; width: c?.w ?? 0; height: c?.h ?? 0
                    radius: 24
                    color: Theme.alpha(Theme.primary, 0.16)
                    border.width: 2; border.color: Theme.primary
                    Txt { anchors.centerIn: parent; text: ed.picked.length > 1 ? "Move " + ed.picked.length + " here" : "Move here"
                          size: 14; weight: Font.DemiBold; color: Theme.primary }
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
                        Tool { icon: "content_copy"; usable: ed.picked.length > 0; onClicked: ed.duplicate(ed.picked) }
                        Tool { icon: "delete"; usable: ed.picked.length > 0; onClicked: ed.remove(ed.picked) }
                        Divider {}
                        Tool { icon: "undo"; usable: ed.undos.length > 0; onClicked: ed.undo() }
                        Tool { icon: "redo"; usable: ed.redos.length > 0; onClicked: ed.redo() }
                        Tool { icon: "grid_4x4"; active: ed.grid; onClicked: Config.o.desktop.snapGrid = !ed.grid }
                        Divider {}
                        Pill { icon: "check"; label: "Done"; primary: true; onClicked: Desk.done() }
                    }
                }

                // ── the palette: the kinds down the left, the chosen one's layouts beside ──
                Rectangle {
                    id: shelf
                    visible: ed.adding
                    z: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: bar.y + bar.height + 10
                    width: Math.min(root.width - 80, 1180)
                    height: Math.min(root.height - y - 40, 860)
                    radius: 30
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.6)
                    property string kind: "clock"
                    readonly property var chosen: Desk.kind(kind)
                    // clicks inside don't reach the desktop
                    MouseArea { anchors.fill: parent }

                    Flickable {
                        id: kindList
                        x: 12; y: 12
                        width: 220; height: parent.height - 24
                        contentHeight: kindCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: kindCol
                            width: parent.width
                            spacing: 2
                            Repeater {
                                model: ed.adding ? Desk.groups : []
                                Column {
                                    id: groupCol
                                    required property string modelData
                                    width: kindCol.width
                                    spacing: 2
                                    Txt { leftPadding: 14; topPadding: 10; bottomPadding: 4; text: groupCol.modelData.toUpperCase(); size: 10; weight: Font.Bold
                                          color: Theme.inkDim; font.letterSpacing: 1.2 }
                                    Repeater {
                                        model: Desk.types.filter(t => t.group === groupCol.modelData)
                                        Rectangle {
                                            id: kindRow
                                            required property var modelData
                                            readonly property bool on: shelf.kind === modelData.type
                                            width: groupCol.width; height: 36
                                            radius: on ? 14 : 20
                                            color: on ? Theme.secondaryContainer : "transparent"
                                            Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                                            Row {
                                                x: 14; anchors.verticalCenter: parent.verticalCenter
                                                spacing: 12
                                                Icon { name: kindRow.modelData.icon; size: 20; fill: kindRow.on ? 1 : 0
                                                       color: kindRow.on ? Theme.inkSecondaryContainer : Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                                                Txt { text: kindRow.modelData.name; size: 14; weight: kindRow.on ? Font.DemiBold : Font.Normal
                                                      color: kindRow.on ? Theme.inkSecondaryContainer : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                            StateLayer { onClicked: shelf.kind = kindRow.modelData.type }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { x: kindList.x + kindList.width + 8; y: 20; width: 1; height: parent.height - 40; color: Theme.outlineVariant }

                    Flickable {
                        id: list
                        x: kindList.x + kindList.width + 26; y: 16
                        width: parent.width - x - 18; height: parent.height - 32
                        contentHeight: tiles.implicitHeight + 50
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        Txt { y: 6; text: shelf.chosen.name; size: 18; weight: Font.DemiBold }
                        Txt { y: 32; text: "Pick a layout to place it; its look and size come after"; size: 12; color: Theme.inkDim }
                        Flow {
                            id: tiles
                            y: 62; width: list.width
                            spacing: 12
                            Repeater {
                                model: ed.adding ? shelf.chosen.layouts : []
                                // a live copy; click to place it
                                Rectangle {
                                    id: tile
                                    required property var modelData
                                    readonly property real k: Math.min(0.6, 230 / Math.max(1, prev.baseWidth), 200 / Math.max(1, prev.baseHeight))
                                    width: Math.max(prev.width, 150) + 24
                                    height: prev.height + 48
                                    radius: 22
                                    color: pick.containsMouse ? Theme.surfaceHigh : Theme.surfaceLow
                                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                                    Placed {
                                        id: prev
                                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
                                        item: ({ id: "", type: shelf.kind, layout: tile.modelData[0], look: "" })
                                        k: tile.k
                                        force: true
                                    }
                                    Txt { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 11 }
                                          text: tile.modelData[1]; size: 12; color: Theme.inkDim }
                                    MouseArea {
                                        id: pick
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ed.add(shelf.kind, tile.modelData[0], ov.out, ov.room(prev.baseWidth, prev.baseHeight))
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
                    readonly property bool many: ed.picked.length > 1
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
                            Txt { text: inspector.many ? ed.picked.length + " widgets" : inspector.kind.name; size: 16; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                            Txt { visible: inspector.many; text: "their look and size change together"; size: 12; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Row {
                            visible: !inspector.many
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
                                        on: (inspector.it?.layout || (inspector.kind.key ? Config.o.desktop[inspector.kind.key] : inspector.kind.layouts[0][0])) === modelData[0]
                                        onClicked: ed.change(ed.selected, { layout: modelData[0] })
                                    }
                                }
                            }
                        }
                        Row {
                            visible: !inspector.kind.bare || inspector.many
                            spacing: 12
                            Txt { width: 64; text: "Look"; size: 13; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                            Flow {
                                width: fields.width - 76
                                spacing: 6
                                Pill { label: "Like the rest"; on: !inspector.it?.look; onClicked: ed.changeMany(ed.picked, { look: "" }) }
                                Repeater {
                                    model: Desk.looks
                                    Pill {
                                        required property var modelData
                                        label: modelData[1]
                                        on: inspector.it?.look === modelData[0]
                                        onClicked: ed.changeMany(ed.picked, { look: modelData[0] })
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
                                onMoved: v => ed.changeMany(ed.picked, { scale: Math.round((0.5 + v * 2) * 20) / 20 }, "size " + ed.picked.join(" "))
                            }
                            Txt { text: Math.round((inspector.it?.scale ?? 1) * 100) + "%"; size: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter; width: 48 }
                            Pill { label: "100%"; visible: (inspector.it?.scale ?? 1) !== 1; onClicked: ed.changeMany(ed.picked, { scale: 1 }) }
                        }
                        EditorOptions { visible: !inspector.many; editor: ed; it: inspector.it; width: fields.width }
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
                        text: "Drag to move (onto another screen too)  ·  drag the desktop or Ctrl+click to pick several  ·  pull a corner to resize  ·  Shift: no snapping  ·  G grid  ·  A add  ·  Del remove  ·  Ctrl+D duplicate  ·  Ctrl+Z undo  ·  Esc done"
                    }
                }
            }
        }
    }
}
