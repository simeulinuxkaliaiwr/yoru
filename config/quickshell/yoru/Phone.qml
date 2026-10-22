import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.parts
import qs.phone
import "phone/actions.js" as Actions

// the phone (mod+y): your apps, quick settings, the day and the music on pages that slide
// sideways, in a device that drops out of the island (or rises from the bottom of the screen,
// or fades in). Bodies (phone.skin): slab, a glass smartphone; flip, a folding keitai whose
// keypad works; bare, the screen alone. It leans toward the pointer until you use it.
// Keys: Tab and Shift+Tab walk the pages (the arrows too, until you're in the apps); typing
// searches your apps from any page; Enter opens; Esc backs out of a panel, clears the search,
// then puts it away. IPC `phone toggle | open PAGE | close`, PAGE one of home, control, today,
// music, wifi, bluetooth
Scope {
    id: phone
    property var isle: null                 // the Island: to grow out of, and to hand over to
    property bool shown: false
    property bool alive: false              // still drawing: open, or on its way out
    property string output: ""
    property string page: "home"
    property string panel: ""               // over the pages: wifi or bluetooth
    property string hint: ""                // what the flip's key under the pointer does
    property var from: null                 // the island's pill on its screen: { x, y, w, h, r }
    property bool morph: false
    property var later: []                  // for once it's gone: a screenshot mustn't catch it
    readonly property var c: Config.o.phone
    readonly property var pages: {
        const p = (c.pages ?? []).filter((x, i, a) => Actions.pages.includes(x) && a.indexOf(x) === i);
        return p.length > 0 ? p : ["home"];
    }
    // for the flip's lid, which can't reach for these itself (the settings' preview has no phone)
    readonly property int unseen: Notifs.unseen
    readonly property bool playing: Media.playing
    signal keyed(string name)               // a key went down: the flip presses its own

    function toggle() { shown ? close() : open(""); }
    // where: a page or a panel to open on; "" for the settings' choice
    function open(where) {
        if (shown) { go(where); return; }
        output = Wm.focusedOutput || (Quickshell.screens[0]?.name ?? "");
        const p = isle?.pills?.[output];
        morph = c.from === "island" && !!p && !p.gone;
        from = morph ? p : null;
        if (morph) { isle.awayQuick = true; isle.away = output; }
        hint = "";
        go(where !== "" ? where : c.start === "last" ? page : c.start);
        alive = true;
        shown = true;
    }
    function go(where) {
        if (where === "wifi" || where === "bluetooth") {
            if (pages.includes("control")) page = "control";
            panel = where;
            return;
        }
        panel = "";
        if (pages.includes(where)) page = where;
        else if (!pages.includes(page)) page = pages[0];
    }
    function close() {
        // folds back into wherever the island is now
        const p = isle?.pills?.[output];
        if (morph && p && !p.gone) from = p;
        shown = false;
    }
    function afterwards(f) {
        later = later.concat([f]);
        close();
    }
    // a search that isn't for an app: the island's list does the web, maths, emoji, commands
    function handOver(text) { afterwards(() => isle?.search(text)); }
    onAliveChanged: if (!alive) {
        if (isle) {
            if (isle.away === output) isle.away = "";
            isle.awayQuick = false;
        }
        const l = later;
        later = [];
        for (const f of l) f();
    }

    // the tiles and the keys: whether each is on, a line about it, its icon, and doing it
    function isOn(id) {
        switch (id) {
        case "wifi": return Status.wifiOn && (Status.signal >= 0 || Status.ethernet);
        case "bluetooth": return Status.btOn;
        case "night": return Status.night;
        case "caffeine": return Status.caffeine;
        case "dnd": return Notifs.dnd;
        case "focus": return Focus.active;
        case "record": return Recorder.active;
        case "mic": return !Audio.micMuted;
        case "music": return Media.playing;
        }
        return false;
    }
    function about(id) {
        switch (id) {
        case "wifi": return Status.netName;
        case "bluetooth": return Status.btWanted ? "Turning on…" : !Status.btOn ? "Off" : Status.btConnected.length > 0 ? Status.btConnected[0].name : "On";
        case "night": return Status.night ? "4000K" : "Off";
        case "caffeine": return Status.caffeine ? "Awake" : "Off";
        case "dnd": return !Notifs.dnd ? "Off" : Notifs.quietHours ? "Quiet hours" : Focus.active && !Notifs.manualDnd ? "Focusing" : "On";
        case "focus": return Focus.active ? (Focus.phase === "break" ? "Break " : "") + Focus.clock(Focus.left) : Config.o.focus.minutes + " min";
        case "record": return Recorder.active ? Focus.clock(Recorder.seconds) : "The screen";
        case "mic": return Audio.micMuted ? "Muted" : "On";
        case "music": return Media.playing ? Media.title : Media.player ? "Paused" : "Nothing";
        }
        return "";
    }
    function icon(id) {
        switch (id) {
        case "wifi": return Status.netIcon;
        case "bluetooth": return !Status.btOn ? "bluetooth_disabled" : Status.btConnected.length > 0 ? "bluetooth_connected" : "bluetooth";
        case "dnd": return Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off";
        case "focus": return Focus.phase === "break" ? "self_improvement" : "timer";
        case "mic": return Audio.micMuted ? "mic_off" : "mic";
        case "music": return Media.playing ? "pause" : "play_arrow";
        }
        return Actions.icon(id);
    }
    function run(id) {
        switch (id) {
        case "wifi": Status.toggleWifi(); break;
        case "bluetooth": Status.toggleBt(); break;
        case "night": Status.night = !Status.night; break;
        case "caffeine": Status.caffeine = !Status.caffeine; break;
        case "dnd": Notifs.toggleDnd(); break;
        case "focus": Focus.toggle(); break;
        case "mic": Audio.toggleMic(); break;
        case "music": Media.toggle(); break;
        case "next": Quickshell.execDetached(["yoru", "wall", "next"]); break;
        // these want the screen to themselves
        case "record":
            if (Recorder.active) Recorder.stop();
            else afterwards(() => Recorder.toggle(""));
            break;
        case "screenshot": afterwards(() => Quickshell.execDetached(["yoru-shot", "area"])); break;
        case "picker": afterwards(() => Picker.pick()); break;
        case "lock": afterwards(() => Quickshell.execDetached(["yoru-lock"])); break;
        case "wallpaper": afterwards(() => isle?.open("walls", output)); break;
        case "power": afterwards(() => isle?.open("power", output)); break;
        case "settings": afterwards(() => Quickshell.execDetached(["qs", "-n", "-p", Quickshell.shellDir + "/settings.qml"])); break;
        }
    }
    // the flip's keypad: 1–9 as the settings say, * mutes, 0 goes home, # locks
    function keypad(k) {
        keyed(k);
        if (/^[1-9]$/.test(k)) run(c.keys[+k - 1] ?? "");
        else if (k === "*") Audio.toggleMute();
        else if (k === "0") go(pages[0]);
        else if (k === "#") run("lock");
    }

    LazyLoader {
        active: phone.alive
        PanelWindow {
            id: win
            readonly property var device: phone
            screen: Quickshell.screens.find(s => s.name === phone.output) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "yoru-phone"
            WlrLayershell.keyboardFocus: phone.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property real t: 0                  // 0 gone … 1 in your hand
            readonly property string how: phone.morph ? "island" : phone.c.from === "fade" ? "fade" : "rise"
            // the screen's size: the window may not have grown to it yet
            readonly property real sw: screen?.width ?? width
            readonly property real sh: screen?.height ?? height
            readonly property Item body: bodyLoader.item
            readonly property real nw: body ? body.implicitWidth : 376
            readonly property real nh: body ? body.implicitHeight : 784
            readonly property real span: body?.span ?? 1      // how long the body takes to arrive
            // its size: natural, times the setting, never off the screen nor up under the island
            readonly property real k: Math.max(0.4, Math.min(Math.max(0.6, Math.min(1.4, phone.c.size)), (sh - 46 - 40) / nh, (sw - 48) / nw))
            readonly property real pw: nw * k
            readonly property real ph: nh * k
            readonly property real px: phone.c.side === "left" ? 44 : phone.c.side === "center" ? (sw - pw) / 2 : sw - 44 - pw
            readonly property real py: Math.max(46 + 14, (sh - ph) / 2 + 22)
            // where the island lands: the phone as it arrives (the flip shut)
            readonly property var landing: {
                const l = body ? body.landing : { x: 0, y: 0, w: nw, h: nh, r: 40 };
                return { x: px + l.x * k, y: py + l.y * k, w: l.w * k, h: l.h * k, r: l.r * k };
            }

            function clamp01(x) { return Math.max(0, Math.min(1, x)); }
            function inOutCubic(x) { return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2; }
            function outCubic(x) { return 1 - Math.pow(1 - x, 3); }
            function backOut(x, s) { const c = s + 1; return 1 + c * Math.pow(x - 1, 3) + s * Math.pow(x - 1, 2); }
            function lerp(a, b, f) { return a + (b - a) * f; }
            // the stages: the island travelling and swelling; the phone appearing over it as it
            // arrives; or the phone coming up from the bottom of the screen
            readonly property real m: how === "island" ? inOutCubic(clamp01(t / 0.55)) : 1
            readonly property real bodyIn: how === "island" ? clamp01((t - 0.44) / 0.18)
                                         : how === "fade" ? outCubic(clamp01(t / 0.55)) : clamp01(t / 0.1)
            readonly property real rise: how === "rise" ? backOut(clamp01(t / 0.7), 1.1) : 1

            NumberAnimation {
                id: grow; target: win; property: "t"; to: 1; duration: Theme.slow * (win.how === "fade" ? 0.8 : 1.45) * win.span
                // landed: the island comes back, for its notifications and the volume; going, the
                // phone flies back into it
                onFinished: if (phone.isle && phone.isle.away === phone.output) { phone.isle.awayQuick = false; phone.isle.away = ""; }
            }
            NumberAnimation { id: shrink; target: win; property: "t"; to: 0; duration: Theme.normal * (win.how === "fade" ? 0.6 : 1.1) * win.span; onFinished: phone.alive = false }
            Component.onCompleted: grow.start()
            Connections {
                target: phone
                function onShownChanged() {
                    if (phone.shown) { shrink.stop(); grow.start(); }
                    else { grow.stop(); shrink.start(); }
                }
            }
            // put away before it landed: the island comes back as the phone nears it
            onTChanged: if (!phone.shown && how === "island" && t < 0.22 && phone.isle) phone.isle.away = ""

            // a light veil, so it reads over any wallpaper; a click on it puts the phone away
            Rectangle {
                anchors.fill: parent
                visible: phone.c.dim
                color: Theme.alpha(Theme.surfaceLowest, 0.32 * win.clamp01(win.t * 1.8))
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: phone.close()
            }

            // the island on its way: its pill travelling and swelling into the phone
            Rectangle {
                visible: win.how === "island" && opacity > 0.001
                readonly property var f: phone.from ?? win.landing
                x: win.lerp(f.x, win.landing.x, win.m)
                y: win.lerp(f.y, win.landing.y, win.m)
                width: win.lerp(f.w, win.landing.w, win.m)
                height: win.lerp(f.h, win.landing.h, win.m)
                radius: Math.min(win.lerp(f.r, win.landing.r, win.m), width / 2, height / 2)
                color: Theme.island
                border.width: Theme.border > 0 ? Theme.border : 1
                border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.outlineVariant, 0.45)
                opacity: 1 - win.clamp01((win.t - 0.58) / 0.14)
            }

            // it leans toward the pointer, and holds still while the pointer's on it
            HoverHandler { id: hover }
            readonly property point at: hover.point.position
            readonly property bool over: at.x >= px && at.x <= px + pw && at.y >= py && at.y <= py + ph
            readonly property bool leaning: phone.c.tilt && phone.shown && hover.hovered && !over && t >= 1
            property real tiltY: leaning ? Math.max(-1, Math.min(1, (at.x - (px + pw / 2)) / (sw / 2))) * 9 : 0
            property real tiltX: leaning ? -Math.max(-1, Math.min(1, (at.y - (py + ph / 2)) / (sh / 2))) * 7 : 0
            Behavior on tiltY { SmoothedAnimation { velocity: 18 } }
            Behavior on tiltX { SmoothedAnimation { velocity: 14 } }

            FocusScope {
                anchors.fill: parent
                focus: true
                Item {
                    id: stage
                    width: win.nw
                    height: win.nh
                    // scaled about its middle: placed so its scaled edges land on px, py
                    x: win.px - win.nw * (1 - win.k) / 2
                    y: win.py - win.nh * (1 - win.k) / 2 + (1 - win.rise) * (win.sh - win.py + 80)
                    scale: win.k * (win.how === "fade" ? 0.92 + 0.08 * win.bodyIn : 1)
                    opacity: win.bodyIn
                    // fading as one: each part on its own would show the ones under it through it
                    layer.enabled: opacity < 1
                    layer.smooth: true
                    rotation: (1 - win.rise) * (phone.c.side === "left" ? -9 : 9)
                    transform: [
                        Rotation { origin.x: stage.width / 2; origin.y: stage.height / 2; axis { x: 0; y: 1; z: 0 } angle: win.tiltY },
                        Rotation { origin.x: stage.width / 2; origin.y: stage.height / 2; axis { x: 1; y: 0; z: 0 } angle: win.tiltX }
                    ]
                    // clicks on the phone stay on it
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                    Loader {
                        id: bodyLoader
                        anchors.fill: parent
                        focus: true
                        sourceComponent: ({ slab: slabC, flip: flipC, bare: bareC })[phone.c.skin] ?? slabC
                    }
                }
            }
            Component { id: displayC; Display { phone: win.device } }
            Component { id: slabC; SlabBody { phone: win.device; screen: displayC; t: win.t } }
            Component { id: flipC; FlipBody { phone: win.device; screen: displayC; t: win.t } }
            Component { id: bareC; BareBody { phone: win.device; screen: displayC; t: win.t } }
        }
    }
}
