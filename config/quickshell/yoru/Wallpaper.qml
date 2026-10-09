import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia

// the wallpaper, drawn by the shell so it can move: it drifts with the
// workspaces (parallax), plays videos (paused while windows cover it), and a
// new one ripples out of the island instead of just appearing
Scope {
    id: root

    // where the next transition starts, in 0..1 of the screen; the picker sets it
    property point origin: Qt.point(0.5, 0.0)

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
            readonly property string wanted: Theme.wallpaper

            // parallax: one screen-height's worth of travel split across the workspaces
            readonly property int extra: Math.round(height * 0.07)
            readonly property var ws: Aro.wsFor(modelData.name)
            readonly property int count: Math.max(2, ...ws.map(w => w.index))
            readonly property int cur: Aro.current(modelData.name)
            readonly property bool covered: Aro.busy(modelData.name) || Aro.fullscreen(modelData.name)

            onWantedChanged: show(wanted)
            Component.onCompleted: show(wanted)

            function show(file) {
                if (file === "") return;
                const f = slots[front], b = slots[1 - front];
                if (f.file === "") { f.load(file); return; }
                if (f.file === file && !moving) return;
                b.load(file);
                waitReady.restart();
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
                    duration: 1500
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
