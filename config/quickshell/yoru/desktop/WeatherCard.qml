import QtQuick
import qs
import qs.parts

// the weather, in one of three layouts (settings: Desktop → Weather)
//   card: today and three days · hero: the temperature large, a range bar per day
//   pill: one line
Card {
    id: c
    readonly property string look: Config.o.desktop.weatherStyle
    visible: Weather.ready
    width: look === "pill" ? pill.implicitWidth + 36 : 320
    height: look === "hero" ? 300 : look === "pill" ? 64 : 168
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
}
