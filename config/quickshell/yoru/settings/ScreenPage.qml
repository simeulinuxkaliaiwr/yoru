import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var n: Config.o.night

    Section {
        icon: "nightlight"; title: "Night light"
        SetRow {
            icon: "thermostat"; label: "Warmth"; hint: "Lower is warmer; the control centre's tile turns it on"
            Range { value: n.warmth; from: 2500; to: 6000; step: 100; suffix: " K"; onMoved: v => n.warmth = v }
        }
        SetRow { icon: "wb_twilight"; label: "Comes on by itself" }
        Choice {
            x: 10; current: n.auto
            options: [{ value: "off", label: "No, only by hand" }, { value: "sun", label: "Sunset to sunrise" }, { value: "hours", label: "Between two hours" }]
            onPicked: v => n.auto = v
        }
        Item { width: 1; height: 6 }
        // (no live state here: Status in this window would start a second wlsunset)
        SetRow {
            visible: n.auto === "sun"
            icon: "location_on"; label: "By the sun"
            hint: "Sunset and sunrise where the weather is for (Settings → Weather); it fades in and out over half an hour"
        }
        SetRow {
            visible: n.auto === "hours"
            icon: "dark_mode"; label: "From"
            Field { width: 120; text: n.from; placeholder: "21:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) n.from = t; } }
        }
        SetRow {
            visible: n.auto === "hours"
            icon: "light_mode"; label: "Until"
            Field { width: 120; text: n.to; placeholder: "07:00"; onEdited: t => { if (/^\d{1,2}:\d{2}$/.test(t)) n.to = t; } }
        }
    }

    Section {
        icon: "battery_5_bar"; title: "Battery"
        SetRow { icon: "energy_savings_leaf"; label: "Battery saver"; hint: "The sky, the video wallpaper and the visualizer rest, and come back when you plug in" }
        Choice {
            x: 10; current: Config.o.power.saver
            options: [{ value: "battery", label: "On battery" }, { value: "low", label: "Below 20%" }, { value: "off", label: "Never" }]
            onPicked: v => Config.o.power.saver = v
        }
        Item { width: 1; height: 6 }
        SetRow {
            icon: "battery_charging_full"; label: "Show the charge when you plug in"; hint: "In the island, for a moment"
            Toggle { checked: Config.o.power.chargeFlash; onToggled: on => Config.o.power.chargeFlash = on }
        }
    }
}
