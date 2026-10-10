import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia

// the wallpaper, drawn by the shell so it can move: it drifts with the
// workspaces (parallax), plays videos (paused while windows cover it), and a
// new one ripples out of the island instead of just appearing
Scope {
    id: root

    readonly property var names: ["ripple", "fade", "wipe", "disc", "stripes", "zoom", "honeycomb", "pixelate"]

    // the next transition: its kind, where it starts and which way it runs.
    // Every screen uses the same one, so a change looks like one event.
    property int mode: 0
    property point origin: Qt.point(0.5, 0.0)
    property real angle: 0
    property real seed: 0
    // `qs -c yoru ipc call wallpaper preview FILE wipe` shows FILE with that
    // transition without touching the palette: for trying transitions out
    property string preview: ""
    property string forced: ""
    function show(file, transition) {
        forced = transition;
        preview = file;
    }

    function roll() {
        const w = Config.o.wallpaper;
        let name = forced !== "" ? forced : w.transition;
        forced = "";
        if (name === "random" || !names.includes(name)) {
            const pool = w.pool.filter(n => names.includes(n));
            name = pool.length ? pool[Math.floor(Math.random() * pool.length)] : "fade";
        }
        mode = names.indexOf(name);
        // the ripple comes out of the island; a disc or honeycomb from anywhere
        origin = name === "ripple" ? Qt.point(0.5, 0.0) : Qt.point(0.15 + Math.random() * 0.7, 0.15 + Math.random() * 0.7);
        angle = Math.floor(Math.random() * 8) * Math.PI / 4 + (name === "stripes" ? Math.PI / 8 : 0);
        seed = Math.random() * 100;
    }
    onWallChanged: roll()
    readonly property string wall: preview !== "" ? preview : Theme.wallpaper

    // the sky: weather drawn over the wallpaper (shaders/sky.frag). The kinds,
    // in the shader's order; "" is none
    readonly property var skies: ["", "snow", "rain", "aurora", "fog", "storm"]
    property string trySky: ""          // from IPC, for trying one out
    onTrySkyChanged: if (trySky !== "") tryEnd.restart()
    Timer { id: tryEnd; interval: 120000; onTriggered: root.trySky = "" }
    // what the weather outside looks like, from its WMO code
    function outside() {
        if (!Weather.ready) return "";
        const c = Weather.code;
        // a clear night: an aurora (over a bright picture it brings its own dark sky)
        if (c <= 1) return Weather.day ? "" : "aurora";
        if (c === 45 || c === 48) return "fog";
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
        if (c >= 95) return "storm";
        return "";
    }
    readonly property string skyWant: {
        if (trySky !== "") return trySky;
        const s = Config.o.wallpaper.sky;
        return s === "weather" ? outside() : skies.includes(s) ? s : "";
    }
    // drizzle and showers are lighter, heavy rain and snow heavier
    readonly property real skyAmount: {
        let a = Config.o.wallpaper.skyAmount;
        if (trySky === "" && Config.o.wallpaper.sky === "weather") {
            const c = Weather.code;
            if ([51, 53, 56, 61, 71, 80, 85].includes(c)) a *= 0.6;
            else if ([55, 57, 65, 67, 75, 82, 86].includes(c)) a = Math.min(1, a * 1.35);
        }
        return a;
    }
    // the wind slants rain and snow; a breeze when it isn't the real weather
    readonly property real skyWind: trySky === "" && Config.o.wallpaper.sky === "weather"
        ? Math.min(0.8, Weather.wind * (Weather.fahrenheit ? 1.609 : 1) / 50) : 0.2
    // one kind fades out before the next fades in
    property int sky: 0
    property real skyFade: 0
    onSkyWantChanged: skySwap.restart()
    Component.onCompleted: skySwap.restart()
    SequentialAnimation {
        id: skySwap
        NumberAnimation { target: root; property: "skyFade"; to: 0; duration: root.sky > 0 ? 1500 : 0; easing.type: Easing.InOutSine }
        ScriptAction { script: root.sky = Math.max(0, root.skies.indexOf(root.skyWant)) }
        NumberAnimation { target: root; property: "skyFade"; to: 1; duration: 3000; easing.type: Easing.InOutSine }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            color: Theme.surfaceLowest
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "yoru-wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            property int front: 0
            property bool moving: false
            readonly property var slots: [slotA, slotB]
            readonly property string wanted: root.wall

            // parallax: one screen-height's worth of travel split across the workspaces
            readonly property int extra: Config.o.wallpaper.parallax ? Math.round(height * 0.07) : 0
            readonly property var ws: Aro.wsFor(modelData.name)
            readonly property int count: Math.max(2, ...ws.map(w => w.index))
            readonly property int cur: Aro.current(modelData.name)
            readonly property bool covered: Config.o.wallpaper.pauseCovered && (Aro.busy(modelData.name) || Aro.fullscreen(modelData.name))

            onWantedChanged: show(wanted)
            Component.onCompleted: show(wanted)

            function show(file) {
                if (file === "") return;
                const f = slots[front], b = slots[1 - front];
                if (f.file === "") { f.load(file); firstIn.start(); return; }
                if (f.file === file && !moving) return;
                b.load(file);
                waitReady.restart();
            }

            // the very first picture fades up out of the dark instead of popping in
            property bool awake: false
            Timer {
                id: firstIn
                interval: 16; repeat: true
                property int tries: 0
                onTriggered: if (win.slots[win.front].ready || ++tries > 120) { stop(); win.awake = true; }
            }

            Timer {
                id: waitReady
                interval: 16; repeat: true
                property int tries: 0
                onTriggered: {
                    const b = win.slots[1 - win.front];
                    if (b.ready || ++tries > 120) { stop(); tries = 0; reveal.restart(); }
                }
            }

            SequentialAnimation {
                id: reveal
                ScriptAction { script: { shader.progress = 0; win.moving = true; } }
                NumberAnimation {
                    target: shader; property: "progress"; from: 0; to: 1
                    duration: Config.o.wallpaper.duration * Theme.pace
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized
                }
                ScriptAction {
                    script: {
                        win.moving = false;
                        win.slots[win.front].unload();
                        win.front = 1 - win.front;
                    }
                }
            }

            Item {
                id: plane
                width: parent.width
                height: parent.height + win.extra
                y: -win.extra * (win.cur - 1) / (win.count - 1)
                opacity: win.awake ? 1 : 0
                scale: win.awake ? 1 : 1.04
                Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 1600; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on y { NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

                component Slot: Item {
                    id: slot
                    property string file: ""
                    readonly property bool isVideo: /\.(mp4|webm|mkv|mov|gif)$/i.test(file)
                    readonly property bool ready: isVideo ? (vid.item?.playbackState === MediaPlayer.PlayingState || vid.item?.hasVideo === true)
                                                          : img.status === Image.Ready
                    function load(f) { file = f; }
                    function unload() { file = ""; }
                    anchors.fill: parent

                    Image {
                        id: img
                        anchors.fill: parent
                        visible: !slot.isVideo
                        source: slot.file !== "" && !slot.isVideo ? "file://" + slot.file : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(width, height)
                        asynchronous: true
                        cache: false
                        smooth: true
                    }
                    Loader {
                        id: vid
                        anchors.fill: parent
                        active: slot.isVideo
                        sourceComponent: Video {
                            source: "file://" + slot.file
                            loops: MediaPlayer.Infinite
                            muted: true
                            fillMode: VideoOutput.PreserveAspectCrop
                            autoPlay: true
                            // a video under windows costs the blur a redraw every frame
                            readonly property bool wantPlay: !win.covered || win.moving
                            onWantPlayChanged: wantPlay ? play() : pause()
                            // tell the theme where the loop is, for its colours
                            Timer {
                                interval: 1000; repeat: true; triggeredOnStart: true
                                running: slot.z > 0 && Theme.videoOn && win.modelData === Quickshell.screens[0]
                                         && parent.playbackState === MediaPlayer.PlayingState
                                onTriggered: Theme.videoPos = parent.position / 1000
                            }
                        }
                    }
                }

                // the front one covers the other, so the next can load unseen underneath
                Slot { id: slotA; z: win.front === 0 ? 1 : 0 }
                Slot { id: slotB; z: win.front === 1 ? 1 : 0 }

                ShaderEffect {
                    id: shader
                    anchors.fill: parent
                    z: 2
                    visible: win.moving
                    property real progress: 0
                    property real aspect: width / height
                    property point origin: Qt.point(root.origin.x, (root.origin.y * win.height - plane.y) / plane.height)
                    property real mode: root.mode
                    property real smoothness: Config.o.wallpaper.smoothness
                    property real angle: root.angle
                    property real seed: root.seed
                    property variant from: ShaderEffectSource { sourceItem: win.slots[win.front]; hideSource: win.moving; live: true }
                    property variant to: ShaderEffectSource { sourceItem: win.slots[1 - win.front]; hideSource: win.moving; live: true }
                    fragmentShader: Qt.resolvedUrl("shaders/reveal.frag.qsb")
                }
            }

            // the sky over the picture, drawn at half size and 30 frames a second
            // (it's soft anyway; full size at 60 kept the GPU 30% busy), and
            // stopped under windows whatever the videos do
            Item {
                id: skyBox
                anchors.fill: parent
                visible: root.sky > 0 && root.skyFade > 0
                opacity: root.skyFade
                layer.enabled: visible
                layer.textureSize: Qt.size(Math.ceil(width / 2), Math.ceil(height / 2))
                layer.smooth: true
                readonly property bool hidden: Aro.busy(win.modelData.name) || Aro.fullscreen(win.modelData.name)
                // seconds since it started, from the clock, so a late tick doesn't slow it
                property real t0: Date.now()
                function deep(c: color): color { return Qt.hsla(c.hslHue, Math.max(c.hslSaturation, 0.75), 0.55, 1); }
                Timer {
                    interval: 33; repeat: true
                    running: skyBox.visible && (!skyBox.hidden || win.moving)
                    // wrapped well before a float loses the fractions of a second
                    onTriggered: skyFx.time = ((Date.now() - skyBox.t0) / 1000) % 20000
                }
                ShaderEffect {
                    id: skyFx
                    anchors.fill: parent
                    property real time: 0
                    property real aspect: width / height
                    property real kind: root.sky
                    property real amount: root.skyAmount
                    property real wind: root.skyWind
                    // bright pictures get a night sky behind the aurora; dark ones already are one
                    property real veil: Math.max(0, Math.min(1, (Theme.bright - 0.25) / 0.4))
                    property color tint: Qt.tint("#ffffff", Theme.alpha(Theme.primary, 0.18))
                    // the palette's colours, deepened: its light accents alone glow almost white
                    property color glowA: skyBox.deep(Theme.primary)
                    property color glowB: skyBox.deep(Theme.tertiary)
                    property color night: Theme.surfaceLowest
                    fragmentShader: Qt.resolvedUrl("shaders/sky.frag.qsb")
                }
            }

            // a little shade where the island and the clock sit
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 140
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.surfaceLowest, 0.45) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 320
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Theme.alpha(Theme.surfaceLowest, 0.55) }
                }
            }
        }
    }
}
