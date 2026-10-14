import Quickshell
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs
import qs.parts

// a clock to place anywhere, in any of the desktop clock's styles, or a
// cookie: Material's wavy shape with fat hands, the hour numbers faint behind
Item {
    id: c
    property string layout: "thin"
    property string look
    property var settings: ({})
    property string itemId
    width: layout === "cookie" ? 250 : face.implicitWidth
    height: layout === "cookie" ? 250 : face.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    ClockFace {
        id: face
        visible: c.layout !== "cookie"
        style: c.layout === "cookie" ? "thin" : c.layout
    }

    Item {
        id: cookie
        visible: c.layout === "cookie"
        anchors.fill: parent
        readonly property real cx: width / 2
        readonly property real cy: height / 2
        readonly property real r: width / 2 - 10
        readonly property int hh: clock.date.getHours() % 12
        readonly property int mm: clock.date.getMinutes()

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.primaryContainer
                strokeWidth: 0
                strokeColor: "transparent"
                PathPolyline {
                    // twelve soft bumps around the rim
                    path: {
                        const pts = [];
                        for (let i = 0; i <= 240; i++) {
                            const a = i / 240 * Math.PI * 2;
                            const r = cookie.r * (1 + 0.055 * Math.cos(12 * a));
                            pts.push(Qt.point(cookie.cx + r * Math.cos(a), cookie.cy + r * Math.sin(a)));
                        }
                        return pts;
                    }
                }
            }
        }
        // the quarter hours, big and faint
        Repeater {
            model: [[12, 0, -1], [3, 1, 0], [6, 0, 1], [9, -1, 0]]
            Txt {
                required property var modelData
                text: modelData[0]
                size: 44; weight: Font.Bold
                color: Theme.alpha(Theme.inkPrimaryContainer, 0.22)
                x: cookie.cx + modelData[1] * cookie.r * 0.66 - width / 2
                y: cookie.cy + modelData[2] * cookie.r * 0.66 - height / 2
            }
        }
        // the hands: rounded bars from the middle
        Rectangle {
            // hour
            width: 16; height: cookie.r * 0.5; radius: Theme.r(8)
            x: cookie.cx - width / 2; y: cookie.cy - height + width / 2
            color: Theme.primary
            transformOrigin: Item.Bottom
            rotation: (cookie.hh + cookie.mm / 60) * 30
            Behavior on rotation { RotationAnimation { duration: Theme.slow; direction: RotationAnimation.Clockwise } }
        }
        Rectangle {
            // minute
            width: 10; height: cookie.r * 0.78; radius: Theme.r(5)
            x: cookie.cx - width / 2; y: cookie.cy - height + width / 2
            color: Theme.tertiary
            transformOrigin: Item.Bottom
            rotation: cookie.mm * 6
            Behavior on rotation { RotationAnimation { duration: Theme.slow; direction: RotationAnimation.Clockwise } }
        }
        Rectangle { width: 14; height: 14; radius: Theme.r(7); x: cookie.cx - 7; y: cookie.cy - 7; color: Theme.inkPrimaryContainer }
        // the day of the month, in a bubble at the rim
        Rectangle {
            width: 50; height: 50; radius: Theme.r(25)
            x: cookie.cx + cookie.r * 0.62; y: cookie.cy + cookie.r * 0.62
            color: Theme.surfaceHigh
            border.width: 3; border.color: Theme.primaryContainer
            Txt { anchors.centerIn: parent; text: Qt.formatDate(clock.date, "d"); size: 18; weight: Font.DemiBold }
        }
    }

    // the desktop clock's shadow, so it reads on any wallpaper
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, c.layout === "cookie" ? 0.4 : 0.55)
        shadowBlur: 0.8
        shadowVerticalOffset: 2
    }
}
