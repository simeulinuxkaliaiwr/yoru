import QtQuick
import QtQuick.Effects
import qs

// what a desktop widget sits on, in the style the settings pick:
//   glass · solid · tonal · outline · neon · minimal
Rectangle {
    id: card
    readonly property string look: Config.o.desktop.widgetStyle
    width: 320
    radius: Config.o.desktop.widgetRadius
    color: look === "glass" ? Theme.alpha(Theme.surfaceLowest, 0.62)
         : look === "solid" ? Theme.surfaceMid
         : look === "tonal" ? Theme.alpha(Theme.primaryContainer, 0.88)
         : look === "neon" ? Theme.alpha(Theme.island, 0.82)
         // the light ones still need a little dark under the text on a bright wallpaper
         : look === "outline" ? Theme.alpha(Theme.surfaceLowest, 0.45)
         : Theme.alpha(Theme.surfaceLowest, 0.32)
    border.width: look === "outline" ? 1.5 : look === "neon" ? 2 : look === "glass" ? 1 : 0
    border.color: look === "neon" ? Theme.primary
                : look === "outline" ? Theme.alpha(Theme.ink, 0.4)
                : Theme.alpha(Theme.outlineVariant, 0.5)
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    // neon glows; solid and tonal cast a soft shadow
    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: card.radius
        visible: card.look === "neon" || card.look === "solid" || card.look === "tonal"
        // a tight glow: a wide one fogged the gaps between the cards
        blur: card.look === "neon" ? 16 : 22
        spread: 0
        offset: card.look === "neon" ? Qt.vector2d(0, 0) : Qt.vector2d(0, 6)
        color: card.look === "neon" ? Theme.alpha(Theme.primary, 0.28) : Qt.rgba(0, 0, 0, 0.35)
    }
}
