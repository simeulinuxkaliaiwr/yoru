import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import qs

// the music, drawn from cava's levels. Bars rise at once and fall slowly, and
// sink to nothing if cava goes quiet, so they never freeze mid-air.
//   bars · mirror · wave · dots · aurora · silk · glass
Item {
    id: vis
    property string style: "bars"
    readonly property int n: 64
    property var levels: new Array(n).fill(0)
    property real peak: 0.3
    // glass: where each bar's cap hangs, and how fast it's falling
    readonly property int glassN: 40
    property var caps: new Array(glassN).fill(0)
    property var capFall: new Array(glassN).fill(0)

    // a level between two of cava's bars, for styles with fewer of them
    function at(t) {
        const f = t * (n - 1), i = Math.floor(f), k = f - i;
        return (levels[i] ?? 0) * (1 - k) + (levels[Math.min(n - 1, i + 1)] ?? 0) * k;
    }
    // caps hang a moment at the top, then fall faster and faster
    function dropCaps() {
        const c = caps.slice(), f = capFall.slice();
        for (let i = 0; i < glassN; i++) {
            const v = at(i / (glassN - 1));
            if (v >= c[i]) { c[i] = v; f[i] = -0.012; }         // negative: still hanging
            else { f[i] += 0.0016; c[i] = Math.max(v, c[i] - Math.max(0, f[i])); }
        }
        capFall = f;
        caps = c;
    }

    Process {
        running: true
        command: Tied.cmd(["cava", "-p", Quickshell.shellDir + "/cava.conf"])
        stdout: SplitParser {
            onRead: line => {
                const raw = line.split(";");
                const r = new Array(vis.n);
                let top = 0;
                for (let i = 0; i < vis.n; i++) {
                    r[i] = Math.min(1, (parseInt(raw[i]) || 0) / 1000);
                    top = Math.max(top, r[i]);
                }
                // scale to a slowly falling peak: loud or quiet, the tallest bar
                // reaches near the top and the rest keep their proportions
                vis.peak = Math.max(top, vis.peak * 0.997);
                const out = new Array(vis.n);
                for (let i = 0; i < vis.n; i++) {
                    const v = 0.92 * Math.pow(r[i] / Math.max(vis.peak, 0.12), 1.5);
                    out[i] = Math.max(v, (vis.levels[i] ?? 0) * 0.88);  // rise at once, fall slowly
                }
                vis.levels = out;
                if (vis.style === "glass")
                    vis.dropCaps();
                stall.restart();
            }
        }
    }
    // no frame for a while: let everything settle down
    Timer {
        id: stall
        interval: 200; repeat: true
        onTriggered: {
            const out = vis.levels.map(v => v * 0.6);
            vis.levels = out;
            if (vis.style === "glass")
                vis.dropCaps();
            if (out.every(v => v < 0.01) && vis.caps.every(v => v < 0.01)) stop();
        }
    }

    readonly property real gap: style === "dots" ? 8 : 7
    readonly property real barW: Math.max(3, (width - (n - 1) * gap) / n)

    // only the chosen style exists: a hidden one would still update every frame
    Loader { anchors.fill: parent; active: vis.style === "bars" || vis.style === "dots"; sourceComponent: barsC }
    Loader { anchors.fill: parent; active: vis.style === "mirror"; sourceComponent: mirrorC }
    Loader { anchors.fill: parent; active: vis.style === "wave"; sourceComponent: waveC }
    Loader { anchors.fill: parent; active: vis.style === "aurora" || vis.style === "silk"; sourceComponent: lightC }
    Loader { anchors.fill: parent; active: vis.style === "glass"; sourceComponent: glassC }

    // bars, rising off the bottom
    Component { id: barsC; Item {
    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        spacing: vis.gap
        Repeater {
            model: vis.n
            Item {
                required property int index
                width: vis.barW
                height: vis.height
                // bars
                Rectangle {
                    visible: vis.style === "bars"
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(width, vis.levels[parent.index] * vis.height)
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha(Theme.tertiary, 0.9) }
                        GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0.15) }
                    }
                }
                // dots: a column of beads that light up
                Column {
                    visible: vis.style === "dots"
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    spacing: 5
                    Repeater {
                        model: vis.style === "dots" ? 9 : 0
                        Rectangle {
                            required property int index
                            readonly property bool lit: (8 - index) / 9 < vis.levels[parent.parent.index]
                            width: Math.min(vis.barW, 9); height: width; radius: width / 2
                            color: lit ? (index < 3 ? Theme.tertiary : Theme.primary) : Theme.alpha(Theme.ink, 0.08)
                        }
                    }
                }
            }
        }
    }

    } }

    // mirror: bars growing both ways from a line
    Component { id: mirrorC; Item {
    Row {
        anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
        spacing: vis.gap
        Repeater {
            model: vis.n
            Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: vis.barW
                height: Math.max(width, vis.levels[index] * vis.height * 0.9)
                radius: width / 2
                color: Theme.alpha(Theme.mix(Theme.primary, Theme.tertiary, index / vis.n), 0.75)
            }
        }
    }

    } }

    // wave: one smooth filled line
    Component { id: waveC; Item {
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 4
            strokeColor: Theme.alpha(Theme.tertiary, 0.9)
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: vis.height
                GradientStop { position: 0; color: Theme.alpha(Theme.primary, 0.45) }
                GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0.02) }
            }
            startX: 0; startY: vis.height
            PathLine { x: 0; y: vis.height - Math.min(1, vis.levels[0] * 1.4) * vis.height * 0.9 }
            PathPolyline {
                path: {
                    const pts = [];
                    const step = vis.width / (vis.n - 1);
                    for (let i = 0; i < vis.n; i++) {
                        // a soft average with the neighbours, so it reads as one line
                        const a = vis.levels[Math.max(0, i - 1)], b = vis.levels[i], c = vis.levels[Math.min(vis.n - 1, i + 1)];
                        pts.push(Qt.point(i * step, vis.height - Math.min(1, (a + 2 * b + c) / 4 * 1.4) * vis.height * 0.9));
                    }
                    return pts;
                }
            }
            PathLine { x: vis.width; y: vis.height }
        }
    }
    } }

    // aurora and silk: light, drawn by shaders/vis.frag from the levels as a 64x1 texture
    Component { id: lightC; Item {
        // one pixel per bar, red = height; the shader reads it with smooth filtering
        Row {
            id: strip
            Repeater {
                model: vis.n
                Rectangle { required property int index; width: 1; height: 1; color: Qt.rgba(vis.levels[index], 0, 0, 1) }
            }
        }
        ShaderEffect {
            anchors.fill: parent
            property real time: 0
            property real mode: vis.style === "silk" ? 1 : 0
            property real aspect: width / Math.max(1, height)
            property color c1: Theme.primary
            property color c2: Theme.tertiary
            property color c3: Theme.secondary
            property variant levels: ShaderEffectSource {
                sourceItem: strip; hideSource: true; live: true; smooth: true
                textureSize: Qt.size(vis.n, 1)
            }
            fragmentShader: Qt.resolvedUrl("../shaders/vis.frag.qsb")
            // slow drift for the rays and ribbons; wraps long after anyone notices
            NumberAnimation on time { from: 0; to: 3600; duration: 3600000; loops: Animation.Infinite }
        }
    } }

    // glass: glossy capsules standing on a horizon, their reflections under it, caps that hang and fall
    Component { id: glassC; Item {
        id: gl
        readonly property real gap: 12
        readonly property real w: Math.max(6, (width - (vis.glassN - 1) * gap) / vis.glassN)
        readonly property real horizon: height * 0.76
        readonly property real tall: horizon - 10           // room for the cap above the tallest bar
        readonly property color white: Qt.rgba(1, 1, 1, 1)  // Theme's helpers want a colour, not a string

        // the horizon: a thread of light, fading out at both ends
        Rectangle {
            x: 0; y: gl.horizon; width: gl.width; height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.ink, 0.22) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Repeater {
            model: vis.glassN
            Item {
                id: col
                required property int index
                readonly property real lv: vis.at(index / (vis.glassN - 1))
                readonly property real h: Math.max(gl.w * 0.5, lv * gl.tall)
                readonly property color tint: Theme.mix(Theme.primary, Theme.tertiary, index / (vis.glassN - 1))
                x: index * (gl.w + gl.gap); width: gl.w; height: gl.height

                // the capsule: tinted glass, brighter at the top
                Rectangle {
                    id: cap
                    x: 0; y: gl.horizon - col.h - 2; width: gl.w; height: col.h
                    radius: Math.min(width / 2, Theme.r(12))
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha(Theme.mix(col.tint, gl.white, 0.25), 0.85) }
                        GradientStop { position: 1; color: Theme.alpha(col.tint, 0.28) }
                    }
                    border.width: 1
                    border.color: Theme.alpha(gl.white, 0.18)
                    // the gloss: a soft sheen down the left of the upper half
                    Rectangle {
                        x: parent.width * 0.16; y: Math.min(3, parent.height * 0.1)
                        width: parent.width * 0.3; height: Math.max(0, parent.height * 0.55 - y)
                        radius: width / 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.alpha(gl.white, 0.45) }
                            GradientStop { position: 1; color: Theme.alpha(gl.white, 0) }
                        }
                    }
                }
                // its reflection on the horizon, shorter and fading away
                Rectangle {
                    x: 0; y: gl.horizon + 3; width: gl.w
                    height: Math.min(gl.height - y, col.h * 0.45)
                    radius: Math.min(width / 2, Theme.r(12))
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha(col.tint, 0.3) }
                        GradientStop { position: 1; color: Theme.alpha(col.tint, 0) }
                    }
                }
                // the cap: where the bar just was
                Rectangle {
                    readonly property real peakAt: Math.max(vis.caps[col.index] ?? 0, col.lv)
                    visible: peakAt > 0.04
                    x: gl.w * 0.15; width: gl.w * 0.7; height: 4; radius: 2
                    y: gl.horizon - 2 - Math.max(col.h, peakAt * gl.tall) - 8
                    color: Theme.alpha(Theme.mix(col.tint, gl.white, 0.55), 0.9)
                }
            }
        }
    } }
}
