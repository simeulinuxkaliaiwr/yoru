import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// the words of what's playing, in time:
//   scroll: the lines rolling past, the sung one big · line: just the one and
//   the next · card: the cover and title above the scroll
Card {
    id: c
    property string layout: "scroll"
    property var settings: ({})
    property string itemId
    width: layout === "line" ? 520 : 340
    height: layout === "line" ? 84 : layout === "card" ? 330 : 240

    Component.onCompleted: Lyrics.users++
    Component.onDestruction: Lyrics.users--

    readonly property string state_: Media.title === "" ? "Nothing playing"
        : Lyrics.status === "loading" ? "Finding the words…"
        : Lyrics.status === "none" ? "No synced lyrics for this one" : ""

    // card: what it is, on top
    Row {
        id: head
        visible: c.layout === "card"
        x: 16; y: 16
        spacing: 12
        ClippingRectangle {
            width: 56; height: 56; radius: Theme.r(14)
            color: Theme.surfaceHigh
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(112, 112); asynchronous: true }
            Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "music_note"; size: 24; color: Theme.inkDim }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: c.width - 32 - 68
            Txt { width: parent.width; text: Media.title || "—"; size: 14; weight: Font.DemiBold }
            Txt { width: parent.width; text: Media.artist; size: 12; color: Theme.inkDim }
        }
    }

    Txt {
        visible: c.state_ !== "" || (Lyrics.status === "ok" && Lyrics.index < 0 && c.layout === "line")
        anchors.centerIn: lines
        text: c.state_ || "♪"
        size: 13; color: Theme.inkDim
    }

    // scroll and card: every line, the sung one centred
    Item {
        id: lines
        x: 16; width: parent.width - 32
        y: c.layout === "card" ? 84 : 12
        height: c.height - y - 12
        clip: true
        visible: c.layout !== "line"
        Column {
            id: col
            width: parent.width
            spacing: 6
            visible: c.state_ === ""
            readonly property Item current: Lyrics.index >= 0 ? rows.itemAt(Lyrics.index) : null
            y: current ? lines.height / 2 - current.y - current.height / 2 : lines.height / 2 - 10
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Repeater {
                id: rows
                model: c.layout !== "line" ? Lyrics.lines : []
                Txt {
                    required property var modelData
                    required property int index
                    readonly property int away: Math.abs(index - Lyrics.index)
                    width: col.width
                    text: modelData[1] || "♪"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    size: away === 0 ? 17 : 13
                    weight: away === 0 ? Font.DemiBold : Font.Normal
                    color: away === 0 ? Theme.ink : Theme.inkDim
                    opacity: away === 0 ? 1 : Math.max(0.15, 0.75 - away * 0.15)
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }
        }
    }

    // line: the one being sung, the next one under it
    Column {
        visible: c.layout === "line" && c.state_ === "" && Lyrics.index >= 0
        anchors { left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22; verticalCenter: parent.verticalCenter }
        spacing: 4
        Txt {
            width: parent.width
            text: Lyrics.line || "♪"
            size: 18; weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }
        Txt {
            width: parent.width
            text: Lyrics.index + 1 < Lyrics.lines.length ? Lyrics.lines[Lyrics.index + 1][1] : ""
            size: 12; color: Theme.inkDim
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
