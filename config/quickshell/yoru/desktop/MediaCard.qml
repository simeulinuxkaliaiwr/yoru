import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

Card {
    height: 112
    visible: Media.title !== ""
    readonly property real frac: Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0

    ClippingRectangle {
        id: art
        x: 14; y: 14
        width: 84; height: 84; radius: 20
        color: Theme.surfaceHigh
        Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(168, 168); asynchronous: true }
        Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "music_note"; size: 32; color: Theme.inkDim }
    }
    Column {
        anchors { left: art.right; leftMargin: 14; right: parent.right; rightMargin: 16; top: art.top; topMargin: 2 }
        Txt { width: parent.width; text: Media.title; size: 14; weight: Font.DemiBold }
        Txt { width: parent.width; text: Media.artist; size: 12; color: Theme.inkDim }
    }
    Rectangle {
        anchors { left: art.right; leftMargin: 14; right: parent.right; rightMargin: 16; bottom: art.bottom }
        height: 4; radius: 2
        color: Theme.surfaceHighest
        visible: Media.length > 0
        Rectangle { width: parent.width * parent.parent.frac; height: 4; radius: 2; color: Theme.primary }
    }
    Row {
        anchors { left: art.right; leftMargin: 6; bottom: art.bottom; bottomMargin: 8 }
        IconButton { icon: "skip_previous"; size: 32; onClicked: Media.prev() }
        IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 32; onClicked: Media.toggle() }
        IconButton { icon: "skip_next"; size: 32; onClicked: Media.next() }
    }
}
