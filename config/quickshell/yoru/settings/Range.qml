import QtQuick
import qs
import qs.parts

// a slider with its value printed beside it
Row {
    id: r
    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    property string suffix: ""
    property int decimals: 0
    property real shownScale: 1
    signal moved(real v)
    spacing: 12

    Slider {
        width: 220; h: 28
        anchors.verticalCenter: parent.verticalCenter
        value: (r.value - r.from) / (r.to - r.from)
        onMoved: x => {
            const v = r.from + Math.round(x * (r.to - r.from) / r.step) * r.step;
            r.moved(Number(v.toFixed(4)));
        }
    }
    Txt {
        width: 64
        anchors.verticalCenter: parent.verticalCenter
        text: (r.value * r.shownScale).toFixed(r.decimals) + r.suffix
        size: 13; weight: Font.Medium; color: Theme.inkDim
        font.features: { "tnum": 1 }
    }
}
