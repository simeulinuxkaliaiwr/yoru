import QtQuick
import qs
import qs.parts

// chips that each turn one thing on or off; what's on keeps the order it was turned on in
// (`numbered` says where each comes), so turning one off and on again sends it to the end
Flow {
    id: ch
    property var options: []            // [{ value, label, icon? }]
    property var current: []            // the values that are on, in order
    property bool numbered: false
    property int least: 0               // how many must stay on
    signal picked(var values)
    spacing: 6
    width: parent ? parent.width - 20 : 500

    Repeater {
        model: ch.options
        Rectangle {
            id: chip
            required property var modelData
            readonly property int at: Array.prototype.indexOf.call(ch.current, modelData.value)
            readonly property bool on: at >= 0
            height: 36
            width: row.implicitWidth + 28
            radius: on ? 12 : 18
            color: on ? Theme.secondaryContainer : "transparent"
            border.width: on ? 0 : 1
            border.color: Theme.outlineVariant
            Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                // its place in the order, while it's on
                Rectangle {
                    visible: ch.numbered && chip.on
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20; radius: 10
                    color: Theme.primary
                    Txt { anchors.centerIn: parent; text: chip.at + 1; size: 11; weight: Font.Bold; color: Theme.inkPrimary }
                }
                Icon {
                    visible: !(ch.numbered && chip.on) && (!!chip.modelData.icon || chip.on)
                    anchors.verticalCenter: parent.verticalCenter
                    name: chip.on && !chip.modelData.icon ? "check" : (chip.modelData.icon ?? "")
                    size: 18; fill: chip.on ? 1 : 0
                    color: chip.on ? Theme.inkSecondaryContainer : Theme.inkDim
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.label; size: 13; weight: Font.Medium
                    color: chip.on ? Theme.inkSecondaryContainer : Theme.ink
                }
            }
            StateLayer {
                onClicked: {
                    const now = Array.prototype.slice.call(ch.current);
                    if (chip.on && now.length <= ch.least) return;
                    ch.picked(chip.on ? now.filter(v => v !== chip.modelData.value) : now.concat([chip.modelData.value]));
                }
            }
        }
    }
}
