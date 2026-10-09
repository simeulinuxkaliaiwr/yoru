import QtQuick
import qs

// Material 3 Expressive slider: a thick rounded track that fills from the
// left, a bar for a handle, and the icon riding inside the filled part
Item {
    id: s
    property real value: 0              // 0..1
    property string icon: ""
    property bool muted: false
    property int h: 40
    signal moved(real v)
    signal iconClicked()

    implicitHeight: h
    implicitWidth: 240

    readonly property real shown: drag.pressed ? drag.live : value
    Behavior on value { enabled: !drag.pressed; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

    readonly property real handleX: Math.max(h * 0.5, Math.min(width - 6, shown * width))

    // the empty track, right of the handle
    Rectangle {
        x: s.handleX + 6
        width: Math.max(0, s.width - x)
        height: s.h * 0.72
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 3
        color: Theme.surfaceHighest
    }
    // the filled track
    Rectangle {
        width: Math.max(s.h * 0.5, s.handleX - 6)
        height: s.h
        radius: s.h / 3
        color: s.muted ? Theme.outline : Theme.primary
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Icon {
            anchors { left: parent.left; leftMargin: (s.h - size) / 2; verticalCenter: parent.verticalCenter }
            name: s.icon
            size: Math.round(s.h * 0.5)
            fill: 1
            color: Theme.inkPrimary
            visible: parent.width > s.h * 0.9
        }
    }
    // the handle
    Rectangle {
        x: s.handleX - width / 2
        width: drag.pressed ? 3 : 4
        height: s.h * 1.15
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: s.muted ? Theme.outline : Theme.primary
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property real live: 0
        function at(x) { return Math.max(0, Math.min(1, x / width)); }
        onPressed: e => {
            if (e.x < s.h && s.icon !== "") { s.iconClicked(); e.accepted = false; return; }
            live = at(e.x); s.moved(live);
        }
        onPositionChanged: e => { if (pressed) { live = at(e.x); s.moved(live); } }
        onWheel: e => s.moved(Math.max(0, Math.min(1, s.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
