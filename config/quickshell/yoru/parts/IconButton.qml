import QtQuick
import qs

// a round icon button; `filled` makes it a tonal one
Rectangle {
    id: btn
    property string icon: ""
    property int size: 36
    property bool filled: false
    property bool active: false
    property color tone: active ? Theme.primary : filled ? Theme.surfaceHighest : "transparent"
    property color inkColour: active ? Theme.inkPrimary : Theme.ink
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: active ? size * 0.3 : size / 2
    color: tone
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Icon {
        anchors.centerIn: parent
        name: btn.icon
        size: Math.round(btn.size * 0.55)
        fill: btn.active ? 1 : 0
        color: btn.inkColour
    }
    StateLayer {
        tint: btn.inkColour
        onClicked: btn.clicked()
        // a little squish on press
        onPressedChanged: btn.scale = pressed ? 0.92 : 1
    }
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
}
