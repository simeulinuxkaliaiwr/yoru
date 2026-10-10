import QtQuick
import qs
import qs.parts
import qs.desktop

Column {
    spacing: 14
    readonly property var c: Config.o.desktop

    Section {
        icon: "style"; title: "Widget layouts"
        Repeater {
            model: [
                ["weatherStyle", "Weather", "partly_cloudy_day", [["card", "Card"], ["hero", "Hero"], ["pill", "Pill"], ["graph", "Graph"], ["split", "Split"]], weatherC],
                ["calendarStyle", "Calendar", "calendar_month", [["month", "Month"], ["week", "Week"], ["date", "Date"], ["dots", "Dots"]], calC],
                ["systemStyle", "System", "monitoring", [["rings", "Rings"], ["bars", "Bars"], ["chips", "Chips"], ["graph", "Graph"]], sysC],
                ["mediaStyle", "Now playing", "album", [["card", "Card"], ["cover", "Cover"], ["pill", "Pill"], ["vinyl", "Vinyl"]], mediaC],
                ["dayStyle", "Today", "hourglass_bottom", [["bars", "Bars"], ["rings", "Rings"], ["sun", "Sun"]], dayC],
            ]
            Item {
                id: entry
                required property var modelData
                width: parent.width
                height: Math.max(left.height, shown.height) + 22
                Column {
                    id: left
                    x: 10; y: 6
                    width: parent.width - 300
                    spacing: 8
                    Row {
                        spacing: 10
                        Icon { name: entry.modelData[2]; size: 20; color: Theme.inkDim }
                        Txt { text: entry.modelData[1]; size: 14; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Choice {
                        width: parent.width
                        current: c[entry.modelData[0]] ?? ""
                        options: entry.modelData[3].map(o => ({ value: o[0], label: o[1] }))
                        onPicked: v => c[entry.modelData[0]] = v
                    }
                }
                // the widget itself, as it will look
                Item {
                    id: shown
                    anchors { right: parent.right; rightMargin: 10; top: parent.top; topMargin: 6 }
                    width: ld.item ? ld.item.width * 0.8 : 0
                    height: ld.item ? ld.item.height * 0.8 : 0
                    Loader {
                        id: ld
                        sourceComponent: entry.modelData[4]
                        onLoaded: { item.scale = 0.8; item.transformOrigin = Item.TopLeft; }
                    }
                }
            }
        }
        Component { id: weatherC; WeatherCard {} }
        Component { id: calC; CalendarCard {} }
        Component { id: sysC; SystemCard {} }
        Component { id: mediaC; MediaCard { visible: true } }
        Component { id: dayC; DayCard {} }
    }
}
