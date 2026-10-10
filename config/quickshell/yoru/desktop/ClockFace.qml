import Quickshell
import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// the clock, in any of its styles; the desktop and the lock screen share it
//   thin · bold · stacked · outline · mono · split · words · kanji · serif · analog
Item {
    id: f
    property string style: "thin"
    property bool centred: false
    property real k: 1                  // size
    readonly property bool h24: Config.o.island.clock24

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    SystemClock { id: clock; precision: f.style === "mono" ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property date now: clock.date
    readonly property int hh: now.getHours()
    readonly property int mm: now.getMinutes()
    readonly property string hm: Qt.formatTime(now, h24 ? "HH:mm" : "h:mm")
    readonly property string date: Qt.formatDate(now, "dddd, d MMMM")

    // words: "twenty past five"
    readonly property var nums: ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
        "thirteen", "fourteen", "quarter", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
    function words() {
        const m5 = Math.round(mm / 5) * 5;
        let h = hh % 12;
        const next = (h + 1) % 12;
        const exact = m5 === mm ? "" : (m5 > mm ? "almost " : "just after ");
        if (m5 === 0 || m5 === 60) return exact + nums[m5 === 60 ? next : h] + "\no'clock";
        if (m5 === 30) return exact + "half past\n" + nums[h];
        const n = m5 <= 30 ? m5 : 60 - m5;
        const name = n === 15 ? "quarter" : n === 20 ? "twenty" : n === 25 ? "twenty-five" : nums[n];
        return exact + name + (m5 < 30 ? " past\n" + nums[h] : " to\n" + nums[next]);
    }

    // kanji: 十七時四十二分
    readonly property var kd: ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
    function kanji(n) {
        if (n < 10) return kd[n];
        const t = Math.floor(n / 10), o = n % 10;
        return (t > 1 ? kd[t] : "") + "十" + (o ? kd[o] : "");
    }
    readonly property var kdays: ["日", "月", "火", "水", "木", "金", "土"]

    // a line under the big time, shared by most styles
    component DateLine: Row {
        spacing: 12
        Rectangle { width: 26 * f.k; height: 3; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: f.date; size: 22 * f.k; weight: Font.Light; opacity: 0.85 }
    }

    Loader {
        id: holder
        sourceComponent: ({
            thin: thin, bold: bold, stacked: stacked, outline: outline, mono: mono, split: split,
            words: wordsC, kanji: kanjiC, serif: serif, analog: analog
        })[f.style] ?? thin
    }

    Component {
        id: thin
        Column {
            spacing: -6 * f.k
            Txt {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                text: f.hm; size: 136 * f.k; weight: Font.ExtraLight
                font.letterSpacing: -6 * f.k; font.features: { "tnum": 1 }
            }
            DateLine { anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined; leftPadding: f.centred ? 0 : 8 }
        }
    }
    Component {
        id: bold
        Column {
            spacing: -4 * f.k
            Txt {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                text: f.hm; size: 124 * f.k; weight: Font.Bold
                font.letterSpacing: -3 * f.k; font.features: { "tnum": 1 }
            }
            DateLine { anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined; leftPadding: f.centred ? 0 : 8 }
        }
    }
    Component {
        id: stacked
        Column {
            spacing: 6 * f.k
            Column {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                spacing: -34 * f.k
                Txt { text: Qt.formatTime(f.now, f.h24 ? "HH" : "hh"); size: 150 * f.k; weight: Font.Black; color: Theme.primary; font.features: { "tnum": 1 } }
                Txt { text: Qt.formatTime(f.now, "mm"); size: 150 * f.k; weight: Font.Black; font.features: { "tnum": 1 } }
            }
            DateLine { anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined; leftPadding: f.centred ? 0 : 8 }
        }
    }
    Component {
        id: outline
        Column {
            spacing: -2 * f.k
            Text {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                text: f.hm
                color: Theme.alpha(Theme.primary, 0.12)
                style: Text.Outline
                styleColor: Theme.ink
                font { family: Theme.sans; pixelSize: 150 * f.k; weight: Font.Black; letterSpacing: -2 * f.k; features: { "tnum": 1 } }
            }
            DateLine { anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined; leftPadding: f.centred ? 0 : 8 }
        }
    }
    Component {
        id: mono
        Column {
            spacing: 4 * f.k
            Row {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                Txt { text: Qt.formatTime(f.now, f.h24 ? "HH:mm" : "hh:mm"); size: 104 * f.k; weight: Font.Medium; font.family: Theme.mono }
                Txt {
                    text: Qt.formatTime(f.now, ":ss"); size: 104 * f.k; weight: Font.Light; font.family: Theme.mono
                    color: Theme.primary
                }
            }
            Txt {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                leftPadding: f.centred ? 0 : 6
                text: Qt.formatDate(f.now, "yyyy-MM-dd  ddd").toLowerCase()
                size: 20 * f.k; font.family: Theme.mono; color: Theme.inkDim
            }
        }
    }
    Component {
        id: split
        Row {
            spacing: 22 * f.k
            Txt { text: Qt.formatTime(f.now, f.h24 ? "HH" : "h"); size: 168 * f.k; weight: Font.Bold; font.letterSpacing: -6 * f.k; font.features: { "tnum": 1 } }
            Rectangle { width: 4 * f.k; height: 136 * f.k; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Txt { text: Qt.formatTime(f.now, "mm"); size: 78 * f.k; weight: Font.Light; color: Theme.primary; font.features: { "tnum": 1 } }
                Txt { text: Qt.formatDate(f.now, "dddd"); size: 22 * f.k; weight: Font.DemiBold }
                Txt { text: Qt.formatDate(f.now, "d MMMM"); size: 18 * f.k; color: Theme.inkDim }
            }
        }
    }
    Component {
        id: wordsC
        Column {
            spacing: 10 * f.k
            Txt {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                horizontalAlignment: f.centred ? Text.AlignHCenter : Text.AlignLeft
                text: "it's " + f.words()
                size: 64 * f.k; weight: Font.Light
                lineHeight: 0.92
                elide: Text.ElideNone
            }
            DateLine { anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined; leftPadding: f.centred ? 0 : 6 }
        }
    }
    Component {
        id: kanjiC
        Column {
            spacing: 4 * f.k
            Row {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                spacing: 2 * f.k
                Txt { text: f.kanji(f.hh); size: 104 * f.k; weight: Font.Bold; font.family: "Noto Sans JP" }
                Txt { text: "時"; size: 104 * f.k; weight: Font.Light; color: Theme.primary; font.family: "Noto Sans JP" }
                Txt { text: f.kanji(f.mm); size: 104 * f.k; weight: Font.Bold; font.family: "Noto Sans JP" }
                Txt { text: "分"; size: 104 * f.k; weight: Font.Light; color: Theme.primary; font.family: "Noto Sans JP" }
            }
            Txt {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                leftPadding: f.centred ? 0 : 8
                text: (f.now.getMonth() + 1) + "月" + f.now.getDate() + "日  " + f.kdays[f.now.getDay()] + "曜日  ·  " + f.hm
                size: 22 * f.k; font.family: "Noto Sans JP"; weight: Font.Light; opacity: 0.85
            }
        }
    }
    Component {
        id: serif
        Column {
            spacing: -16 * f.k
            Text {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                text: f.hm
                color: Theme.ink
                font { family: "Instrument Serif"; pixelSize: 168 * f.k; features: { "lnum": 1 } }
            }
            Text {
                anchors.horizontalCenter: f.centred ? parent.horizontalCenter : undefined
                leftPadding: f.centred ? 0 : 6
                text: Qt.formatDate(f.now, "dddd") + ", the " + f.ordinal(f.now.getDate()) + " of " + Qt.formatDate(f.now, "MMMM")
                color: Theme.primary
                font { family: "Instrument Serif"; italic: true; pixelSize: 30 * f.k }
            }
        }
    }
    function ordinal(n) {
        const s = n % 100 >= 11 && n % 100 <= 13 ? "th" : ["th", "st", "nd", "rd"][n % 10] ?? "th";
        return n + s;
    }
    Component {
        id: analog
        Row {
            spacing: 26 * f.k
            Item {
                id: dial
                width: 230 * f.k; height: width
                readonly property real r: width / 2
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Theme.alpha(Theme.surfaceLowest, 0.45)
                    border.width: 2; border.color: Theme.alpha(Theme.ink, 0.25)
                }
                Repeater {
                    model: 12
                    Rectangle {
                        required property int index
                        readonly property bool big: index % 3 === 0
                        width: big ? 5 * f.k : 3 * f.k; height: big ? 18 * f.k : 10 * f.k; radius: width / 2
                        color: big ? Theme.primary : Theme.alpha(Theme.ink, 0.6)
                        x: dial.r - width / 2; y: 12 * f.k
                        transform: Rotation { origin.x: width / 2; origin.y: dial.r - 12 * f.k; angle: index * 30 }
                    }
                }
                // hands
                Rectangle {
                    width: 9 * f.k; height: dial.r * 0.55; radius: width / 2
                    color: Theme.ink
                    x: dial.r - width / 2; y: dial.r - height + width / 2
                    transform: Rotation { origin.x: 4.5 * f.k; origin.y: dial.r * 0.55 - 4.5 * f.k; angle: (f.hh % 12) * 30 + f.mm * 0.5
                        Behavior on angle { RotationAnimation { duration: 600; direction: RotationAnimation.Clockwise } } }
                }
                Rectangle {
                    width: 6 * f.k; height: dial.r * 0.8; radius: width / 2
                    color: Theme.primary
                    x: dial.r - width / 2; y: dial.r - height + width / 2
                    transform: Rotation { origin.x: 3 * f.k; origin.y: dial.r * 0.8 - 3 * f.k; angle: f.mm * 6
                        Behavior on angle { RotationAnimation { duration: 600; easing.type: Easing.OutBack; direction: RotationAnimation.Clockwise } } }
                }
                Rectangle { anchors.centerIn: parent; width: 16 * f.k; height: width; radius: width / 2; color: Theme.primary; border.width: 3; border.color: Theme.island }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                visible: !f.centred
                Txt { text: Qt.formatDate(f.now, "dddd"); size: 34 * f.k; weight: Font.DemiBold }
                Txt { text: Qt.formatDate(f.now, "d MMMM"); size: 22 * f.k; color: Theme.inkDim }
                Txt { text: f.hm; size: 22 * f.k; color: Theme.primary; font.features: { "tnum": 1 } }
            }
        }
    }
}
