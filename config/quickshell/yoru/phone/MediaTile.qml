import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// what's playing on the control page: a square with the cover behind the words, or a row on
// a flip's short screen. Its controls play and skip; anywhere else opens the music page
Item {
    id: mt
    required property var phone
    property bool row: false
    readonly property bool has: !!Media.player

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.r(mt.row ? 20 : 28)
        color: Theme.alpha(Theme.surfaceHigh, 0.72)
        border.width: Theme.border
        border.color: Theme.borderColour
        Image {
            id: cover
            visible: !mt.row && mt.has
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(320, 320)
            asynchronous: true
        }
        // dimmed toward the bottom, where the words sit on it
        Rectangle {
            visible: cover.visible && cover.status === Image.Ready
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.alpha(Theme.surfaceLowest, 0.0) }
                GradientStop { position: 0.4; color: Theme.alpha(Theme.surfaceLowest, 0.3) }
                GradientStop { position: 1; color: Theme.alpha(Theme.surfaceLowest, 0.9) }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mt.phone.go("music")
    }

    // nothing playing
    Column {
        visible: !mt.has
        anchors.centerIn: parent
        spacing: 4
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "music_note"; size: mt.row ? 18 : 30; color: Theme.outline; visible: !mt.row }
        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing playing"; size: 12; color: Theme.inkDim }
    }

    // the square
    Icon {
        visible: !mt.row && mt.has && (Media.art === "" || cover.status !== Image.Ready)
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.18 }
        name: "album"; size: 40; color: Theme.inkDim
    }
    Column {
        visible: !mt.row && mt.has
        anchors { left: parent.left; right: parent.right; bottom: ctl.top; leftMargin: 14; rightMargin: 14; bottomMargin: 4 }
        Txt { width: parent.width; text: Media.title; size: 13; weight: Font.DemiBold }
        Txt { width: parent.width; text: Media.artist; size: 11; color: Theme.inkDim }
    }

    // the row
    ClippingRectangle {
        id: thumb
        visible: mt.row && mt.has
        x: 9; anchors.verticalCenter: parent.verticalCenter
        width: parent.height - 18; height: width
        radius: Theme.r(12)
        color: Theme.surfaceHighest
        Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96); asynchronous: true }
    }
    Column {
        visible: mt.row && mt.has
        anchors { left: thumb.right; leftMargin: 10; right: ctl.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        Txt { width: parent.width; text: Media.title; size: 12; weight: Font.DemiBold }
        Txt { width: parent.width; text: Media.artist; size: 10; color: Theme.inkDim }
    }

    Row {
        id: ctl
        visible: mt.has
        x: mt.row ? parent.width - width - 6 : (parent.width - width) / 2
        y: mt.row ? (parent.height - height) / 2 : parent.height - height - 10
        spacing: 2
        IconButton { anchors.verticalCenter: parent.verticalCenter; size: mt.row ? 28 : 32; icon: "skip_previous"; onClicked: Media.prev() }
        IconButton { anchors.verticalCenter: parent.verticalCenter; size: mt.row ? 32 : 38; icon: Media.playing ? "pause" : "play_arrow"; active: true; onClicked: Media.toggle() }
        IconButton { anchors.verticalCenter: parent.verticalCenter; size: mt.row ? 28 : 32; icon: "skip_next"; onClicked: Media.next() }
    }
}
