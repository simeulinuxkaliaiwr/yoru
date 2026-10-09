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

    Section {
        icon: "timer"; title: "Focus timer"
        SetRow { icon: "hourglass_top"; label: "Focus for"; Range { value: Config.o.focus.minutes; from: 5; to: 90; step: 5; suffix: " min"; onMoved: v => Config.o.focus.minutes = v } }
        SetRow { icon: "self_improvement"; label: "Then a break of"; hint: "0 for none"; Range { value: Config.o.focus.breakMinutes; from: 0; to: 30; step: 1; suffix: " min"; onMoved: v => Config.o.focus.breakMinutes = v } }
        SetRow { icon: "notifications_paused"; label: "Hold notifications while focusing"; Toggle { checked: Config.o.focus.quiet; onToggled: on => Config.o.focus.quiet = on } }
    }

    Section {
        icon: "bedtime"; title: "Quiet hours"
        SetRow { icon: "do_not_disturb_on"; label: "Do not disturb at night"; hint: "Critical notifications still come through"; Toggle { checked: Config.o.quiet.schedule; onToggled: on => Config.o.quiet.schedule = on } }
        SetRow { icon: "dark_mode"; label: "From"; Field { width: 120; text: Config.o.quiet.from; placeholder: "23:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.quiet.from = t; } } }
        SetRow { icon: "light_mode"; label: "Until"; Field { width: 120; text: Config.o.quiet.to; placeholder: "07:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.quiet.to = t; } } }
    }
}
