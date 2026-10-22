import QtQuick
import qs
import qs.parts
import "actions.js" as Actions

// the pages as pills along the bottom, like the island's workspaces: the one you're on
// stretches, and says its name for a moment after you arrive, in a chip grown over the row
// (so the pills never move under the pointer)
Item {
    id: pp
    property var pages: []
    property int current: 0
    signal picked(int index)
    readonly property int gap: 6
    readonly property real cur: 22
    readonly property real dot: 7
    width: row.width
    height: 24

    property bool named: false
    onCurrentChanged: { named = true; quiet.restart(); }
    Timer { id: quiet; interval: 1400; onTriggered: pp.named = false }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: pp.gap
        Repeater {
            id: pills
            model: pp.pages
            Item {
                id: slot
                required property string modelData
                required property int index
                readonly property bool on: index === pp.current
                width: on ? pp.cur : pp.dot
                height: 24
                Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: pp.dot
                    radius: height / 2
                    color: slot.on ? Theme.primary : Theme.alpha(Theme.ink, hover.containsMouse ? 0.6 : 0.32)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                MouseArea {
                    id: hover
                    anchors { fill: parent; margins: -4 }
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pp.picked(slot.index)
                }
            }
        }
    }

    // the name, over the pill it belongs to
    Rectangle {
        id: chip
        readonly property Item at: pills.itemAt(pp.current)
        readonly property real full: label.implicitWidth + 30
        anchors.verticalCenter: parent.verticalCenter
        x: at ? at.x + at.width / 2 - width / 2 : 0
        width: pp.named ? full : pp.cur
        height: pp.named ? 22 : pp.dot
        radius: height / 2
        color: Theme.primaryContainer
        opacity: pp.named ? 1 : 0
        visible: opacity > 0.01
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Row {
            anchors.centerIn: parent
            spacing: 4
            opacity: chip.width > label.implicitWidth + 18 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            Icon { anchors.verticalCenter: parent.verticalCenter; name: Actions.page[pp.pages[pp.current]]?.[0] ?? ""; size: 13; fill: 1; color: Theme.inkPrimaryContainer }
            Txt { id: label; anchors.verticalCenter: parent.verticalCenter; text: Actions.page[pp.pages[pp.current]]?.[1] ?? ""; size: 11; weight: Font.DemiBold; color: Theme.inkPrimaryContainer }
        }
    }
}
