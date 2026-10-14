import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs

// what a desktop widget sits on, in the look the settings pick:
//   glass · solid · tonal · outline · neon · minimal
//   frosted: the wallpaper behind it, blurred · gradient: a wash of the accents
//   hud: corner brackets, nothing else · stack: a second sheet behind
//   manga: paper ruled in ink, a hard shadow and the accent's band along the top
// (a mode can choose the look for every card: its cardLook)
Rectangle {
    id: card
    property string look: Theme.mode && Theme.mode.cardLook ? Theme.mode.cardLook : Config.o.desktop.widgetStyle
    width: 320
    radius: Theme.r(Config.o.desktop.widgetRadius)
    color: look === "manga" ? Theme.surfaceLowest
         : look === "glass" ? Theme.alpha(Theme.surfaceLowest, 0.62)
         : look === "solid" || look === "stack" ? Theme.surfaceMid
         : look === "tonal" ? Theme.alpha(Theme.primaryContainer, 0.88)
         : look === "neon" ? Theme.alpha(Theme.island, 0.82)
         : look === "frosted" ? Theme.alpha(Theme.surfaceLowest, 0.5)
         : look === "gradient" ? "transparent"
         : look === "hud" ? Theme.alpha(Theme.surfaceLowest, 0.38)
         // the light ones still need a little dark under the text on a bright wallpaper
         : look === "outline" ? Theme.alpha(Theme.surfaceLowest, 0.45)
         : Theme.alpha(Theme.surfaceLowest, 0.32)
    border.width: look === "manga" ? Math.max(2, Theme.border) : look === "outline" ? 1.5 : look === "neon" ? 2 : look === "glass" || look === "frosted" ? 1 : 0
    border.color: look === "manga" ? (Theme.border > 0 ? Theme.borderColour : Theme.ink)
                : look === "neon" ? Theme.primary
                : look === "outline" ? Theme.alpha(Theme.ink, 0.4)
                : look === "frosted" ? Theme.alpha(Theme.ink, 0.18)
                : Theme.alpha(Theme.outlineVariant, 0.5)
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    // manga: printed, so its shadow is solid ink, and a band of the accent runs along the top
    Rectangle {
        z: -2
        visible: card.look === "manga"
        x: Theme.shadowOffset; y: Theme.shadowOffset
        width: parent.width; height: parent.height
        radius: card.radius
        color: Theme.border > 0 ? Theme.borderColour : Theme.ink
    }
    Rectangle {
        visible: card.look === "manga"
        x: card.border.width; y: card.border.width
        width: parent.width - card.border.width * 2; height: 4
        color: Theme.primary
    }

    // neon glows; solid, tonal, gradient and stack cast a soft shadow
    RectangularShadow {
        z: -2
        anchors.fill: parent
        radius: card.radius
        visible: ["neon", "solid", "tonal", "gradient", "stack", "frosted"].includes(card.look)
        blur: card.look === "neon" ? 16 : 22
        spread: 0
        offset: card.look === "neon" ? Qt.vector2d(0, 0) : Qt.vector2d(0, 6)
        color: card.look === "neon" ? Theme.alpha(Theme.primary, 0.28) : Qt.rgba(0, 0, 0, card.look === "frosted" ? 0.25 : 0.35)
    }

    // stack: a second sheet, a little lower and narrower
    Rectangle {
        z: -1
        visible: card.look === "stack"
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 9 }
        width: parent.width - 24; height: parent.height
        radius: card.radius
        color: Theme.surfaceHigh
        border.width: 1; border.color: Theme.alpha(Theme.outlineVariant, 0.6)
    }

    // gradient: the accents, washed across
    Rectangle {
        z: -1
        visible: card.look === "gradient"
        anchors.fill: parent
        radius: card.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.alpha(Theme.primaryContainer, 0.92) }
            GradientStop { position: 1; color: Theme.alpha(Theme.tertiaryContainer, 0.92) }
        }
    }

    // frosted: the wallpaper behind the card, blurred
    // the desktop's widget window says where it sits on screen (frostX/Y);
    // elsewhere (the settings preview) this is plain glass
    readonly property var host: QsWindow.window
    readonly property bool canFrost: look === "frosted" && host && host.frostX !== undefined && Theme.still !== ""
    property point at: Qt.point(0, 0)
    property real k: 1          // how much the card is scaled on screen (placed widgets can be)
    function place() {
        if (!canFrost) return;
        const p = card.mapToItem(host.contentItem, 0, 0), q = card.mapToItem(host.contentItem, 100, 0);
        at = Qt.point(host.frostX + p.x, host.frostY + p.y);
        k = Math.max(0.1, (q.x - p.x) / 100);
    }
    onCanFrostChanged: Qt.callLater(place)
    onWidthChanged: Qt.callLater(place)
    onHeightChanged: Qt.callLater(place)
    Timer { interval: 1500; running: card.canFrost; repeat: true; onTriggered: card.place() }

    ClippingRectangle {
        z: -1
        visible: card.canFrost
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        // the same plane Wallpaper.qml draws: taller by the parallax travel,
        // shifted by the workspace, gliding the same way
        Item {
            id: frost
            readonly property string out: card.host?.screen?.name ?? ""
            readonly property real screenH: card.host?.screen?.height ?? 1080
            readonly property int extra: Config.o.wallpaper.parallax ? Math.round(screenH * 0.07) : 0
            readonly property int count: Math.max(2, ...Wm.wsFor(out).map(w => w.index))
            property real shift: -extra * (Wm.current(out) - 1) / (count - 1)
            Behavior on shift { NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            // in the card's own units, so a scaled card shows the wallpaper at 1:1
            x: -card.at.x / card.k; y: (-card.at.y + shift) / card.k
            width: (card.host?.screen?.width ?? 1920) / card.k
            height: (screenH + extra) / card.k
            Image {
                id: wall
                anchors.fill: parent
                source: card.canFrost ? "file://" + Theme.still : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width / 4, height / 4)
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blur: 1
                blurMax: 64
                brightness: -0.25
                saturation: 0.2
            }
        }
    }

    // hud: brackets at the corners
    Repeater {
        model: card.look === "hud" ? 4 : 0
        Item {
            required property int index
            // not right/bottom: those are Item's anchor lines
            readonly property bool atRight: index % 2 === 1
            readonly property bool atBottom: index >= 2
            width: 22; height: 22
            x: atRight ? card.width - width : 0
            y: atBottom ? card.height - height : 0
            Rectangle { width: 22; height: 3; radius: Theme.r(1.5); color: Theme.primary; y: parent.atBottom ? 19 : 0 }
            Rectangle { width: 3; height: 22; radius: Theme.r(1.5); color: Theme.primary; x: parent.atRight ? 19 : 0 }
        }
    }
}
