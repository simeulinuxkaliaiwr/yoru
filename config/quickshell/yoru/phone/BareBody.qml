import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs

// bare: the screen alone, floating, edged like the island
Item {
    id: body
    property var phone: null
    property Component screen: null
    property real t: 1
    readonly property Item display: glass.item
    readonly property real outer: Theme.r(44)
    readonly property var landing: ({ x: 0, y: 0, w: width, h: height, r: outer })
    readonly property real power: Math.max(0, Math.min(1, (t - 0.5) / 0.3))
    readonly property real span: 0.9
    implicitWidth: 384
    implicitHeight: 748

    RectangularShadow {
        visible: !Theme.hardShadow
        anchors.fill: pane
        radius: body.outer
        blur: 48
        offset: Qt.vector2d(0, 16)
        color: Qt.rgba(0, 0, 0, 0.5)
    }
    Rectangle {
        visible: Theme.hardShadow
        x: Theme.shadowOffset; y: Theme.shadowOffset
        width: pane.width; height: pane.height
        radius: body.outer
        color: Theme.borderColour
    }
    ClippingRectangle {
        id: pane
        anchors.fill: parent
        radius: body.outer
        color: Theme.island
        border.width: Theme.border > 0 ? Theme.border : 1
        border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.outlineVariant, 0.45)
        contentUnderBorder: true
        Loader {
            id: glass
            anchors.fill: parent
            focus: true
            sourceComponent: body.screen
            onLoaded: {
                if (item.look !== undefined) item.look = "bare";
                if (item.power !== undefined) item.power = Qt.binding(() => body.power);
            }
        }
    }
}
