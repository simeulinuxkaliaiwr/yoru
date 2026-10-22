import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs
import qs.parts

// the ring: your apps in a circle around the pointer. Point toward one and click,
// or turn it with the arrows / Tab and press Enter (1–9 pick directly). A dot under
// an app means it's open: picking it brings that window back instead of a second one.
// Typing searches: the ring fills with the best matches (Backspace edits, Esc clears).
// The list's own modes (":" emoji, "?" web, ">" a command, "=" maths) and a search with
// no app hand over to the island's launcher. Right-click takes an app off the ring.
// Apps: launcher.ringApps, or the ones you open most.
// With launcher.ringMorph the island itself flies down and opens into the ring.
// With launcher.ringGlow each icon glows in its own colours, brightest where you point.
Scope {
    id: ring
    property bool shown: false
    property bool alive: false              // still drawing: open, or animating closed
    property string output: ""
    property var apps: []
    property string query: ""
    property var isle: null                 // the Island, to grow out of
    property var from: null                 // its pill on this screen: { x, y, w, h, r }
    property bool morph: false
    signal typed(string text)

    function toggle() { shown ? close() : open(); }
    function open() {
        output = Wm.focusedOutput || (Quickshell.screens[0]?.name ?? "");
        query = "";
        apps = pickApps();
        const p = isle?.pills?.[output];
        morph = Config.o.launcher.ringMorph && !!p && !p.gone;
        from = morph ? p : null;
        if (morph) { isle.awayQuick = true; isle.away = output; }
        alive = true;
        shown = true;
    }
    function close() {
        // fold back into wherever the island is now (the launcher, if you typed)
        const p = isle?.pills?.[output];
        if (morph && p && !p.gone) from = p;
        shown = false;
    }
    onAliveChanged: if (!alive && isle) {
        if (isle.away === output) isle.away = "";
        isle.awayQuick = false;
    }

    function pickApps() {
        const pinned = Config.o.launcher.ringApps ?? [];
        if (pinned.length > 0) return pinned.map(id => Apps.entry(id)).filter(e => e).slice(0, 12);
        // the ones you open most, then what's running, then a few by name so it's never bare
        const out = Apps.most().slice(0, 10);
        for (const e of Apps.entries)
            if (out.length < 12 && !out.includes(e) && Apps.windowsOf(e).length > 0) out.push(e);
        for (const e of Apps.entries.slice().sort((a, b) => a.name.localeCompare(b.name)))
            if (out.length < 8 && !out.includes(e)) out.push(e);
        return out;
    }
    function search(text) {
        query = text;
        apps = text.trim() === "" ? pickApps() : Apps.search(text, 12);
    }
    // what the ring can't show goes to the island's list
    function handOver() {
        typed(query);
        close();
    }

    function pick(e) {
        if (!e) return;
        // an open one comes back (the window used last); otherwise it starts
        if (!Apps.raise(e)) Apps.launch(e);
        close();
    }
    // right-click: off the ring (the rest become the pinned list)
    function unpin(e) {
        Config.o.launcher.ringApps = apps.filter(a => a !== e).map(a => a.id);
        apps = apps.filter(a => a !== e);
    }

    LazyLoader {
        active: ring.alive
        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === ring.output) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "yoru-ring"
            WlrLayershell.keyboardFocus: ring.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property int n: Math.max(1, ring.apps.length)
            readonly property real outer: 236
            readonly property real inner: 132
            readonly property real mid: (outer + inner) / 2
            readonly property real step: 360 / n
            property real cx: width / 2
            property real cy: height / 2
            property bool placed: false
            property int sel: -1
            property real t: 0                  // 0 closed … 1 open
            readonly property bool morph: ring.morph
            function clamp01(x) { return Math.max(0, Math.min(1, x)); }
            function outCubic(x) { return 1 - Math.pow(1 - x, 3); }
            function inOutCubic(x) { return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2; }
            function lerp(a, b, k) { return a + (b - a) * k; }
            // the morph: a copy of the pill appears on the island, then travels and
            // swells, then the hole opens, then the apps come out
            readonly property real m: morph ? inOutCubic(clamp01((t - 0.06) / 0.52)) : 1
            readonly property real hole: morph ? outCubic(clamp01((t - 0.28) / 0.4)) : 1
            readonly property real appsT: morph ? clamp01((t - 0.42) / 0.58) : t
            // the island comes back as the ring nears it again
            onTChanged: if (!ring.shown && morph && t < 0.25 && ring.isle) ring.isle.away = ""

            // where it opens: at the pointer (kept whole on the screen), hanging just under
            // the island, or in the middle
            function place(x, y) {
                if (placed) return;
                placed = true;
                const at = Config.o.launcher.ringAt;
                const m = outer + 20;
                // the screen's size: the window may not have grown to it yet
                const w = screen?.width ?? width, h = screen?.height ?? height;
                if (at === "pointer") {
                    cx = Math.max(m, Math.min(w - m, x));
                    cy = Math.max(m, Math.min(h - m, y));
                } else if (at === "island") {
                    const p = ring.isle?.pills?.[ring.output];
                    const shown = p && !p.gone;
                    cx = shown ? Math.max(m, Math.min(w - m, p.x + p.w / 2)) : w / 2;
                    cy = (shown ? p.y + p.h : 0) + 14 + outer;
                } else {
                    cx = w / 2;
                    cy = h / 2;
                }
                grow.start();
            }
            // a pie menu: the direction from the middle picks, past a small dead zone
            function aim(x, y) {
                const dx = x - cx, dy = y - cy;
                if (Math.hypot(dx, dy) < inner * 0.4) { sel = -1; return; }
                const deg = Math.atan2(dy, dx) * 180 / Math.PI + 90;
                sel = ((Math.round(deg / step) % n) + n) % n;
            }
            function spot(i) {
                const a = (-90 + i * step) * Math.PI / 180;
                return Qt.point(Math.cos(a), Math.sin(a));
            }
            function backOut(x) { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2); }

            // the pointer may not move before it's wanted: open in the middle after a moment
            // (the other places don't wait for it)
            Timer {
                interval: Config.o.launcher.ringAt === "pointer" ? 90 : 0
                running: true
                onTriggered: win.place(win.width / 2, win.height / 2)
            }
            NumberAnimation { id: grow; target: win; property: "t"; to: 1; duration: win.morph ? Theme.slow * 1.15 : Theme.normal * 1.2 }
            NumberAnimation {
                id: shrink; target: win; property: "t"; to: 0; duration: win.morph ? Theme.normal * 1.2 : Theme.fast * 0.8
                onFinished: ring.alive = false
            }
            Connections {
                target: ring
                function onShownChanged() { if (!ring.shown) { grow.stop(); shrink.start(); } }
            }

            // a light veil, so the ring reads over any wallpaper
            Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.surfaceLowest, 0.28 * Math.min(1, win.t * 2)) }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onContainsMouseChanged: if (containsMouse) win.place(mouseX, mouseY)
                onPositionChanged: m => { win.place(m.x, m.y); win.aim(m.x, m.y); }
                onClicked: m => {
                    const d = Math.hypot(m.x - win.cx, m.y - win.cy);
                    if (d > win.outer + 30 || win.sel < 0) { ring.close(); return; }
                    if (m.button === Qt.RightButton) ring.unpin(ring.apps[win.sel]);
                    else ring.pick(ring.apps[win.sel]);
                }
            }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    const n = ring.apps.length;
                    const typing = ring.query !== "";
                    // a new search starts on its best match
                    const find = text => { ring.search(text); win.sel = ring.apps.length > 0 && text.trim() !== "" ? 0 : -1; };
                    if (e.key === Qt.Key_Escape) {
                        if (typing) find("");           // the first Esc clears the search
                        else ring.close();
                    } else if (e.key === Qt.Key_Backspace) {
                        if (typing) find(e.modifiers & Qt.ControlModifier ? "" : ring.query.slice(0, -1));
                    } else if (n > 0 && (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab))
                        win.sel = win.sel < 0 ? 0 : (win.sel + 1) % n;
                    else if (n > 0 && (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab))
                        win.sel = win.sel < 0 ? n - 1 : (win.sel - 1 + n) % n;
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        if (n > 0) ring.pick(ring.apps[Math.max(0, win.sel)]);
                        else if (typing) ring.handOver();   // nothing here: the list may know (web, maths)
                    } else if (!typing && e.key >= Qt.Key_1 && e.key <= Qt.Key_9 && e.key - Qt.Key_1 < n)
                        ring.pick(ring.apps[e.key - Qt.Key_1]);
                    else if (e.text.length === 1 && (e.text.trim() !== "" || (e.text === " " && typing))) {
                        if (e.modifiers & Qt.ControlModifier) return;
                        const next = ring.query + e.text;
                        // the list's own modes: emoji, the web, a command, maths
                        if (!typing && ":?>=".includes(e.text)) { ring.query = next; ring.handOver(); }
                        else find(next);
                    } else return;
                    e.accepted = true;
                }
            }

            // the island on its way: its pill becoming the band, travelling as it swells
            Shape {
                id: travel
                visible: win.morph
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: win.clamp01(win.t / 0.06)
                readonly property var f: ring.from ?? { x: win.cx, y: win.cy, w: 0, h: 0, r: 0 }
                readonly property real bw: win.lerp(f.w, win.outer * 2, win.m)
                readonly property real bh: win.lerp(f.h, win.outer * 2, win.m)
                readonly property real bx: win.lerp(f.x + f.w / 2, win.cx, win.m) - bw / 2
                readonly property real by: win.lerp(f.y + f.h / 2, win.cy, win.m) - bh / 2
                // the hole stays inside the shape: drawn outside it, even-odd would fill it in
                readonly property real reach: Math.min(bw, bh) / 2 - Math.hypot(bx + bw / 2 - win.cx, by + bh / 2 - win.cy) - 2
                readonly property real hr: Math.max(0, Math.min(win.inner * win.hole, reach))
                ShapePath {
                    fillRule: ShapePath.OddEvenFill
                    fillColor: Theme.alpha(Theme.island, 1 - 0.08 * win.m)
                    strokeColor: Theme.alpha(Theme.outlineVariant, 0.45)
                    strokeWidth: 1
                    PathRectangle { x: travel.bx; y: travel.by; width: travel.bw; height: travel.bh; radius: Math.min(win.lerp(travel.f.r, win.outer, win.m), travel.bw / 2, travel.bh / 2) }
                    PathRectangle { x: win.cx - travel.hr; y: win.cy - travel.hr; width: Math.max(0.01, travel.hr * 2); height: Math.max(0.01, travel.hr * 2); radius: travel.hr }
                }
            }

            // the ring itself
            Item {
                id: disc
                x: win.cx - win.outer; y: win.cy - win.outer
                width: win.outer * 2; height: win.outer * 2
                readonly property real ease: 1 - Math.pow(1 - Math.min(1, win.t * 1.6), 3)
                opacity: win.morph ? 1 : ease
                scale: win.morph ? 1 : 0.86 + 0.14 * ease

                // a soft edge outside the band, like a shadow (once a morph has arrived)
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: win.morph ? win.clamp01((win.m - 0.85) / 0.15) * win.hole : 1
                    ShapePath {
                        strokeColor: Qt.rgba(0, 0, 0, 0.22); strokeWidth: win.outer - win.inner + 22
                        fillColor: "transparent"; capStyle: ShapePath.FlatCap
                        PathAngleArc { centerX: win.outer; centerY: win.outer; radiusX: win.mid; radiusY: win.mid; startAngle: 0; sweepAngle: 360 }
                    }
                }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    visible: !win.morph             // the morph's own shape is the band then
                    // the band: the island's dark glass
                    ShapePath {
                        strokeColor: Theme.alpha(Theme.island, 0.92); strokeWidth: win.outer - win.inner
                        fillColor: "transparent"; capStyle: ShapePath.FlatCap
                        PathAngleArc { centerX: win.outer; centerY: win.outer; radiusX: win.mid; radiusY: win.mid; startAngle: 0; sweepAngle: 360 }
                    }
                    // hairlines on both edges catch the light
                    ShapePath {
                        strokeColor: Theme.alpha(Theme.ink, 0.1); strokeWidth: 1; fillColor: "transparent"
                        PathAngleArc { centerX: win.outer; centerY: win.outer; radiusX: win.outer - 0.5; radiusY: win.outer - 0.5; startAngle: 0; sweepAngle: 360 }
                    }
                    ShapePath {
                        strokeColor: Theme.alpha(Theme.ink, 0.07); strokeWidth: 1; fillColor: "transparent"
                        PathAngleArc { centerX: win.outer; centerY: win.outer; radiusX: win.inner + 0.5; radiusY: win.inner + 0.5; startAngle: 0; sweepAngle: 360 }
                    }
                }

                // the highlight: a pill of light sliding round to the chosen app
                Item {
                    anchors.fill: parent
                    visible: win.sel >= 0 && win.sel < ring.apps.length
                    opacity: win.appsT
                    rotation: win.sel * win.step
                    Behavior on rotation { RotationAnimation { direction: RotationAnimation.Shortest; duration: Theme.fast; easing.type: Easing.OutCubic } }
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Theme.alpha(Theme.primary, 0.2); strokeWidth: win.outer - win.inner - 18
                            fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: win.outer; centerY: win.outer; radiusX: win.mid; radiusY: win.mid
                                startAngle: -90 - Math.min(win.step * 0.5 - 6, 22) + 6
                                sweepAngle: 2 * (Math.min(win.step * 0.5 - 6, 22) - 6)
                            }
                        }
                    }
                }

                // the apps
                Repeater {
                    model: ring.apps
                    Item {
                        id: slot
                        required property var modelData
                        required property int index
                        readonly property bool on: win.sel === index
                        readonly property var wins: Apps.windowsOf(modelData)
                        readonly property bool focused: wins.some(w => w.focused)
                        // each flies out a beat after the one before
                        readonly property real k: Math.max(0, Math.min(1, win.appsT * (1 + win.n * 0.045) - index * 0.045))
                        readonly property real r: win.mid * (0.35 + 0.65 * win.backOut(k))
                        readonly property point dir: win.spot(index)
                        width: 64; height: 64
                        x: win.outer + dir.x * r - width / 2
                        y: win.outer + dir.y * r - height / 2
                        opacity: k

                        // the glow: the icon blurred into a halo of its own colours, behind it
                        MultiEffect {
                            visible: Config.o.launcher.ringGlow
                            source: icon
                            anchors.fill: icon
                            autoPaddingEnabled: true
                            blurEnabled: true; blurMax: 40; blur: 1
                            // 0 → 1 as it's pointed at: brighter, wider, stronger
                            property real lit: slot.on ? 1 : 0
                            Behavior on lit { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                            saturation: 0.35; brightness: 0.1 + 0.15 * lit
                            scale: icon.scale * (1.22 + 0.13 * lit)
                            opacity: 0.75 + 0.25 * lit
                        }
                        IconImage {
                            id: icon
                            anchors.centerIn: parent
                            implicitSize: 52
                            source: Quickshell.iconPath(slot.modelData.icon, "application-x-executable")
                            scale: slot.on ? 1.2 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        }
                        // open: a dot toward the middle; the focused one stretches into a pill
                        Rectangle {
                            visible: slot.wins.length > 0
                            width: slot.focused ? 16 : 6; height: 6; radius: 3
                            color: slot.focused ? Theme.primary : Theme.alpha(Theme.ink, 0.75)
                            x: slot.width / 2 - width / 2 - slot.dir.x * 36
                            y: slot.height / 2 - height / 2 - slot.dir.y * 36
                            Behavior on width { NumberAnimation { duration: Theme.fast } }
                        }
                    }
                }

                // the middle: what's chosen, or the time
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    opacity: win.appsT
                    readonly property var e: win.sel >= 0 ? ring.apps[win.sel] ?? null : null
                    readonly property int count: e ? Apps.windowsOf(e).length : 0
                    // what you've typed, with a caret
                    Rectangle {
                        visible: ring.query !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(win.inner * 1.5, typedText.implicitWidth + 28); height: 30
                        radius: height / 2
                        color: Theme.alpha(Theme.primary, 0.16)
                        border.width: 1; border.color: Theme.alpha(Theme.primary, 0.35)
                        Txt {
                            id: typedText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width - 20)
                            elide: Text.ElideLeft
                            text: ring.query + "▏"
                            size: 15; weight: Font.Medium
                            color: Theme.ink
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, win.inner * 1.6)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: parent.e !== null || ring.query === ""
                        text: parent.e ? parent.e.name : Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm")
                        size: parent.e ? 20 : 30
                        weight: Font.DemiBold
                        color: Theme.ink
                        style: Text.Outline; styleColor: Theme.alpha(Theme.surfaceLowest, 0.35)
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.e ? (parent.count > 1 ? parent.count + " windows · brings the last" : parent.count === 1 ? "open · brings it back" : "opens it")
                                       : ring.query !== "" ? (ring.apps.length ? "point, or Enter" : "no app · Enter searches the list")
                                       : "point, or type to search"
                        size: 12
                        color: Theme.inkDim
                        style: Text.Outline; styleColor: Theme.alpha(Theme.surfaceLowest, 0.35)
                    }
                }
            }
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }
    }
}
