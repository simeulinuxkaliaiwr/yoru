import QtQuick
import qs
import qs.parts

// processor, memory, heat and battery, in one of three layouts
//   rings: gauges · bars: a meter per line · chips: a compact row
Card {
    id: c
    readonly property string look: Config.o.desktop.systemStyle
    width: look === "chips" ? chips.implicitWidth + 24 : 320
    height: look === "bars" ? 176 : look === "chips" ? 56 : 124
    radius: look === "chips" ? height / 2 : Config.o.desktop.widgetRadius
    Component.onCompleted: SysStats.watchers++
    Component.onDestruction: SysStats.watchers--

    readonly property var stats: [
        { icon: "memory", label: "CPU", value: SysStats.cpu, text: Math.round(SysStats.cpu * 100) + "%", tone: Theme.primary },
        { icon: "memory_alt", label: "Memory", value: SysStats.mem, text: SysStats.memUsedGb.toFixed(1) + " GB", tone: Theme.secondary },
        { icon: "thermostat", label: "Heat", value: Math.min(1, SysStats.temp / 100), text: Math.round(SysStats.temp) + "°", tone: SysStats.temp > 85 ? Theme.danger : Theme.tertiary },
    ].concat(Status.hasBattery ? [{ icon: Status.charging ? "bolt" : "battery_full", label: "Battery", value: Status.charge,
        text: Math.round(Status.charge * 100) + "%", tone: Status.charge < 0.15 && !Status.charging ? Theme.danger : Theme.primary }] : [])

    Row {
        visible: c.look === "rings"
        anchors.centerIn: parent
        spacing: 12
        Repeater {
            model: c.stats
            Ring {
                required property var modelData
                value: modelData.value; icon: modelData.icon; label: modelData.label
                text: modelData.label === "Memory" ? SysStats.memUsedGb.toFixed(1) : modelData.text
                tone: modelData.tone
            }
        }
    }

    Column {
        visible: c.look === "bars"
        x: 20; y: 18
        width: parent.width - 40
        spacing: 12
        Repeater {
            model: c.stats
            Item {
                required property var modelData
                width: parent.width; height: 26
                Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.modelData.icon; size: 18; fill: 1; color: parent.modelData.tone }
                Txt { x: 28; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; size: 12; color: Theme.inkDim }
                Rectangle {
                    id: meter
                    x: 96; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 96 - 62; height: 8; radius: 4
                    color: Theme.surfaceHighest
                    Rectangle {
                        width: Math.max(8, meter.width * Math.min(1, parent.parent.modelData.value)); height: 8; radius: 4
                        color: parent.parent.modelData.tone
                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                    }
                }
                Txt { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: parent.modelData.text; size: 12; weight: Font.Medium; font.features: { "tnum": 1 } }
            }
        }
    }

    Row {
        id: chips
        visible: c.look === "chips"
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            model: c.stats
            Rectangle {
                required property var modelData
                height: 36; radius: 18
                width: chipRow.implicitWidth + 22
                color: Theme.alpha(Theme.surfaceHigh, 0.7)
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.parent.modelData.icon; size: 16; fill: 1; color: parent.parent.modelData.tone }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.modelData.text; size: 12; weight: Font.Medium; font.features: { "tnum": 1 } }
                }
            }
        }
    }
}
