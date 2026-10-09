import QtQuick
import qs

// Material's state layer: a wash of the ink colour on hover and press, and
// the MouseArea that drives it. Put it inside the thing that is pressable.
MouseArea {
    id: area
    property color tint: Theme.ink
    property real radius: parent ? (parent.radius ?? 0) : 0
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: area.radius
        color: area.tint
        opacity: area.pressed ? 0.14 : area.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }
}
