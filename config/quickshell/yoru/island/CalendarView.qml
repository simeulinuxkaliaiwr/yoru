import Quickshell
import QtQuick
import qs
import qs.parts

// a month, with today in the accent; scroll or the arrows for other months. With calendars
// (calendar.feeds) the days with events have dots, and a click on a day lists them under it
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "calendar"
    property int offset: 0
    property date picked: clock.date
    readonly property bool cals: Config.o.calendar.feeds.length > 0
    readonly property var dayEvents: cals ? Events.onDay(picked) : []
    implicitWidth: 360
    implicitHeight: 76 + 6 * 42 + 16 + (cals ? agenda.implicitHeight + 8 : 0)

    SystemClock { id: clock; precision: SystemClock.Hours }
    onShownChanged: if (shown) { offset = 0; picked = clock.date; }

    readonly property date first: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)
    // Monday first
    readonly property var days: {
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(first.getFullYear(), first.getMonth(), 1 - lead + i));
        return out;
    }

    Txt {
        x: 24; y: 22
        text: Qt.formatDate(v.first, "MMMM")
        size: 20; weight: Font.DemiBold
    }
    Txt {
        x: 24; y: 48
        text: Qt.formatDate(v.first, "yyyy")
        size: 12; color: Theme.inkDim
    }
    Row {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 20 }
        IconButton { icon: "chevron_left"; size: 34; onClicked: v.offset-- }
        IconButton { icon: "today"; size: 34; visible: v.offset !== 0; onClicked: v.offset = 0 }
        IconButton { icon: "chevron_right"; size: 34; onClicked: v.offset++ }
    }

    Grid {
        id: grid
        x: 16; y: 76
        columns: 7
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Txt {
                required property string modelData
                required property int index
                width: 46; height: 28
                horizontalAlignment: Text.AlignHCenter
                text: modelData; size: 11; weight: Font.DemiBold
                color: index >= 5 ? Theme.tertiary : Theme.outline
            }
        }
        Repeater {
            model: v.days
            Item {
                id: cell
                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === v.first.getMonth()
                readonly property bool today: modelData.toDateString() === clock.date.toDateString()
                readonly property bool isPicked: v.cals && modelData.toDateString() === v.picked.toDateString() && !today
                readonly property int busy: v.cals ? Events.onDay(modelData).length : 0
                width: 46; height: 36
                Rectangle {
                    anchors.centerIn: parent
                    width: 34; height: 34; radius: Theme.r(17)
                    color: parent.today ? Theme.primary : cell.isPicked ? Theme.secondaryContainer : "transparent"
                }
                // a dot for each event, up to three
                Row {
                    visible: cell.busy > 0
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
                    spacing: 2
                    Repeater {
                        model: Math.min(3, cell.busy)
                        Rectangle { width: 4; height: 4; radius: 2; color: cell.today ? Theme.inkPrimary : Theme.tertiary; opacity: cell.inMonth ? 1 : 0.4 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: v.cals
                    cursorShape: Qt.PointingHandCursor
                    onClicked: v.picked = cell.modelData
                }
                Txt {
                    anchors.centerIn: parent
                    text: parent.modelData.getDate()
                    size: 13
                    weight: parent.today ? Font.Bold : Font.Normal
                    color: parent.today ? Theme.inkPrimary : parent.inMonth ? Theme.ink : Theme.alpha(Theme.inkDim, 0.35)
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
    // the picked day's events
    Column {
        id: agenda
        visible: v.cals
        x: 18; y: grid.y + grid.height + 4
        width: parent.width - 36
        spacing: 4
        Txt {
            text: (v.picked.toDateString() === clock.date.toDateString() ? "Today" : Qt.formatDate(v.picked, "dddd, d MMMM"))
                  + (v.dayEvents.length === 0 ? ": nothing on" : "")
            size: 12; weight: Font.DemiBold; color: Theme.inkDim
            leftPadding: 4; bottomPadding: 2
        }
        Repeater {
            model: v.dayEvents.slice(0, 4)
            Rectangle {
                required property var modelData
                width: agenda.width; height: 40
                radius: Theme.r(14)
                color: Theme.surfaceMid
                Txt {
                    id: at
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    text: parent.modelData.allDay ? "All day" : Qt.formatTime(Events.when(parent.modelData.start), Config.o.island.clock24 ? "HH:mm" : "h:mm AP")
                    size: 12; weight: Font.DemiBold; color: Theme.primary
                    font.features: { "tnum": 1 }
                }
                Column {
                    anchors { left: at.right; leftMargin: 8; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    Txt { width: parent.width; text: parent.parent.modelData.title; size: 12; weight: Font.Medium }
                    Txt {
                        width: parent.width; visible: text !== ""
                        text: [parent.parent.modelData.where, parent.parent.modelData.cal].filter(x => x).join("  ·  ")
                        size: 10; color: Theme.inkDim
                    }
                }
            }
        }
        Txt { visible: v.dayEvents.length > 4; leftPadding: 4; text: (v.dayEvents.length - 4) + " more"; size: 11; color: Theme.inkDim }
    }

    WheelHandler { onWheel: e => v.offset += e.angleDelta.y > 0 ? -1 : 1 }
    function key(e) {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Up || e.key === Qt.Key_K) offset--;
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Down || e.key === Qt.Key_J) offset++;
        else if (e.key === Qt.Key_T || e.key === Qt.Key_Home) offset = 0;
        else return false;
        return true;
    }
}
