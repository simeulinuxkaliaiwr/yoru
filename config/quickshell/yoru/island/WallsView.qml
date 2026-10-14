import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// the wallpaper picker: a strip of nights; picking one re-themes everything
Item {
    id: v
    required property var isle
    required property var screen
    readonly property bool shown: isle?.mode === "walls"
    property var walls: []
    property bool loading: false

    implicitWidth: Math.min(screen.width - 120, 1240)
    implicitHeight: 290

    function key(e) {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_H) { list.decrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Right || e.key === Qt.Key_L) { list.incrementCurrentIndex(); return true; }
        if (e.key === Qt.Key_Home) { list.currentIndex = 0; return true; }
        if (e.key === Qt.Key_End) { list.currentIndex = list.count - 1; return true; }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
            if (list.currentIndex >= 0) apply(walls[list.currentIndex]);
            return true;
        }
        if (e.key === Qt.Key_R) { apply(walls[Math.floor(Math.random() * walls.length)]); return true; }
        return false;
    }
    onShownChanged: if (shown) { if (walls.length === 0) loading = true; query.running = true; }

    Process {
        id: query
        command: ["yoru", "walls"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { v.walls = JSON.parse(this.text); } catch (e) { return; }
                v.loading = false;
                const i = v.walls.findIndex(w => w.path === Theme.wallpaper);
                list.currentIndex = Math.max(0, i);
                list.positionViewAtIndex(list.currentIndex, ListView.Center);
            }
        }
    }
    function apply(w) {
        Quickshell.execDetached(["yoru", "wall", w.path]);
    }

    Txt { x: 26; y: 20; text: "Wallpapers"; size: 18; weight: Font.DemiBold }
    Txt {
        x: 26; y: 44
        text: v.loading ? "Making thumbnails…" : v.walls.length + " nights  ·  ← → to browse, Enter to pick"
        size: 12; color: Theme.inkDim
    }
    IconButton {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 18 }
        icon: "shuffle"; filled: true
        onClicked: if (v.walls.length) v.apply(v.walls[Math.floor(Math.random() * v.walls.length)])
    }

    ListView {
        id: list
        x: 12; y: 76
        width: parent.width - 24
        height: 196
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        model: v.walls
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: width / 2 - 160
        preferredHighlightEnd: width / 2 + 160
        highlightMoveDuration: Theme.slow
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool current: modelData.path === Theme.wallpaper
            readonly property bool sel: ListView.isCurrentItem
            width: 320; height: 196
            ClippingRectangle {
                id: frame
                anchors.centerIn: parent
                width: 320; height: 180
                radius: Theme.r(22)
                scale: card.sel ? 1 : 0.9
                opacity: card.sel || hover.containsMouse ? 1 : 0.62
                color: Theme.surfaceHigh
                border.width: card.current ? 3 : 0
                border.color: Theme.primary
                Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                Image {
                    anchors.fill: parent
                    source: card.modelData.thumb ? "file://" + card.modelData.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(480, 270)
                    asynchronous: true
                }
                Rectangle {
                    visible: card.modelData.video
                    anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                    width: 66; height: 26; radius: Theme.r(13)
                    color: Theme.alpha(Theme.island, 0.8)
                    Row {
                        anchors.centerIn: parent; spacing: 3
                        Icon { name: "play_arrow"; size: 16; fill: 1; color: Theme.ink }
                        Txt { text: "Live"; size: 11; weight: Font.DemiBold }
                    }
                }
                Rectangle {
                    visible: card.current
                    anchors { right: parent.right; top: parent.top; margins: 10 }
                    width: 28; height: 28; radius: Theme.r(14)
                    color: Theme.primary
                    Icon { anchors.centerIn: parent; name: "check"; size: 18; weight: 700; color: Theme.inkPrimary }
                }
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { list.currentIndex = card.index; v.apply(card.modelData); }
            }
        }
        WheelHandler {
            onWheel: e => { if (e.angleDelta.y < 0) list.incrementCurrentIndex(); else list.decrementCurrentIndex(); }
        }
    }
}
