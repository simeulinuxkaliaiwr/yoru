import Quickshell
import QtQuick
import qs
import qs.parts

// what's coming up in your calendars (Events, calendar.feeds):
//   next: the next one, big, and how soon · list: the next few, by day
Card {
    id: c
    property string layout: "next"
    property var settings: ({})
    property string itemId
    width: layout === "list" ? 320 : 300
    height: layout === "list" ? Math.max(120, list.implicitHeight + 32) : 140

    readonly property var next: Events.upcoming[0] ?? null
    readonly property string none: Config.o.calendar.feeds.length === 0 ? "Add a calendar in Settings → Calendar" : "Nothing coming up"

    // next
    Item {
        visible: c.layout === "next"
        anchors.fill: parent
        Row {
            x: 20; y: 18
            spacing: 8
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "event_upcoming"; size: 18; color: Theme.primary }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: c.next ? Events.words(c.next) : "Next up"; size: 12; weight: Font.DemiBold; color: Theme.primary }
        }
        Column {
            anchors { left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 20; bottom: parent.bottom; bottomMargin: 18 }
            spacing: 2
            Txt {
                width: parent.width
                text: c.next ? c.next.title : c.none
                size: c.next ? 20 : 13; weight: c.next ? Font.DemiBold : Font.Normal
                color: c.next ? Theme.ink : Theme.inkDim
                wrapMode: Text.Wrap; maximumLineCount: 2
            }
            Txt {
                width: parent.width; visible: !!c.next && text !== ""
                text: c.next ? [c.next.where, c.next.cal].filter(x => x).join("  ·  ") : ""
                size: 12; color: Theme.inkDim
            }
        }
    }

    // list: up to six, under their days
    Column {
        id: list
        visible: c.layout === "list"
        x: 18; y: 16
        width: c.width - 36
        spacing: 3
        Txt { visible: Events.upcoming.length === 0; text: c.none; size: 13; color: Theme.inkDim; topPadding: 30 }
        Repeater {
            model: Events.upcoming.slice(0, 6)
            Column {
                id: one
                required property var modelData
                required property int index
                readonly property string day: Qt.formatDate(Events.when(modelData.start), "dddd, d MMM")
                readonly property bool firstOfDay: index === 0 || Qt.formatDate(Events.when(Events.upcoming[index - 1].start), "dddd, d MMM") !== day
                width: list.width
                spacing: 2
                Txt {
                    visible: one.firstOfDay
                    topPadding: one.index === 0 ? 0 : 6
                    text: Events.when(one.modelData.start).toDateString() === new Date().toDateString() ? "Today" : one.day
                    size: 11; weight: Font.Bold; color: Theme.primary
                }
                Row {
                    spacing: 10
                    Txt {
                        width: 46
                        text: one.modelData.allDay ? "all day" : Qt.formatTime(Events.when(one.modelData.start), Config.o.island.clock24 ? "HH:mm" : "h:mm AP")
                        size: 12; color: Theme.inkDim; font.features: { "tnum": 1 }
                    }
                    Txt { width: list.width - 56; text: one.modelData.title; size: 12; weight: Font.Medium }
                }
            }
        }
    }
}
