import Quickshell
import QtQuick
import qs
import qs.parts

// days until something (or since, once it's passed):
//   number: the count, big · page: a tear-off calendar page · pill: one line
Card {
    id: c
    property string layout: "number"
    property var settings: ({})
    property string itemId
    width: layout === "pill" ? row.implicitWidth + 36 : layout === "page" ? 190 : 260
    height: layout === "pill" ? 52 : layout === "page" ? 210 : 150
    radius: layout === "pill" ? height / 2 : Config.o.desktop.widgetRadius

    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property string title: settings.title || "the day"
    readonly property date when: {
        const m = (settings.date ?? "").match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
        return m ? new Date(+m[1], +m[2] - 1, +m[3]) : new Date(NaN);
    }
    readonly property bool valid: !isNaN(when.getTime())
    readonly property int days: {
        const t = clock.date, today = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        return valid ? Math.round((when - today) / 86400000) : 0;
    }
    readonly property string words: !valid ? "Set a date in edit mode"
        : days === 0 ? "Today is " + title
        : days > 0 ? (days === 1 ? "day" : "days") + " until " + title
        : (days === -1 ? "day" : "days") + " since " + title

    // number
    Column {
        visible: c.layout === "number"
        x: 22; anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Txt { visible: c.valid && c.days !== 0; text: Math.abs(c.days); size: 56; weight: Font.Light; font.features: { "tnum": 1 } }
        Txt { width: c.width - 44; text: c.words; size: 14; weight: Font.Medium; wrapMode: Text.Wrap }
        Txt { visible: c.valid; text: Qt.formatDate(c.when, "dddd, d MMMM yyyy"); size: 11; color: Theme.inkDim }
    }

    // page: the month across the top, the count in the middle
    Item {
        visible: c.layout === "page"
        anchors.fill: parent
        Rectangle {
            width: parent.width; height: 46
            radius: c.radius
            color: Theme.primary
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.radius; color: parent.color }
            Txt { anchors.centerIn: parent; text: c.valid ? Qt.formatDate(c.when, "MMMM").toUpperCase() : "—"; size: 13; weight: Font.Bold
                  color: Theme.inkPrimary; font.letterSpacing: 2 }
        }
        Txt { anchors.horizontalCenter: parent.horizontalCenter; y: 56; text: c.valid ? Math.abs(c.days) : "?"; size: 72; weight: Font.Light; font.features: { "tnum": 1 } }
        Txt {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 16 }
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
            text: c.words; size: 12; color: Theme.inkDim; wrapMode: Text.Wrap; maximumLineCount: 2
        }
    }

    // pill
    Row {
        id: row
        visible: c.layout === "pill"
        x: 18; anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Icon { name: "event"; size: 20; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Txt { visible: c.valid && c.days !== 0; text: Math.abs(c.days); size: 18; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: c.words; size: 13; anchors.verticalCenter: parent.verticalCenter }
    }
}
