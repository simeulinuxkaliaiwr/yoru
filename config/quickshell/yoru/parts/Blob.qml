import QtQuick
import QtQuick.Shapes
import qs

// a small Material 3 Expressive shape, drawn from a curve around its middle:
//   clover · burst · pill · diamond · pentagon · arrow · scallop · circle
// (the lock screen's password characters take them in turn)
Shape {
    id: b
    property string kind: "circle"
    property real size: 18
    property color color: Theme.ink
    width: size; height: size
    preferredRendererType: Shape.CurveRenderer

    // the outline as points, for a shape of radius 1 around 0,0
    function outline(kind) {
        const n = 96, pts = [];
        const poly = (sides, t, round) => {
            // a regular polygon's radius at angle t, its corners cut to arcs:
            // capping the radius turns each corner into a piece of a circle
            const seg = 2 * Math.PI / sides, h = Math.PI / sides;
            const r = Math.cos(h) / Math.cos(((t % seg) + seg) % seg - h);
            const cap = Math.cos(h) / Math.cos(h * (1 - round));
            return Math.min(r, cap) / cap;
        };
        for (let i = 0; i <= n; i++) {
            const t = i / n * Math.PI * 2;
            let x, y, r = 1;
            switch (kind) {
            case "clover":  r = 0.6 + 0.4 * Math.pow(Math.abs(Math.cos(2 * t)), 0.6); break;
            case "burst":   r = 0.82 + 0.18 * Math.cos(10 * t); break;
            case "scallop": r = 0.88 + 0.12 * Math.cos(6 * t); break;
            case "pentagon": r = poly(5, t + Math.PI / 2, 0.2); break;
            case "arrow":   r = poly(3, t + Math.PI / 2, 0.15); break;
            case "diamond": {
                // a rounded rhombus: |x|^p + |y|^p = 1
                const p = 1.35, c = Math.cos(t), s = Math.sin(t);
                r = Math.pow(Math.pow(Math.abs(c), p) + Math.pow(Math.abs(s), p), -1 / p);
                break;
            }
            case "pill": {
                // a capsule along the diagonal
                const a = t - Math.PI / 4, c = Math.cos(a), s = Math.sin(a);
                const w = 1, h = 0.55;
                x = Math.max(-w + h, Math.min(w - h, c * w)) + c * h;
                y = s * h;
                pts.push(Qt.point(x * Math.cos(Math.PI / 4) - y * Math.sin(Math.PI / 4),
                                  x * Math.sin(Math.PI / 4) + y * Math.cos(Math.PI / 4)));
                continue;
            }
            }
            pts.push(Qt.point(r * Math.cos(t), r * Math.sin(t)));
        }
        return pts;
    }
    readonly property var unit: outline(kind)

    ShapePath {
        fillColor: b.color
        strokeWidth: 0
        strokeColor: "transparent"
        PathPolyline {
            path: b.unit.map(p => Qt.point(b.width / 2 + p.x * b.width / 2, b.height / 2 + p.y * b.height / 2))
        }
    }
}
