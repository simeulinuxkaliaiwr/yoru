import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// a tall slider, as on a phone: it fills from the bottom, the icon riding at its foot
// (a click there is the icon's: mute), the level showing at the top while it moves
Item {
    id: s
    property real value: 0                  // 0..1
    property string icon: ""
    property bool muted: false
    signal moved(real v)
    signal iconClicked()

    readonly property real shown: drag.pressed ? drag.live : value
    Behavior on value { enabled: !drag.pressed; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.r(Math.min(width / 2.3, 30))
        color: Theme.alpha(Theme.surfaceHigh, 0.72)
        border.width: Theme.border
        border.color: Theme.borderColour
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * Math.max(0, Math.min(1, s.shown))
            color: s.muted ? Theme.outline : Theme.primary
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }
    Icon {
        id: glyph
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
        name: s.icon
        size: 22
        fill: 1
        // ink that reads on whichever side of the fill it's on
        color: s.shown * s.height > s.height - glyph.y - glyph.height / 2 ? (s.muted ? Theme.surface : Theme.inkPrimary) : Theme.ink
    }
    Txt {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
        text: Math.round(s.shown * 100)
        size: 12; weight: Font.DemiBold
        color: s.shown > 0.88 ? Theme.inkPrimary : Theme.ink
        font.features: { "tnum": 1 }
        opacity: drag.pressed || drag.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        property real live: 0
        function at(y) { return Math.max(0, Math.min(1, 1 - y / height)); }
        onPressed: e => {
            if (e.y > height - 46 && s.icon !== "") { s.iconClicked(); e.accepted = false; return; }
            live = at(e.y); s.moved(live);
        }
        onPositionChanged: e => { if (pressed) { live = at(e.y); s.moved(live); } }
        onWheel: e => s.moved(Math.max(0, Math.min(1, s.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
