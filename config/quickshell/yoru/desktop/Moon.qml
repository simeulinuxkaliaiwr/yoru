import QtQuick
import QtQuick.Shapes
import qs

// the moon as it is tonight (Night.phase): the lit part bounded by the edge and the
// terminator, a half-ellipse; the dark part faint. Mirrored south of the equator
Item {
    id: m
    property real size: 96
    property color light: Theme.ink
    property real phase: Night.phase        // 0 new, 0.5 full
    property bool south: Night.south
    readonly property real lit: (1 - Math.cos(2 * Math.PI * phase)) / 2
    readonly property bool waxing: phase < 0.5
    width: size; height: size
    readonly property real r: size / 2
    // how wide the terminator's half-ellipse is: the edge at new and full, a line at the quarters
    readonly property real rx: Math.max(0.01, r * Math.abs(Math.cos(2 * Math.PI * phase)))
    readonly property bool gibbous: lit > 0.5
    transform: Scale { origin.x: m.r; xScale: m.south ? -1 : 1 }

    // the dark disc, with a little earthshine
    Rectangle {
        anchors.fill: parent
        radius: m.r
        color: Theme.alpha(m.light, 0.1)
        border.width: 1
        border.color: Theme.alpha(m.light, 0.16)
    }
    Shape {
        anchors.fill: parent
        visible: m.lit > 0.01
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: m.light
            strokeWidth: 0
            strokeColor: "transparent"
            startX: m.r; startY: 0
            // the lit edge: the right side while it waxes, the left as it wanes
            PathArc {
                x: m.r; y: m.size
                radiusX: m.r; radiusY: m.r
                direction: m.waxing ? PathArc.Clockwise : PathArc.Counterclockwise
            }
            // and back up the terminator: bulging into the lit side for a crescent, out of it for
            // a gibbous (bottom to top through the right is counterclockwise: 6, 3, 12)
            PathArc {
                x: m.r; y: 0
                radiusX: m.rx; radiusY: m.r
                direction: m.waxing === m.gibbous ? PathArc.Clockwise : PathArc.Counterclockwise
            }
        }
    }
}
