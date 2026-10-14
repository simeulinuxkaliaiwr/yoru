import QtQuick
import qs
import qs.parts

// Material 3 switch: the thumb grows and shows a check when on
Rectangle {
    id: sw
    property bool checked: false
    signal toggled(bool on)
    width: 52; height: 32; radius: Theme.r(16)
    color: checked ? Theme.primary : Theme.surfaceHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Rectangle {
        id: thumb
        property int d: sw.checked ? 24 : (area.pressed ? 28 : 16)
        width: d; height: d; radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? sw.width - d - 4 : 8 - (d - 16) / 2
        color: sw.checked ? Theme.inkPrimary : Theme.outline
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on d { NumberAnimation { duration: Theme.fast } }
        Icon { anchors.centerIn: parent; name: "check"; size: 16; weight: 600; color: Theme.primary; opacity: sw.checked ? 1 : 0
               Behavior on opacity { NumberAnimation { duration: Theme.fast } } }
    }
    MouseArea { id: area; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled(!sw.checked) }
}
