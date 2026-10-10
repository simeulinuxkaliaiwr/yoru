import Quickshell
import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// today: how much of the day, the week and the year has gone
// today in one of three layouts: bars, three rings, or the sun's way across the sky
Card {
    id: c
    readonly property string look: Config.o.desktop.dayStyle
    height: look === "rings" ? 140 : look === "sun" ? 168 : 150
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
        visible: c.look === "bars"
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

    // ── sun: where it is between rising and setting ─────────────────
    Item {
        id: sun
        anchors.fill: parent
        visible: c.look === "sun"
        function mins(iso) { return iso ? parseInt(iso.slice(11, 13)) * 60 + parseInt(iso.slice(14, 16)) : 0; }
        readonly property real rise: mins(Weather.sunrise) || 360
        readonly property real set: mins(Weather.sunset) || 1080
        readonly property real nowM: c.now.getHours() * 60 + c.now.getMinutes()
        readonly property real f: (nowM - rise) / (set - rise)          // 0 at sunrise, 1 at sunset
        readonly property bool up: f >= 0 && f <= 1
        readonly property real cx: width / 2
        readonly property real cy: 132
        readonly property real r: 110
        readonly property real ang: Math.PI * (1 - Math.max(0, Math.min(1, f)))

        Txt { x: 20; y: 14; text: up ? Math.floor((sun.set - sun.nowM) / 60) + "h " + Math.round((sun.set - sun.nowM) % 60) + "m of light left" : "The sun is down"; size: 13; weight: Font.DemiBold
              readonly property bool up: sun.up }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.alpha(Theme.ink, 0.18); strokeWidth: 2; fillColor: "transparent"; strokeStyle: ShapePath.DashLine; dashPattern: [3, 4]
                PathAngleArc { centerX: sun.cx; centerY: sun.cy; radiusX: sun.r; radiusY: sun.r * 0.72; startAngle: 180; sweepAngle: 180 }
            }
            ShapePath {
                strokeColor: Theme.tertiary; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: sun.cx; centerY: sun.cy; radiusX: sun.r; radiusY: sun.r * 0.72; startAngle: 180; sweepAngle: 180 * Math.max(0.001, Math.min(1, sun.f)) }
            }
        }
        Rectangle { x: 16; y: sun.cy; width: parent.width - 32; height: 1; color: Theme.alpha(Theme.ink, 0.15) }
        // the sun, or the moon after dark
        Rectangle {
            width: 20; height: 20; radius: 10
            x: sun.cx + sun.r * Math.cos(sun.ang) - 10
            y: sun.cy - sun.r * 0.72 * Math.sin(sun.ang) - 10
            color: sun.up ? Theme.tertiary : Theme.inkDim
            Icon { anchors.centerIn: parent; visible: !sun.up; name: "bedtime"; size: 14; fill: 1; color: Theme.surfaceLowest }
        }
        Txt { x: 16; y: sun.cy + 6; text: "↑ " + (Weather.sunrise.slice(11, 16) || "--:--"); size: 11; color: Theme.inkDim }
        Txt { anchors.right: parent.right; anchors.rightMargin: 16; y: sun.cy + 6; text: (Weather.sunset.slice(11, 16) || "--:--") + " ↓"; size: 11; color: Theme.inkDim }
    }
}
