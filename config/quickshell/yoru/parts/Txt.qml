import QtQuick
import qs

Text {
    property int size: 13
    property int weight: Font.Normal
    color: Theme.ink
    font.family: Theme.sans
    font.pixelSize: size
    font.weight: weight
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
