import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// a gauge: a thick arc that fills clockwise, the value in the middle
Item {
    id: g
    property real value: 0              // 0..1
    property string icon
    property string label
    property string text
    property color tone: Theme.primary
    width: 64; height: 86

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    Shape {
        id: arc
        width: 64; height: 64
        preferredRendererType: Shape.CurveRenderer
        readonly property real r: 27
        ShapePath {
            strokeColor: Theme.surfaceHighest; strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 32; centerY: 32; radiusX: arc.r; radiusY: arc.r; startAngle: 135; sweepAngle: 270 }
        }
        ShapePath {
            strokeColor: g.tone; strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 32; centerY: 32; radiusX: arc.r; radiusY: arc.r; startAngle: 135; sweepAngle: Math.max(0.5, 270 * Math.min(1, g.shown)) }
        }
        Column {
            anchors.centerIn: parent
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: g.icon; size: 16; fill: 1; color: g.tone }
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: g.text; size: 12; weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
    }
    Txt {
        anchors { horizontalCenter: parent.horizontalCenter; top: arc.bottom; topMargin: 2 }
        text: g.label; size: 11; color: Theme.inkDim
    }
}
