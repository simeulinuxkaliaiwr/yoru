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
        SetRow { icon: "format_size"; label: "Clock style" }
        Choice {
            x: 10; current: c.clockStyle
            options: [{ value: "thin", label: "Thin" }, { value: "bold", label: "Bold" }, { value: "stacked", label: "Stacked" },
                      { value: "outline", label: "Outline" }, { value: "mono", label: "Mono" }, { value: "split", label: "Split" },
                      { value: "words", label: "Words" }, { value: "kanji", label: "漢字" }, { value: "serif", label: "Serif" },
                      { value: "analog", label: "Analog" }]
            onPicked: v => c.clockStyle = v
        }
        Item { width: 1; height: 6 }
        SetRow {
            icon: "password"; label: "Password characters"; hint: "Shapes take turns and settle from the accent colour"
            Choice { width: 220; current: c.chars; options: [{ value: "shapes", label: "Shapes" }, { value: "dots", label: "Dots" }]; onPicked: v => c.chars = v }
        }
        SetRow { icon: "album"; label: "Media controls"; Toggle { checked: c.media; onToggled: on => c.media = on } }
        SetRow { icon: "partly_cloudy_day"; label: "The weather"; hint: "Under the clock"; Toggle { checked: c.weather; onToggled: on => c.weather = on } }
        SetRow { icon: "notifications"; label: "How many notifications came"; hint: "A count by the battery; never what they say"; Toggle { checked: c.notifications; onToggled: on => c.notifications = on } }
        SetRow { icon: "power_settings_new"; label: "Power buttons"; hint: "Sleep, restart and shut down from the lock screen"; Toggle { checked: c.power; onToggled: on => c.power = on } }
        SetRow {
            icon: "hourglass"; label: "Lock when idle for"
            Range { value: c.lockAfterMinutes; from: 1; to: 60; step: 1; suffix: " min"; onMoved: v => c.lockAfterMinutes = v }
        }
        SetRow {
            icon: "lock_clock"; label: "Warn before locking"; hint: c.warnSeconds > 0 ? "The screen dims and the island counts down; move or type to stay" : "Off: it locks without a warning"
            Range { value: c.warnSeconds; from: 0; to: 60; step: 5; suffix: " s"; onMoved: v => c.warnSeconds = v }
        }
        SetRow {
            icon: "lock_clock"; label: "Try it"
            Btn { icon: "lock"; label: "Lock now"; onClicked: Quickshell.execDetached(["yoru-lock"]) }
        }
    }
}
