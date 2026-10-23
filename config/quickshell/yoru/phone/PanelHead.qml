import QtQuick
import qs
import qs.parts

// the top of a panel: back, its name, and its switch
Item {
    id: h
    required property var phone
    property string title
    property bool on: false
    property bool busy: false               // a line sweeps under it while it searches
    property bool switchable: true          // false: no switch (the control centre's sound)
    property bool compact: false
    signal toggled()
    width: parent ? parent.width : 300
    height: compact ? 40 : 52

    IconButton {
        id: backBtn
        anchors { left: parent.left; leftMargin: h.compact ? 4 : 8; verticalCenter: parent.verticalCenter }
        size: h.compact ? 30 : 36
        icon: "arrow_back"
        onClicked: h.phone.panel = ""
    }
    Txt {
        anchors { left: backBtn.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
        text: h.title
        size: h.compact ? 15 : 18; weight: Font.DemiBold
    }
    // a switch, as the settings window's
    Rectangle {
        id: sw
        visible: h.switchable
        anchors { right: parent.right; rightMargin: h.compact ? 10 : 16; verticalCenter: parent.verticalCenter }
        width: 48; height: 28; radius: Theme.r(14)
        color: h.on ? Theme.primary : Theme.surfaceHighest
        border.width: h.on ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Rectangle {
            readonly property int d: h.on ? 20 : (flip.pressed ? 24 : 14)
            width: d; height: d; radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: h.on ? sw.width - d - 4 : 7 - (d - 14) / 2
            color: h.on ? Theme.inkPrimary : Theme.outline
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Icon { anchors.centerIn: parent; name: "check"; size: 14; weight: 600; color: Theme.primary; opacity: h.on ? 1 : 0 }
        }
        MouseArea { id: flip; anchors { fill: parent; margins: -6 } cursorShape: Qt.PointingHandCursor; onClicked: h.toggled() }
    }
    // searching
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }
        height: 2
        clip: true
        visible: h.busy
        Rectangle {
            width: parent.width * 0.3; height: 2; radius: 1
            color: Theme.primary
            NumberAnimation on x {
                running: h.busy && h.phone.shown
                loops: Animation.Infinite
                from: -parent.width * 0.3; to: parent.width
                duration: 1400; easing.type: Easing.InOutSine
            }
        }
    }
}
