import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// the weather, in one of three layouts (settings: Desktop → Weather)
//   card: today and three days · hero: the temperature large, a range bar per day
//   pill: one line · graph: the next day as a curve · split: now beside the days
Card {
    id: c
    readonly property string look: Config.o.desktop.weatherStyle
    visible: Weather.ready
    width: look === "pill" ? pill.implicitWidth + 36 : look === "split" ? 360 : 320
    height: look === "hero" ? 300 : look === "pill" ? 64 : look === "graph" ? 196 : look === "split" ? 176 : 168
    radius: look === "pill" ? height / 2 : Config.o.desktop.widgetRadius

    function day(d) { return Qt.formatDate(new Date(d + "T12:00"), "ddd"); }

    // ── card ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: c.look === "card"
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
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: c.day(parent.parent.modelData.date); size: 11; color: Theme.inkDim }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4
                            Icon { name: Weather.icon(parent.parent.parent.modelData.code, true); size: 18; fill: 1; color: Theme.primary }
                            Txt { text: Math.round(parent.parent.parent.modelData.max) + "° "; size: 12; weight: Font.Medium }
                            Txt { text: Math.round(parent.parent.parent.modelData.min) + "°"; size: 12; color: Theme.inkDim }
                        }
                    }
                }
            }
        }
    }

    // ── hero: the number first, then the week as ranges ─────────────
    Item {
        anchors.fill: parent
        visible: c.look === "hero"
        readonly property real lo: Math.min(...Weather.days.map(d => d.min), Weather.temp)
        readonly property real hi: Math.max(...Weather.days.map(d => d.max), Weather.temp)

        Txt { x: 22; y: 18; text: Weather.place; size: 13; weight: Font.Medium; color: Theme.inkDim }
        Txt {
            x: 18; y: 34
            text: Math.round(Weather.temp) + "°"
            size: 86; weight: Font.ExtraLight
            font.letterSpacing: -4
        }
        Icon {
            anchors { right: parent.right; rightMargin: 22; top: parent.top; topMargin: 30 }
            name: Weather.icon(Weather.code, Weather.day)
            size: 76; fill: 1
            color: Theme.tertiary
        }
        Txt {
            x: 24; y: 136
            text: Weather.words(Weather.code) + "  ·  feels " + Math.round(Weather.feels) + "°  ·  " + Weather.humidity + "% humid"
            size: 12; color: Theme.inkDim
        }
        Column {
            x: 22; y: 168
            width: parent.width - 44
            spacing: 6
            Repeater {
                model: Weather.days.slice(0, 4)
                Item {
                    id: drow
                    required property var modelData
                    required property int index
                    width: parent.width; height: 24
                    readonly property var range: parent.parent
                    Txt { width: 44; anchors.verticalCenter: parent.verticalCenter; text: drow.index === 0 ? "Today" : c.day(drow.modelData.date); size: 12; weight: Font.Medium }
                    Icon { x: 48; anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(drow.modelData.code, true); size: 18; fill: 1; color: Theme.primary }
                    Txt { x: 76; width: 30; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; text: Math.round(drow.modelData.min) + "°"; size: 12; color: Theme.inkDim }
                    // the day's range against the whole week's
                    Rectangle {
                        id: track
                        x: 114; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 114 - 40; height: 6; radius: 3
                        color: Theme.surfaceHighest
                        Rectangle {
                            readonly property real span: Math.max(1, drow.range.hi - drow.range.lo)
                            x: track.width * (drow.modelData.min - drow.range.lo) / span
                            width: Math.max(6, track.width * (drow.modelData.max - drow.modelData.min) / span)
                            height: 6; radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.primary }
                                GradientStop { position: 1; color: Theme.tertiary }
                            }
                        }
                    }
                    Txt { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: Math.round(drow.modelData.max) + "°"; size: 12; weight: Font.Medium }
                }
            }
        }
    }

    // ── pill: a line ────────────────────────────────────────────────
    Row {
        id: pill
        visible: c.look === "pill"
        anchors.centerIn: parent
        spacing: 10
        Icon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(Weather.code, Weather.day); size: 28; fill: 1; color: Theme.tertiary }
        Txt { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Weather.temp) + "°"; size: 24; weight: Font.Light }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt { text: Weather.words(Weather.code); size: 12; weight: Font.Medium }
            Txt { text: Weather.place + "  ·  " + Math.round(Weather.days[0]?.max ?? 0) + "° / " + Math.round(Weather.days[0]?.min ?? 0) + "°"; size: 11; color: Theme.inkDim }
        }
    }

    // ── graph: the next 24 hours as a curve ─────────────────────────
    Item {
        id: graph
        anchors.fill: parent
        visible: c.look === "graph"
        readonly property var hs: Weather.hours
        readonly property real lo: hs.length ? Math.min(...hs.map(h => h.temp)) - 1 : 0
        readonly property real hi: hs.length ? Math.max(...hs.map(h => h.temp)) + 1 : 1
        readonly property real gx: 18
        readonly property real gw: width - 36
        readonly property real gy: 70
        readonly property real gh: 70
        function px(i) { return gx + gw * i / Math.max(1, hs.length - 1); }
        function py(t) { return gy + gh * (1 - (t - lo) / Math.max(1, hi - lo)); }

        Row {
            x: 20; y: 16
            spacing: 10
            Icon { name: Weather.icon(Weather.code, Weather.day); size: 36; fill: 1; color: Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: Math.round(Weather.temp) + "°  " + Weather.words(Weather.code); size: 16; weight: Font.DemiBold }
                Txt { text: Weather.place + "  ·  next 24 hours"; size: 11; color: Theme.inkDim }
            }
        }
        Shape {
            anchors.fill: parent
            visible: graph.hs.length > 1
            preferredRendererType: Shape.CurveRenderer
            // the area under the curve
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: graph.gy; x2: 0; y2: graph.gy + graph.gh
                    GradientStop { position: 0; color: Theme.alpha(Theme.primary, 0.35) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0) }
                }
                startX: graph.gx; startY: graph.gy + graph.gh
                PathPolyline { path: graph.hs.map((h, i) => Qt.point(graph.px(i), graph.py(h.temp))) }
                PathLine { x: graph.gx + graph.gw; y: graph.gy + graph.gh }
            }
            // the curve
            ShapePath {
                strokeColor: Theme.primary; strokeWidth: 3; fillColor: "transparent"
                capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                startX: graph.px(0); startY: graph.hs.length ? graph.py(graph.hs[0].temp) : 0
                PathPolyline { path: graph.hs.map((h, i) => Qt.point(graph.px(i), graph.py(h.temp))) }
            }
        }
        // every six hours: the time, an icon and the temperature
        Repeater {
            model: graph.hs.filter((h, i) => i % 6 === 0)
            Column {
                required property var modelData
                required property int index
                x: graph.px(index * 6) - width / 2
                y: graph.gy + graph.gh + 6
                spacing: 0
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(parent.modelData.temp) + "°"; size: 11; weight: Font.Medium }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData.time.slice(11, 16); size: 10; color: Theme.inkDim }
            }
        }
        Repeater {
            model: graph.hs.filter((h, i) => i % 6 === 0)
            Rectangle {
                required property var modelData
                required property int index
                width: 8; height: 8; radius: 4
                x: graph.px(index * 6) - 4; y: graph.py(modelData.temp) - 4
                color: Theme.surfaceLowest
                border.width: 2; border.color: Theme.primary
            }
        }
    }

    // ── split: now on the left, the days on the right ───────────────
    Item {
        anchors.fill: parent
        visible: c.look === "split"
        Rectangle {
            id: now
            x: 10; y: 10
            width: 150; height: parent.height - 20
            radius: c.radius - 8
            color: Theme.alpha(Theme.primaryContainer, 0.75)
            Column {
                anchors.centerIn: parent
                spacing: 2
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(Weather.code, Weather.day); size: 44; fill: 1; color: Theme.inkPrimaryContainer }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(Weather.temp) + "°"; size: 40; weight: Font.Light; color: Theme.inkPrimaryContainer }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.words(Weather.code); size: 11; color: Theme.inkPrimaryContainer }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.place; size: 10; color: Theme.inkPrimaryContainer; opacity: 0.8 }
            }
        }
        Column {
            anchors { left: now.right; leftMargin: 14; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 8
            Repeater {
                model: Weather.days.slice(1, 4)
                Item {
                    required property var modelData
                    width: parent.width; height: 38
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Txt { text: Qt.formatDate(new Date(parent.parent.modelData.date + "T12:00"), "dddd"); size: 12; weight: Font.Medium }
                        Txt { text: Weather.words(parent.parent.modelData.code); size: 10; color: Theme.inkDim }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Icon { name: Weather.icon(parent.parent.modelData.code, true); size: 20; fill: 1; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Txt { text: Math.round(parent.parent.modelData.max) + "°"; size: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                        Txt { text: Math.round(parent.parent.modelData.min) + "°"; size: 12; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
}
