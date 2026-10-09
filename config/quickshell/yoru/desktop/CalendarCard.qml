import Quickshell
import QtQuick
import qs
import qs.parts

// this month, small
Card {
    id: c
    height: grid.y + grid.height + 16
    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date first: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    readonly property var days: {
        const lead = (first.getDay() + 6) % 7;
        const len = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < Math.ceil((lead + len) / 7) * 7; i++) out.push(i - lead + 1);
        return out;
    }
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
                readonly property bool real: modelData >= 1 && modelData <= new Date(c.first.getFullYear(), c.first.getMonth() + 1, 0).getDate()
                readonly property bool today: modelData === clock.date.getDate()
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
