import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.island

    Section {
        icon: "toolbar"; title: "The island"
        SetRow { icon: "schedule"; label: "24-hour clock"; Toggle { checked: c.clock24; onToggled: on => c.clock24 = on } }
        SetRow { icon: "music_note"; label: "Now playing"; hint: "The island grows to show the track"; Toggle { checked: c.showMedia; onToggled: on => c.showMedia = on } }
        SetRow { icon: "battery_5_bar"; label: "Battery percentage"; Toggle { checked: c.batteryPercent; onToggled: on => c.batteryPercent = on } }
        SetRow {
            icon: "view_week"; label: "Workspaces"
            Choice { width: 200; current: c.workspaces; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }]; onPicked: v => c.workspaces = v }
        }
        SetRow {
            icon: "notifications"; label: "Notifications stay for"
            Range { value: c.toastSeconds; from: 2; to: 15; step: 1; suffix: " s"; onMoved: v => c.toastSeconds = v }
        }
    }
}
