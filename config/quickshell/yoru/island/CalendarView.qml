import Quickshell
import QtQuick
import qs
import qs.parts

// a month, with today in the accent; scroll or the arrows for other months
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "calendar"
    property int offset: 0
    implicitWidth: 360
    implicitHeight: 76 + 6 * 42 + 16

    SystemClock { id: clock; precision: SystemClock.Hours }
    onShownChanged: if (shown) offset = 0

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
                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === v.first.getMonth()
                readonly property bool today: modelData.toDateString() === clock.date.toDateString()
                width: 46; height: 36
                Rectangle {
                    anchors.centerIn: parent
                    width: 34; height: 34; radius: 17
                    color: parent.today ? Theme.primary : "transparent"
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
    WheelHandler { onWheel: e => v.offset += e.angleDelta.y > 0 ? -1 : 1 }
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_H) v.offset--;
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) v.offset++;
        else if (e.key === Qt.Key_Escape) v.isle.close();
    }
}
