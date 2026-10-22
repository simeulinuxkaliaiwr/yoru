import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// the slab: a glass smartphone. A dark body with a rim that catches the light, the screen in a
// thin bezel, and buttons that work: on the left a mute switch over the volume, on the right
// the one that puts it away. The screen wakes as it lands
Item {
    id: body
    property var phone: null                // null in the settings' preview: nothing to press
    property Component screen: null
    property real t: 1                      // 0 gone … 1 in your hand
    readonly property Item display: glass.item
    readonly property real outer: Theme.r(60)
    readonly property real bezel: 10
    // where the island lands when it turns into the phone
    readonly property var landing: ({ x: 0, y: 0, w: width, h: height, r: outer })
    readonly property real power: Math.max(0, Math.min(1, (t - 0.55) / 0.35))
    readonly property real span: 1
    implicitWidth: 376
    implicitHeight: 784

    component SideButton: Rectangle {
        id: btn
        property bool far: false             // on the right-hand side
        property string tip: ""
        signal hit()
        x: far ? body.width - 1 : -3
        width: 4
        radius: 2
        color: Theme.mix(Theme.island, Theme.ink, area.pressed ? 0.5 : area.containsMouse ? 0.38 : 0.22)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        MouseArea {
            id: area
            anchors { fill: parent; leftMargin: -8; rightMargin: -8 }
            enabled: body.phone !== null
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.hit()
        }
    }
    SideButton { y: 156; height: 30; onHit: Audio.toggleMute() }
    SideButton { y: 214; height: 60; onHit: Audio.setVolume(Audio.volume + 0.05) }
    SideButton { y: 284; height: 60; onHit: Audio.setVolume(Audio.volume - 0.05) }
    SideButton { far: true; y: 236; height: 92; onHit: body.phone.close() }

    RectangularShadow {
        visible: !Theme.hardShadow
        anchors.fill: rim
        radius: rim.radius
        blur: 56
        spread: 2
        offset: Qt.vector2d(0, 24)
        color: Qt.rgba(0, 0, 0, 0.55)
    }
    Rectangle {
        visible: Theme.hardShadow
        x: Theme.shadowOffset; y: Theme.shadowOffset
        width: rim.width; height: rim.height
        radius: rim.radius
        color: Theme.borderColour
    }

    // the rim: light along the edge, brightest at the top
    Rectangle {
        id: rim
        anchors.fill: parent
        radius: body.outer
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.mix(Theme.island, Theme.ink, 0.3) }
            GradientStop { position: 0.1; color: Theme.mix(Theme.island, Theme.ink, 0.1) }
            GradientStop { position: 0.7; color: Theme.mix(Theme.island, Theme.ink, 0.06) }
            GradientStop { position: 1.0; color: Theme.mix(Theme.island, Theme.ink, 0.18) }
        }
        border.width: Theme.border
        border.color: Theme.borderColour
    }
    Rectangle {
        anchors { fill: parent; margins: Math.max(2, Theme.border) }
        radius: body.outer - anchors.margins
        color: Theme.island
    }

    // the screen
    ClippingRectangle {
        id: pane
        anchors { fill: parent; margins: body.bezel }
        radius: body.outer - body.bezel
        color: "black"
        Loader {
            id: glass
            anchors.fill: parent
            focus: true
            sourceComponent: body.screen
            onLoaded: {
                if (item.look !== undefined) item.look = "slab";
                if (item.power !== undefined) item.power = Qt.binding(() => body.power);
            }
        }
        // the glass catches the light: a soft band, and once more as it wakes
        Rectangle {
            width: pane.width * 1.6; height: 120
            x: -pane.width * 0.3
            y: pane.height * (-0.25 + 1.4 * Math.min(1, body.power * 1.15))
            rotation: -28
            opacity: body.power > 0 && body.power < 1 ? 0.5 : 0
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.ink, 0.12) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(Theme.ink, 0.045) }
                GradientStop { position: 0.35; color: "transparent" }
            }
        }
    }
}
