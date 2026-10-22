import QtQuick
import qs
import qs.parts
import "actions.js" as Actions

// a quick-settings tile. Small: an icon that fills and rounds into a squircle when it's on,
// its name under it. Wide (Wi-Fi, Bluetooth): the round icon turns it on and off, the rest
// says what it's connected to and opens its panel
Item {
    id: tile
    required property var phone
    required property string name
    property bool wide: false
    property bool compact: false
    property real unit: 72
    property real gap: 10
    readonly property bool on: phone.isOn(name)
    readonly property string label: Actions.label(name)

    width: wide ? unit * 2 + gap : unit
    height: wide ? (compact ? 52 : 62) : (compact ? unit * 0.72 : unit * 0.8 + 20)

    // wide
    Rectangle {
        visible: tile.wide
        anchors.fill: parent
        radius: Theme.r(tile.on ? 20 : height / 2)
        color: tile.on ? Theme.primaryContainer : Theme.alpha(Theme.surfaceHigh, 0.72)
        border.width: Theme.border
        border.color: Theme.borderColour
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        StateLayer {
            tint: tile.on ? Theme.inkPrimaryContainer : Theme.ink
            onClicked: tile.phone.go(tile.name)
        }
        Rectangle {
            id: bubble
            x: tile.compact ? 7 : 9
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 2 * x; height: width
            radius: Theme.r(width / 2)
            color: tile.on ? Theme.primary : Theme.surfaceHighest
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Icon {
                anchors.centerIn: parent
                name: tile.phone.icon(tile.name)
                size: tile.compact ? 18 : 21
                fill: tile.on ? 1 : 0
                color: tile.on ? Theme.inkPrimary : Theme.ink
            }
            StateLayer {
                tint: tile.on ? Theme.inkPrimary : Theme.ink
                onClicked: tile.phone.run(tile.name)
                onPressedChanged: bubble.scale = pressed ? 0.9 : 1
            }
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        }
        Column {
            anchors { left: bubble.right; leftMargin: 9; right: chev.left; rightMargin: 2; verticalCenter: parent.verticalCenter }
            Txt { width: parent.width; text: tile.label; size: tile.compact ? 12 : 13; weight: Font.DemiBold; color: tile.on ? Theme.inkPrimaryContainer : Theme.ink }
            Txt { width: parent.width; text: tile.phone.about(tile.name); size: tile.compact ? 10 : 11; color: tile.on ? Theme.inkPrimaryContainer : Theme.inkDim; opacity: 0.85 }
        }
        Icon {
            id: chev
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            name: "chevron_right"; size: 18
            color: tile.on ? Theme.inkPrimaryContainer : Theme.inkDim
        }
    }

    // small
    Rectangle {
        id: pad
        visible: !tile.wide
        width: parent.width
        height: tile.compact ? parent.height : tile.unit * 0.8
        radius: Theme.r(tile.on ? Math.min(22, height * 0.32) : height / 2)
        color: tile.on ? Theme.primary : Theme.alpha(Theme.surfaceHigh, 0.72)
        border.width: Theme.border
        border.color: Theme.borderColour
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Icon {
            anchors.centerIn: parent
            name: tile.phone.icon(tile.name)
            size: tile.compact ? 20 : 24
            fill: tile.on ? 1 : 0
            color: tile.on ? Theme.inkPrimary : Theme.ink
        }
        StateLayer {
            tint: tile.on ? Theme.inkPrimary : Theme.ink
            onClicked: tile.phone.run(tile.name)
            onPressedChanged: pad.scale = pressed ? 0.92 : 1
        }
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
    }
    Txt {
        visible: !tile.wide && !tile.compact
        anchors { top: pad.bottom; topMargin: 5; left: parent.left; right: parent.right }
        horizontalAlignment: Text.AlignHCenter
        // a running timer says how far along it is instead
        text: tile.on && (tile.name === "focus" || tile.name === "record") ? tile.phone.about(tile.name) : tile.label
        size: 10; color: tile.on ? Theme.ink : Theme.inkDim
    }
}
