import QtQuick
import qs
import qs.parts

Rectangle {
    id: b
    property string icon: ""
    property string label
    property bool tonal: false
    signal clicked()
    height: 40
    width: row.implicitWidth + 32
    radius: Theme.r(20)
    color: tonal ? Theme.secondaryContainer : Theme.primary
    readonly property color ink: tonal ? Theme.inkSecondaryContainer : Theme.inkPrimary
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon { visible: b.icon !== ""; name: b.icon; size: 18; color: b.ink; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: b.label; size: 13; weight: Font.DemiBold; color: b.ink; anchors.verticalCenter: parent.verticalCenter }
    }
    StateLayer { tint: b.ink; onClicked: b.clicked() }
}
