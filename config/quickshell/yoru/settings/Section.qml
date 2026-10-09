import QtQuick
import qs
import qs.parts

// a card on a settings page: an icon, a title, and the rows under it
Rectangle {
    id: sec
    property string icon
    property string title
    default property alias rows: body.data
    width: parent ? parent.width : 600
    height: body.implicitHeight + 70
    radius: 26
    color: Theme.surfaceLow

    Row {
        x: 22; y: 20
        spacing: 10
        Icon { name: sec.icon; size: 22; color: Theme.primary }
        Txt { text: sec.title; size: 16; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    Column {
        id: body
        x: 12; y: 58
        width: parent.width - 24
        spacing: 2
    }
}
