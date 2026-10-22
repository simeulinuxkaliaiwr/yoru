import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// an app on the phone: its icon, maybe its name, and a dot while it has a window open
Item {
    id: cell
    required property var modelData
    required property int index
    property bool chosen: false
    property bool compact: false
    property bool labels: true
    property bool docked: false
    signal opened()
    signal dropped()
    readonly property int open: Apps.windowsOf(modelData).length

    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: cell.docked ? 0 : 2 }
        width: Math.min(parent.width - 4, cell.docked ? 62 : 78)
        height: cell.docked ? 62 : parent.height - 4
        radius: Theme.r(cell.docked ? 22 : 18)
        color: cell.chosen ? Theme.alpha(Theme.primary, 0.2) : Theme.alpha(Theme.ink, area.containsMouse ? 0.08 : 0)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    IconImage {
        id: ic
        anchors.horizontalCenter: parent.horizontalCenter
        y: cell.docked ? (parent.height - implicitSize) / 2 - 3 : (cell.compact ? 6 : 9)
        implicitSize: cell.docked ? 46 : cell.compact ? 34 : 46
        source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
        scale: area.pressed ? 0.88 : cell.chosen ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
    }
    // open: a dot under it, stretched while it's the chosen one
    Rectangle {
        visible: cell.open > 0
        anchors { horizontalCenter: parent.horizontalCenter; top: ic.bottom; topMargin: 3 }
        width: cell.chosen ? 12 : 4; height: 4; radius: 2
        color: Theme.primary
        Behavior on width { NumberAnimation { duration: Theme.fast } }
    }
    Txt {
        visible: cell.labels
        anchors { top: ic.bottom; topMargin: 9; left: parent.left; right: parent.right; leftMargin: 3; rightMargin: 3 }
        horizontalAlignment: Text.AlignHCenter
        text: cell.modelData.name
        size: cell.compact ? 10 : 11
        color: Theme.ink
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? cell.dropped() : cell.opened()
    }
}
