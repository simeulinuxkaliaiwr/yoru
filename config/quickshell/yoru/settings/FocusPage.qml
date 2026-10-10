import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.island

    Section {
        icon: "timer"; title: "Focus timer"
        SetRow { icon: "hourglass_top"; label: "Focus for"; Range { value: Config.o.focus.minutes; from: 5; to: 90; step: 5; suffix: " min"; onMoved: v => Config.o.focus.minutes = v } }
        SetRow { icon: "self_improvement"; label: "Then a break of"; hint: "0 for none"; Range { value: Config.o.focus.breakMinutes; from: 0; to: 30; step: 1; suffix: " min"; onMoved: v => Config.o.focus.breakMinutes = v } }
        SetRow { icon: "notifications_paused"; label: "Hold notifications while focusing"; Toggle { checked: Config.o.focus.quiet; onToggled: on => Config.o.focus.quiet = on } }
        SetRow { icon: "music_off"; label: "Pause the music for breaks"; hint: "It plays again when the break ends"; Toggle { checked: Config.o.focus.music; onToggled: on => Config.o.focus.music = on } }
        SetRow { icon: "repeat"; label: "Keep going in rounds"; hint: "Focus again after each break, until you stop it"; Toggle { checked: Config.o.focus.rounds; onToggled: on => Config.o.focus.rounds = on } }
    }

    Section {
        icon: "bedtime"; title: "Quiet hours"
        SetRow { icon: "do_not_disturb_on"; label: "Do not disturb at night"; hint: "Critical notifications still come through"; Toggle { checked: Config.o.quiet.schedule; onToggled: on => Config.o.quiet.schedule = on } }
        SetRow { icon: "dark_mode"; label: "From"; Field { width: 120; text: Config.o.quiet.from; placeholder: "23:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.quiet.from = t; } } }
        SetRow { icon: "light_mode"; label: "Until"; Field { width: 120; text: Config.o.quiet.to; placeholder: "07:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.quiet.to = t; } } }
    }
}
