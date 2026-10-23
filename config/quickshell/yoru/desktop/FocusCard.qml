import Quickshell
import QtQuick
import qs
import qs.parts

// the focus timer's history (Focus.days):
//   heatmap: a square for each day of the last eighteen weeks, deeper for more rounds
//   streak: how many days in a row, and this week's rounds as bars
Card {
    id: c
    property string layout: "heatmap"
    property var settings: ({})
    property string itemId
    readonly property int weeks: 18
    readonly property int cell: 13
    width: layout === "streak" ? 260 : 40 + weeks * (cell + 3)
    height: layout === "streak" ? 150 : 74 + 7 * (cell + 3) + 16

    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date today: new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate())
    // the grid starts on the Monday eighteen weeks back, so today's column is the last
    readonly property date start: {
        const lead = (today.getDay() + 6) % 7;
        return new Date(today.getFullYear(), today.getMonth(), today.getDate() - lead - (weeks - 1) * 7);
    }
    function shade(n) {
        return n <= 0 ? Theme.alpha(Theme.ink, 0.08) : n === 1 ? Theme.alpha(Theme.primary, 0.38)
             : n === 2 ? Theme.alpha(Theme.primary, 0.6) : n === 3 ? Theme.alpha(Theme.primary, 0.82) : Theme.primary;
    }
    readonly property int total: {
        let n = 0;
        for (const k in Focus.days) if (k >= Focus.iso(start)) n += Focus.days[k];
        return n;
    }

    // heatmap
    Item {
        visible: c.layout === "heatmap"
        anchors.fill: parent
        Row {
            x: 20; y: 16
            spacing: 8
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "self_improvement"; size: 20; color: Theme.primary }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Focus"; size: 14; weight: Font.DemiBold }
        }
        Txt {
            anchors { right: parent.right; rightMargin: 20; top: parent.top; topMargin: 18 }
            text: (Focus.streak > 1 ? Focus.streak + " days in a row  ·  " : "") + c.total + (c.total === 1 ? " round" : " rounds")
            size: 12; color: Theme.inkDim
        }
        Column {
            x: 20; y: 56
            spacing: 3
            Repeater {
                model: 7
                Row {
                    id: wk
                    required property int index
                    spacing: 3
                    Repeater {
                        model: c.weeks
                        Rectangle {
                            required property int index
                            readonly property date day: new Date(c.start.getFullYear(), c.start.getMonth(), c.start.getDate() + index * 7 + wk.index)
                            readonly property bool future: day > c.today
                            readonly property bool isToday: day.getTime() === c.today.getTime()
                            width: c.cell; height: c.cell
                            radius: Theme.r(4)
                            visible: !future
                            color: c.shade(Focus.countOn(day))
                            border.width: isToday ? 1.5 : 0
                            border.color: Theme.ink
                        }
                    }
                }
            }
        }
        Txt {
            anchors { left: parent.left; leftMargin: 20; bottom: parent.bottom; bottomMargin: 10 }
            text: Qt.formatDate(c.start, "d MMM") + "  –  today"
            size: 10; color: Theme.outline
        }
    }

    // streak
    Item {
        visible: c.layout === "streak"
        anchors.fill: parent
        Column {
            x: 22; anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Row {
                spacing: 6
                Txt { text: Focus.streak; size: 54; weight: Font.Light; font.features: { "tnum": 1 } }
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "local_fire_department"; size: 28; fill: Focus.streak > 0 ? 1 : 0
                       color: Focus.streak > 0 ? Theme.tertiary : Theme.outline }
            }
            Txt { text: Focus.streak === 1 ? "day of focus" : "days in a row"; size: 13; weight: Font.Medium }
            Txt { text: Focus.today + (Focus.today === 1 ? " round today" : " rounds today"); size: 11; color: Theme.inkDim }
        }
        // this week, Monday on
        Row {
            anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 22 }
            spacing: 6
            Repeater {
                model: 7
                Column {
                    id: bar
                    required property int index
                    readonly property date day: new Date(c.today.getFullYear(), c.today.getMonth(), c.today.getDate() - (c.today.getDay() + 6) % 7 + index)
                    readonly property int n: Focus.countOn(day)
                    spacing: 4
                    Item {
                        width: 10; height: 70
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; radius: 5
                            height: Math.max(6, Math.min(1, bar.n / 6) * parent.height)
                            color: bar.day > c.today ? Theme.alpha(Theme.ink, 0.05) : c.shade(bar.n)
                            Behavior on height { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "MTWTFSS"[bar.index]; size: 10
                        color: bar.day.getTime() === c.today.getTime() ? Theme.primary : Theme.outline
                    }
                }
            }
        }
    }
}
