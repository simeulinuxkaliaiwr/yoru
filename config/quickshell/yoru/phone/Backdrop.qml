import QtQuick
import QtQuick.Effects
import qs

// the phone's own wallpaper: yours (softened, and darker where there's reading to do),
// your colours as light behind frosted glass, or plain
Item {
    id: b
    property string kind: "wallpaper"       // wallpaper, colours, plain
    clip: true

    Rectangle { anchors.fill: parent; color: Theme.surfaceLowest }

    Image {
        id: pic
        anchors.fill: parent
        visible: false
        source: b.kind === "wallpaper" && Theme.still !== "" ? "file://" + Theme.still : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(1, b.width), Math.max(1, b.height))
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: parent
        source: pic
        visible: b.kind === "wallpaper" && pic.status === Image.Ready
        blurEnabled: true; blur: 0.35; blurMax: 24
        saturation: 0.1
    }

    Item {
        id: glow
        anchors.fill: parent
        visible: false
        Rectangle { x: -b.width * 0.35; y: -b.height * 0.08; width: b.width * 1.1; height: width; radius: width / 2; color: Theme.primaryContainer }
        Rectangle { x: b.width * 0.3; y: b.height * 0.38; width: b.width; height: width; radius: width / 2; color: Theme.tertiaryContainer }
        Rectangle { x: -b.width * 0.25; y: b.height * 0.74; width: b.width * 0.85; height: width; radius: width / 2; color: Theme.secondaryContainer }
    }
    MultiEffect {
        anchors.fill: parent
        source: glow
        visible: b.kind === "colours"
        blurEnabled: true; blur: 1; blurMax: 64
        opacity: 0.8
    }

    // something to read on: darker toward the bottom, where the apps are
    Rectangle {
        anchors.fill: parent
        visible: b.kind !== "plain"
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.surfaceLowest, 0.3) }
            GradientStop { position: 0.5; color: Theme.alpha(Theme.surfaceLowest, 0.45) }
            GradientStop { position: 1; color: Theme.alpha(Theme.surfaceLowest, 0.72) }
        }
    }
}
