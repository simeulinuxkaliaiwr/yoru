import QtQuick
import qs
import qs.parts

Card {
    height: 124
    Component.onCompleted: SysStats.watchers++
    Component.onDestruction: SysStats.watchers--

    Row {
        anchors.centerIn: parent
        spacing: 12
        Ring { value: SysStats.cpu; icon: "memory"; label: "CPU"; text: Math.round(SysStats.cpu * 100) + "%" }
        Ring { value: SysStats.mem; icon: "memory_alt"; label: "Memory"; text: SysStats.memUsedGb.toFixed(1); tone: Theme.secondary }
        Ring {
            value: Math.min(1, SysStats.temp / 100); icon: "thermostat"; label: "Heat"; text: Math.round(SysStats.temp) + "°"
            tone: SysStats.temp > 85 ? Theme.danger : Theme.tertiary
        }
        Ring {
            visible: Status.hasBattery
            value: Status.charge; icon: Status.charging ? "bolt" : "battery_full"; label: "Battery"; text: Math.round(Status.charge * 100) + "%"
            tone: Status.charge < 0.15 && !Status.charging ? Theme.danger : Theme.primary
        }
    }
}
