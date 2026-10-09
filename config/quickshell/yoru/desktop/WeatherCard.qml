import QtQuick
import qs
import qs.parts

Card {
    id: c
    height: 168
    visible: Weather.ready

    Icon {
        id: big
        x: 20; y: 18
        name: Weather.icon(Weather.code, Weather.day)
        size: 54; fill: 1
        color: Theme.tertiary
    }
    Column {
        anchors { left: big.right; leftMargin: 14; verticalCenter: big.verticalCenter }
        Txt { text: Math.round(Weather.temp) + "°"; size: 34; weight: Font.Light }
        Txt { text: Weather.words(Weather.code) + " · feels " + Math.round(Weather.feels) + "°"; size: 12; color: Theme.inkDim }
    }
    Txt {
        anchors { right: parent.right; rightMargin: 20; top: parent.top; topMargin: 20 }
        width: 110; horizontalAlignment: Text.AlignRight
        text: Weather.place; size: 12; weight: Font.Medium; color: Theme.inkDim
    }

    Row {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
        spacing: 6
        Repeater {
            model: Weather.days.slice(1, 4)
            Rectangle {
                required property var modelData
                width: (c.width - 40) / 3; height: 58
                radius: 18
                color: Theme.alpha(Theme.surfaceHigh, 0.6)
                Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(parent.parent.modelData.date + "T12:00"), "ddd"); size: 11; color: Theme.inkDim }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        Icon { name: Weather.icon(parent.parent.parent.modelData.code, true); size: 18; fill: 1; color: Theme.primary }
                        Txt { text: Math.round(parent.parent.parent.modelData.max) + "° " ; size: 12; weight: Font.Medium }
                        Txt { text: Math.round(parent.parent.parent.modelData.min) + "°"; size: 12; color: Theme.inkDim }
                    }
                }
            }
        }
    }
}
