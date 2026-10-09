import QtQuick
import qs

// a Material Symbols Rounded glyph, by name: Icon { name: "wifi" }
Text {
    property string name: ""
    property real fill: 0               // 0 outlined, 1 filled; animatable
    property int size: 20
    property int weight: 400
    text: name
    // the distance-field renderer mangles filled glyphs of variable fonts
    renderType: Text.NativeRendering
    color: Theme.ink
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight, "opsz": Math.max(20, Math.min(48, size)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on fill { NumberAnimation { duration: Theme.fast } }
}
