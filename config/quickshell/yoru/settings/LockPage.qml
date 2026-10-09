import Quickshell
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.lock

    Section {
        icon: "lock"; title: "Lock screen"
        SetRow { icon: "blur_on"; label: "Blur"; Range { value: c.blur; from: 0; to: 1; step: 0.05; decimals: 0; shownScale: 100; suffix: "%"; onMoved: v => c.blur = v } }
        SetRow { icon: "contrast"; label: "Dim"; Range { value: c.dim; from: 0; to: 0.8; step: 0.05; decimals: 0; shownScale: 100; suffix: "%"; onMoved: v => c.dim = v } }
        SetRow {
            icon: "format_size"; label: "Clock style"
            Choice { width: 300; current: c.clockStyle; options: [{ value: "thin", label: "Thin" }, { value: "bold", label: "Bold" }, { value: "stacked", label: "Stacked" }]; onPicked: v => c.clockStyle = v }
        }
        SetRow { icon: "album"; label: "Media controls"; Toggle { checked: c.media; onToggled: on => c.media = on } }
        SetRow { icon: "power_settings_new"; label: "Power buttons"; hint: "Sleep, restart and shut down from the lock screen"; Toggle { checked: c.power; onToggled: on => c.power = on } }
        SetRow {
            icon: "hourglass"; label: "Lock when idle for"; hint: "Applies the next time you switch to yoru or log in"
            Range { value: c.lockAfterMinutes; from: 1; to: 60; step: 1; suffix: " min"; onMoved: v => c.lockAfterMinutes = v }
        }
        SetRow {
            icon: "lock_clock"; label: "Try it"
            Btn { icon: "lock"; label: "Lock now"; onClicked: Quickshell.execDetached(["yoru-lock"]) }
        }
    }
}
