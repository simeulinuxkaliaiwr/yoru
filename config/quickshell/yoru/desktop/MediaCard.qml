import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// what's playing, in one of three layouts
//   card: the cover beside the title · cover: the art large, words over it · pill: one line
//   vinyl: the cover on a record that turns while it plays
Card {
    id: c
    property string layout: Config.o.desktop.mediaStyle
    visible: Media.title !== ""
    width: layout === "pill" ? 300 : 320
    height: layout === "cover" ? 320 : layout === "pill" ? 60 : layout === "vinyl" ? 150 : 112
    radius: layout === "pill" ? height / 2 : Config.o.desktop.widgetRadius
    readonly property real frac: Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0

    // ── card ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.layout === "card"
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
            Rectangle { width: parent.width * c.frac; height: 4; radius: 2; color: Theme.primary }
        }
        Row {
            anchors { left: art.right; leftMargin: 6; bottom: art.bottom; bottomMargin: 8 }
            IconButton { icon: "skip_previous"; size: 32; onClicked: Media.prev() }
            IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 32; onClicked: Media.toggle() }
            IconButton { icon: "skip_next"; size: 32; onClicked: Media.next() }
        }
    }

    // ── cover: the art is the card ──────────────────────────────────
    ClippingRectangle {
        anchors.fill: parent
        visible: c.layout === "cover"
        radius: c.radius
        color: Theme.surfaceHigh
        Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(640, 640); asynchronous: true }
        Icon { anchors.centerIn: parent; anchors.verticalCenterOffset: -30; visible: Media.art === ""; name: "album"; size: 96; color: Theme.inkDim }
        // a shade for the words to sit on
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 150
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Theme.alpha(Theme.island, 0.92) }
            }
        }
        Column {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18; bottomMargin: 58 }
            Txt { width: parent.width; text: Media.title; size: 17; weight: Font.DemiBold }
            Txt { width: parent.width; text: Media.artist; size: 13; color: Theme.inkDim }
        }
        Row {
            anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 12 }
            IconButton { icon: "skip_previous"; size: 36; onClicked: Media.prev() }
            IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 40; active: true; onClicked: Media.toggle() }
            IconButton { icon: "skip_next"; size: 36; onClicked: Media.next() }
        }
        Rectangle {
            anchors { right: parent.right; rightMargin: 18; bottom: parent.bottom; bottomMargin: 30 }
            width: 120; height: 4; radius: 2
            visible: Media.length > 0
            color: Theme.alpha(Theme.ink, 0.25)
            Rectangle { width: parent.width * c.frac; height: 4; radius: 2; color: Theme.primary }
        }
    }

    // ── pill ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.layout === "pill"
        ClippingRectangle {
            id: dot
            x: 10; anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 20
            color: Theme.surfaceHigh
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(80, 80); asynchronous: true }
            Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "music_note"; size: 20; color: Theme.inkDim }
        }
        Column {
            anchors { left: dot.right; leftMargin: 10; right: play.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            Txt { width: parent.width; text: Media.title; size: 13; weight: Font.DemiBold }
            Txt { width: parent.width; text: Media.artist; size: 11; color: Theme.inkDim }
        }
        IconButton { id: play; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } icon: Media.playing ? "pause" : "play_arrow"; size: 40; active: true; onClicked: Media.toggle() }
    }

    // ── vinyl ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.layout === "vinyl"
        Item {
            id: disc
            x: 14; anchors.verticalCenter: parent.verticalCenter
            width: 122; height: 122
            // grooves, then the label: the cover
            Rectangle {
                anchors.fill: parent; radius: width / 2
                color: "#0d0d10"
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: 112 - index * 12; height: width; radius: width / 2
                        color: "transparent"
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.05 + (index % 2) * 0.03)
                    }
                }
            }
            ClippingRectangle {
                anchors.centerIn: parent
                width: 54; height: 54; radius: 27
                color: Theme.primary
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(108, 108); asynchronous: true }
            }
            Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.surfaceLowest }
            // one texture, turned in 30 fps steps at a calm 10 rpm: a 60 fps
            // animation kept the whole widget window redrawing for a label
            layer.enabled: c.layout === "vinyl"
            layer.smooth: true
            Timer {
                interval: 33; repeat: true
                running: c.layout === "vinyl" && Media.playing && c.visible
                onTriggered: disc.rotation = (disc.rotation + 2) % 360
            }
        }
        // a sheen that stays put while the record turns under it
        Rectangle {
            anchors.fill: disc; radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.65; color: "transparent" }
            }
        }
        Column {
            anchors { left: disc.right; leftMargin: 14; right: parent.right; rightMargin: 16; top: disc.top; topMargin: 8 }
            spacing: 1
            Txt { width: parent.width; text: Media.title; size: 14; weight: Font.DemiBold }
            Txt { width: parent.width; text: Media.artist; size: 12; color: Theme.inkDim }
        }
        Row {
            anchors { left: disc.right; leftMargin: 6; bottom: disc.bottom; bottomMargin: 4 }
            IconButton { icon: "skip_previous"; size: 34; onClicked: Media.prev() }
            IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 38; active: true; onClicked: Media.toggle() }
            IconButton { icon: "skip_next"; size: 34; onClicked: Media.next() }
        }
    }
}
