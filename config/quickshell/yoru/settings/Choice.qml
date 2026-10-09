import QtQuick
import qs
import qs.parts

// a row of chips; the chosen one fills and rounds into a squircle
Flow {
    id: ch
    property var options: []            // [{ value, label, icon? }]
    property var current
    signal picked(var value)
    spacing: 6
    width: parent ? parent.width - 20 : 500

    Repeater {
        model: ch.options
        Rectangle {
            id: chip
            required property var modelData
            readonly property bool on: ch.current === modelData.value
            height: 36
            width: lbl.implicitWidth + (ico.visible ? 30 : 0) + 28
            radius: on ? 12 : 18
            color: on ? Theme.secondaryContainer : "transparent"
            border.width: on ? 0 : 1
            border.color: Theme.outlineVariant
            Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Row {
                anchors.centerIn: parent
                spacing: 6
                Icon { id: ico; visible: !!chip.modelData.icon || chip.on; name: chip.on ? "check" : (chip.modelData.icon ?? ""); size: 18
                       color: chip.on ? Theme.inkSecondaryContainer : Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                Txt { id: lbl; text: chip.modelData.label; size: 13; weight: Font.Medium
                      color: chip.on ? Theme.inkSecondaryContainer : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
            }
            StateLayer { onClicked: ch.picked(chip.modelData.value) }
        }
    }
}
