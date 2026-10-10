import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

// the time in other cities: a list, or a grid of tiles. Each city is
// { name, tz } with tz an IANA zone (Asia/Tokyo); `date` knows their offsets
Card {
    id: c
    property string layout: "list"
    property var settings: ({})
    property string itemId
    readonly property var cities: (settings.cities ?? []).filter(x => x && x.tz)
    readonly property bool grid: layout === "grid"
    height: grid ? 52 + Math.ceil(cities.length / 2) * 66 : 52 + cities.length * 46

    SystemClock { id: clock; precision: SystemClock.Minutes }
    // minutes east of UTC for each zone, refreshed now and then for daylight saving
    property var offsets: ({})
    readonly property int here: -clock.date.getTimezoneOffset()
    function refresh() {
        if (!cities.length) return;
        zones.command = ["sh", "-c", "for z; do TZ=\"$z\" date +%z; done", "sh"].concat(cities.map(x => x.tz));
        zones.running = true;
    }
    onCitiesChanged: refresh()
    Component.onCompleted: refresh()
    Timer { interval: 30 * 60000; repeat: true; running: true; onTriggered: c.refresh() }
    Process {
        id: zones
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim().split("\n"), o = {};
                c.cities.forEach((x, i) => {
                    const z = out[i] ?? "+0000", sign = z[0] === "-" ? -1 : 1;
                    o[x.tz] = sign * (parseInt(z.slice(1, 3)) * 60 + parseInt(z.slice(3, 5)));
                });
                c.offsets = o;
            }
        }
    }
    function at(tz) {
        const off = offsets[tz] ?? here;
        return new Date(clock.date.getTime() + (off - here) * 60000);
    }
    function diff(tz) {
        const h = ((offsets[tz] ?? here) - here) / 60;
        return h === 0 ? "here" : (h > 0 ? "+" : "−") + Math.abs(h) + "h";
    }
    function night(d) { return d.getHours() < 6 || d.getHours() >= 19; }
    function hm(d) { return Qt.formatTime(d, Config.o.island.clock24 ? "HH:mm" : "h:mm AP"); }

    Row {
        x: 20; y: 16; spacing: 8
        Icon { name: "public"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: "World clock"; size: 14; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    Txt { visible: !c.cities.length; x: 20; y: 52; text: "Add cities in edit mode"; size: 13; color: Theme.inkDim }

    // list: one city a row
    Column {
        visible: !c.grid
        x: 20; y: 50
        width: parent.width - 40
        Repeater {
            model: c.grid ? [] : c.cities
            Item {
                required property var modelData
                readonly property date t: c.at(modelData.tz)
                width: parent.width; height: 46
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt { text: modelData.name || modelData.tz.split("/").pop().replace(/_/g, " "); size: 14; weight: Font.Medium }
                    Txt { text: Qt.formatDate(parent.parent.t, "ddd") + "  ·  " + c.diff(modelData.tz); size: 11; color: Theme.inkDim }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Icon { name: c.night(parent.parent.t) ? "bedtime" : "wb_sunny"; size: 16; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: c.hm(parent.parent.t); size: 22; weight: Font.Light; font.features: { "tnum": 1 } }
                }
            }
        }
    }
    // grid: tiles of two
    Grid {
        visible: c.grid
        x: 14; y: 48
        columns: 2; spacing: 8
        Repeater {
            model: c.grid ? c.cities : []
            Rectangle {
                required property var modelData
                readonly property date t: c.at(modelData.tz)
                width: (c.width - 28 - 8) / 2; height: 58; radius: 18
                color: Theme.alpha(Theme.ink, 0.06)
                Txt { x: 12; y: 8; width: parent.width - 50; text: modelData.name || modelData.tz.split("/").pop().replace(/_/g, " "); size: 12; color: Theme.inkDim }
                Txt { anchors { right: parent.right; rightMargin: 12 } y: 8; text: c.diff(modelData.tz); size: 10; color: Theme.inkDim }
                Txt { x: 12; y: 26; text: c.hm(parent.t); size: 20; weight: Font.Medium; font.features: { "tnum": 1 } }
                Icon { anchors { right: parent.right; rightMargin: 12 } y: 30; name: c.night(parent.t) ? "bedtime" : "wb_sunny"; size: 15; color: Theme.inkDim }
            }
        }
    }
}
