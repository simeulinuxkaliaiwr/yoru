import Quickshell
import QtQuick
import qs
import qs.parts

// the calendar, in one of three layouts (settings: Desktop → Calendar)
//   month: the whole month · week: this week as a strip · date: a tear-off page
//   dots: the month as dots, the days gone filled in
Card {
    id: c
    readonly property string look: Config.o.desktop.calendarStyle
    width: look === "date" ? 200 : 320
    height: look === "date" ? 216 : look === "week" ? 128 : look === "dots" ? 190 : grid.y + grid.height + 16

    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date now: clock.date
    readonly property date first: new Date(now.getFullYear(), now.getMonth(), 1)
    readonly property int len: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()
    readonly property var days: {
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < Math.ceil((lead + len) / 7) * 7; i++) out.push(i - lead + 1);
        return out;
    }

    // ── month ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.look === "month"
        Txt { x: 20; y: 16; text: Qt.formatDate(c.first, "MMMM"); size: 15; weight: Font.DemiBold }
        Txt { anchors { right: parent.right; rightMargin: 20; top: parent.top; topMargin: 18 } text: Qt.formatDate(c.first, "yyyy"); size: 12; color: Theme.inkDim }
        Grid {
            id: grid
            x: 14; y: 46
            columns: 7
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Txt { required property string modelData; required property int index
                      width: 41; height: 22; horizontalAlignment: Text.AlignHCenter; text: modelData; size: 10; weight: Font.DemiBold
                      color: index >= 5 ? Theme.tertiary : Theme.outline }
            }
            Repeater {
                model: c.days
                Item {
                    required property int modelData
                    readonly property bool real: modelData >= 1 && modelData <= c.len
                    readonly property bool today: modelData === c.now.getDate()
                    width: 41; height: 28
                    Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; visible: parent.today && parent.real; color: Theme.primary }
                    Txt {
                        anchors.centerIn: parent
                        visible: parent.real
                        text: parent.modelData; size: 12
                        weight: parent.today ? Font.Bold : Font.Normal
                        color: parent.today ? Theme.inkPrimary : Theme.ink
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }

    // ── week: seven days, today standing up ─────────────────────────
    Item {
        anchors.fill: parent
        visible: c.look === "week"
        Txt { x: 20; y: 16; text: Qt.formatDate(c.now, "MMMM yyyy"); size: 14; weight: Font.DemiBold }
        Txt { anchors { right: parent.right; rightMargin: 20; top: parent.top; topMargin: 18 } text: Qt.formatDate(c.now, "dddd"); size: 12; color: Theme.primary; weight: Font.Medium }
        Row {
            x: 14; y: 48
            spacing: 4
            Repeater {
                model: 7
                Rectangle {
                    required property int index
                    readonly property date d: new Date(c.now.getFullYear(), c.now.getMonth(), c.now.getDate() - ((c.now.getDay() + 6) % 7) + index)
                    readonly property bool today: index === (c.now.getDay() + 6) % 7
                    width: 38; height: 64; radius: 19
                    color: today ? Theme.primary : Theme.alpha(Theme.surfaceHigh, 0.55)
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(parent.parent.d, "ddd").slice(0, 2); size: 10; weight: Font.Medium
                              color: parent.parent.today ? Theme.inkPrimary : (parent.parent.index >= 5 ? Theme.tertiary : Theme.inkDim) }
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.d.getDate(); size: 16; weight: Font.DemiBold
                              color: parent.parent.today ? Theme.inkPrimary : Theme.ink; font.features: { "tnum": 1 } }
                    }
                }
            }
        }
    }

    // ── date: a page torn off a calendar ────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.look === "date"
        Rectangle {
            id: band
            width: parent.width; height: 46
            topLeftRadius: c.radius; topRightRadius: c.radius
            color: Theme.primary
            Txt { anchors.centerIn: parent; text: Qt.formatDate(c.now, "MMMM").toUpperCase(); size: 14; weight: Font.Bold; color: Theme.inkPrimary; font.letterSpacing: 3 }
        }
        // the holes the page hung from
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; top: band.bottom; topMargin: -5 }
            spacing: 62
            Repeater { model: 2; Rectangle { width: 10; height: 10; radius: 5; color: Theme.surfaceLowest; border.width: 2; border.color: Theme.alpha(Theme.ink, 0.3) } }
        }
        Txt {
            anchors { horizontalCenter: parent.horizontalCenter; top: band.bottom; topMargin: 8 }
            text: c.now.getDate()
            size: 104; weight: Font.Light
            font.features: { "tnum": 1 }
        }
        Txt {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 16 }
            text: Qt.formatDate(c.now, "dddd") + "  ·  " + c.now.getFullYear()
            size: 13; color: Theme.inkDim
        }
    }

    // ── dots: how far through the month ─────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.look === "dots"
        Txt { x: 20; y: 14; text: Qt.formatDate(c.now, "MMMM"); size: 22; weight: Font.Light }
        Txt {
            anchors { right: parent.right; rightMargin: 20; top: parent.top; topMargin: 22 }
            text: (c.len - c.now.getDate()) + " days left"
            size: 12; color: Theme.inkDim
        }
        Grid {
            x: 20; y: 58
            columns: 7
            rowSpacing: 10; columnSpacing: 0
            Repeater {
                model: c.days
                Item {
                    required property int modelData
                    readonly property bool real: modelData >= 1 && modelData <= c.len
                    readonly property bool gone: modelData < c.now.getDate()
                    readonly property bool today: modelData === c.now.getDate()
                    width: 40; height: 16
                    Rectangle {
                        anchors.centerIn: parent
                        visible: parent.real
                        width: parent.today ? 16 : 10; height: width; radius: width / 2
                        color: parent.today ? Theme.primary : parent.gone ? Theme.alpha(Theme.primary, 0.55) : "transparent"
                        border.width: parent.gone || parent.today ? 0 : 1.5
                        border.color: Theme.alpha(Theme.ink, 0.35)
                    }
                }
            }
        }
    }
}
