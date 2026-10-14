import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// a small copy of the screen: the wallpaper, the island, and whatever the page
// puts on it, laid out in screen coordinates and scaled down
ClippingRectangle {
    id: p
    default property alias stage: screen.data
    readonly property real k: width / 1920
    width: parent ? Math.min(parent.width - 20, 620) : 620
    height: width * 9 / 16
    radius: Theme.r(18)
    color: Theme.surfaceLowest
    border.width: 1
    border.color: Theme.alpha(Theme.outlineVariant, 0.6)

    Image {
        anchors.fill: parent
        source: Theme.still ? "file://" + Theme.still : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(640, 360)
        asynchronous: true
    }
    Item {
        id: screen
        width: 1920; height: 1080
        scale: p.k
        transformOrigin: Item.TopLeft
        // the island, at rest
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            width: 380; height: 36; radius: Theme.r(18)
            color: Theme.island
            border.width: 1; border.color: Theme.alpha(Theme.outlineVariant, 0.45)
        }
    }
}
