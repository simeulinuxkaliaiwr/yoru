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
