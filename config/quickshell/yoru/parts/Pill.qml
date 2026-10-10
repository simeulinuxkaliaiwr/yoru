import QtQuick
import qs

// a pill with an icon and a label; `on` fills it, `primary` makes it the main action
Rectangle {
    id: pill
    property string icon: ""
    property string label: ""
    property bool on: false
    property bool primary: false
    signal clicked()
    height: 36
    width: row.implicitWidth + (label !== "" ? 28 : 18)
    radius: on ? 12 : height / 2
    color: primary ? Theme.primary : on ? Theme.secondaryContainer : "transparent"
    border.width: primary || on ? 0 : 1
    border.color: Theme.outlineVariant
    opacity: enabled ? 1 : 0.35
    readonly property color ink: primary ? Theme.inkPrimary : on ? Theme.inkSecondaryContainer : Theme.ink
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon { visible: pill.icon !== ""; name: pill.icon; size: 18; color: pill.ink; anchors.verticalCenter: parent.verticalCenter }
        Txt { visible: pill.label !== ""; text: pill.label; size: 13; weight: Font.Medium; color: pill.ink; anchors.verticalCenter: parent.verticalCenter }
    }
    StateLayer { enabled: pill.enabled; tint: pill.ink; onClicked: pill.clicked() }
}
