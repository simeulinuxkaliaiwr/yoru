import QtQuick
import qs
import qs.parts

// timers you can start from the desktop:
//   trio: three tiles, focus (the island's timer), a stopwatch and a countdown
//   focus: the focus timer alone, big, with its ring
Item {
    id: c
    property string layout: "trio"
    property string look
    property var settings: ({})
    property string itemId
    width: layout === "trio" ? 3 * 108 + 2 * 12 : 300
    height: layout === "trio" ? 108 : 150

    // a square tile with a badge in its corner
    component Tile: Card {
        id: tile
        property string icon
        property string value
        property string label
        property bool live: false
        default property alias extra: more.data
        signal clicked()
        signal held()
        look: c.look
        width: 108; height: 108
        Rectangle {
            anchors { right: parent.right; top: parent.top; margins: 10 }
            width: 34; height: 34; radius: tile.live ? 11 : 17
            color: tile.live ? Theme.primary : Theme.primaryContainer
            Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Icon { anchors.centerIn: parent; name: tile.icon; size: 19; fill: tile.live ? 1 : 0
                   color: tile.live ? Theme.inkPrimary : Theme.inkPrimaryContainer }
        }
        Column {
            x: 14; anchors { bottom: parent.bottom; bottomMargin: 12 }
            Txt { text: tile.value; size: 20; weight: Font.DemiBold; font.features: { "tnum": 1 } }
            Txt { text: tile.label; size: 11; color: Theme.inkDim }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: m => m.button === Qt.RightButton ? tile.held() : tile.clicked()
            onPressAndHold: tile.held()
        }
        Item { id: more; anchors.fill: parent }
    }

    Row {
        visible: c.layout === "trio"
        spacing: 12
        Tile {
            icon: "self_improvement"; live: Focus.active
            value: Focus.active ? Focus.clock(Focus.left) : Config.o.focus.minutes + ":00"
            label: Focus.phase === "break" ? "Break" : "Focus"
            onClicked: Focus.toggle()
        }
        Tile {
            icon: "timer"; live: Timers.watching
            value: Timers.clock(Timers.watched)
            label: Timers.watching ? "Stopwatch" : Timers.watched > 0 ? "Paused · hold to reset" : "Stopwatch"
            onClicked: Timers.watchToggle()
            onHeld: Timers.watchReset()
        }
        Tile {
            id: count
            icon: "hourglass_top"; live: Timers.counting
            value: Timers.clock(Timers.left)
            label: Timers.counting ? "Click to stop" : "Countdown"
            onClicked: Timers.cancel()
            // add time without leaving the tile
            Row {
                x: 12; y: 12; spacing: 4
                Repeater {
                    model: [1, 5]
                    Rectangle {
                        required property int modelData
                        width: 28; height: 20; radius: 10
                        color: Theme.alpha(Theme.ink, 0.1)
                        Txt { anchors.centerIn: parent; text: "+" + modelData; size: 10; weight: Font.Medium }
                        StateLayer { onClicked: Timers.add(parent.modelData) }
                    }
                }
            }
        }
    }

    // focus: one card, a ring around the time
    Card {
        visible: c.layout === "focus"
        look: c.look
        width: 300; height: 150
        Ring {
            x: 22; anchors.verticalCenter: parent.verticalCenter
            scale: 1.35
            value: Focus.progress
            icon: Focus.phase === "break" ? "coffee" : "self_improvement"
            label: ""; text: ""
        }
        Column {
            x: 116; anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Txt { text: Focus.phase === "break" ? "On a break" : Focus.active ? "Focusing" : "Focus"; size: 13; color: Theme.inkDim }
            Txt { text: Focus.active ? Focus.clock(Focus.left) : Config.o.focus.minutes + ":00"; size: 34; weight: Font.Light; font.features: { "tnum": 1 } }
            Rectangle {
                width: 100; height: 32; radius: 16
                color: Focus.active ? Theme.secondaryContainer : Theme.primary
                Txt { anchors.centerIn: parent; text: Focus.active ? "Stop" : "Start"; size: 13; weight: Font.Medium
                      color: Focus.active ? Theme.inkSecondaryContainer : Theme.inkPrimary }
                StateLayer { onClicked: Focus.toggle() }
            }
        }
    }
}
