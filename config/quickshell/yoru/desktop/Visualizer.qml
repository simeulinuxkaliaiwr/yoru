import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import qs

// the music, drawn from cava's levels. Bars rise at once and fall slowly, and
// sink to nothing if cava goes quiet, so they never freeze mid-air.
//   bars · mirror · wave · dots
Item {
    id: vis
    property string style: "bars"
    readonly property int n: 64
    property var levels: new Array(n).fill(0)
    property real peak: 0.3

    Process {
        running: true
        command: ["cava", "-p", Quickshell.shellDir + "/cava.conf"]
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
            if (out.every(v => v < 0.01)) stop();
        }
    }

    readonly property real gap: style === "dots" ? 8 : 7
    readonly property real barW: Math.max(3, (width - (n - 1) * gap) / n)

    // only the chosen style exists: a hidden one would still update every frame
    Loader { anchors.fill: parent; active: vis.style === "bars" || vis.style === "dots"; sourceComponent: barsC }
    Loader { anchors.fill: parent; active: vis.style === "mirror"; sourceComponent: mirrorC }
    Loader { anchors.fill: parent; active: vis.style === "wave"; sourceComponent: waveC }

    // ── bars, rising off the bottom ─────────────────────────────────
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

    // ── mirror: bars growing both ways from a line ──────────────────
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

    // ── wave: one smooth filled line ────────────────────────────────
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
}
