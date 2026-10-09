import Quickshell
import QtQuick
import qs
import qs.parts

// today: how much of the day, the week and the year has gone
// today in one of two layouts: bars, or three rings
Card {
    id: c
    readonly property string look: Config.o.desktop.dayStyle
    height: look === "rings" ? 140 : 150
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property date now: clock.date
    readonly property real day: (now.getHours() * 60 + now.getMinutes()) / 1440
    readonly property real week: (((now.getDay() + 6) % 7) + day) / 7
    readonly property int isoWeek: {
        const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
    }
    readonly property real year: {
        const start = new Date(now.getFullYear(), 0, 1), end = new Date(now.getFullYear() + 1, 0, 1);
        return (now - start) / (end - start);
    }

    component Bar: Item {
        property string label
        property real value
        width: parent.width; height: 26
        Txt { width: 52; anchors.verticalCenter: parent.verticalCenter; text: parent.label; size: 12; color: Theme.inkDim }
        Rectangle {
            x: 56; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 56 - 44; height: 8; radius: 4
            color: Theme.surfaceHighest
            Rectangle { width: Math.max(8, parent.width * value); height: 8; radius: 4; color: Theme.primary
                        property real value: parent.parent.value }
        }
        Txt { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: Math.round(parent.value * 100) + "%"; size: 12; weight: Font.Medium; font.features: { "tnum": 1 } }
    }

    Row {
        visible: c.look === "rings"
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
        spacing: 26
        Ring { value: c.day; icon: "sunny"; label: "Day"; text: Math.round(c.day * 100) + "%" }
        Ring { value: c.week; icon: "date_range"; label: "Week " + c.isoWeek; text: Math.round(c.week * 100) + "%"; tone: Theme.secondary }
        Ring { value: c.year; icon: "public"; label: Qt.formatDate(c.now, "yyyy"); text: Math.round(c.year * 100) + "%"; tone: Theme.tertiary }
    }
    Txt { visible: c.look === "rings"; x: 20; y: 14; text: Qt.formatDate(c.now, "dddd, d MMMM"); size: 13; weight: Font.DemiBold }

    Column {
        visible: c.look !== "rings"
        x: 20; y: 16
        width: parent.width - 40
        spacing: 2
        Row {
            spacing: 8
            Txt { text: Qt.formatDate(c.now, "dddd"); size: 15; weight: Font.DemiBold }
            Txt { text: "week " + c.isoWeek; size: 12; color: Theme.inkDim; anchors.baseline: parent.children[0].baseline }
        }
        Item { width: 1; height: 6 }
        Bar { label: "Day"; value: c.day }
        Bar { label: "Week"; value: c.week }
        Bar { label: "Year"; value: c.year }
    }
}
