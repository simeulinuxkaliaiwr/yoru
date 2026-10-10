import Quickshell
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.wallpaper

    Section {
        icon: "animation"; title: "Transitions"
        SetRow {
            icon: "timer"; label: "Duration"
            Range { value: c.duration; from: 300; to: 4000; step: 100; suffix: " ms"; onMoved: v => c.duration = v }
        }
        SetRow {
            icon: "blur_on"; label: "Edge softness"; hint: "Hard lines at 0, a wide soft blend at 1"
            Range { value: c.smoothness; from: 0; to: 1; step: 0.05; decimals: 2; onMoved: v => c.smoothness = v }
        }
        SetRow { icon: "casino"; label: "Random picks from"; hint: "Used when the transition is Random" }
        Choice {
            x: 10; width: parent.width - 20
            readonly property var all: ["ripple", "fade", "wipe", "disc", "stripes", "zoom", "honeycomb", "pixelate"]
            options: all.map(n => ({ value: n, label: n[0].toUpperCase() + n.slice(1), icon: c.pool.includes(n) ? "check" : "" }))
            current: ""
            onPicked: v => { c.pool = c.pool.includes(v) ? (c.pool.length > 1 ? c.pool.filter(x => x !== v) : c.pool) : c.pool.concat([v]); }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "weather_snowy"; title: "Sky"
        SetRow { icon: "cloud"; label: "Over the wallpaper"; hint: "Weather follows the sky outside, with an aurora on clear nights" }
        Choice {
            x: 10; width: parent.width - 20
            options: [
                { value: "weather", label: "Weather", icon: "partly_cloudy_night" },
                { value: "snow", label: "Snow", icon: "weather_snowy" },
                { value: "rain", label: "Rain", icon: "rainy" },
                { value: "aurora", label: "Aurora", icon: "auto_awesome" },
                { value: "fog", label: "Fog", icon: "foggy" },
                { value: "storm", label: "Storm", icon: "thunderstorm" },
                { value: "off", label: "Off", icon: "block" }
            ]
            current: c.sky
            onPicked: v => c.sky = v
        }
        SetRow {
            icon: "grain"; label: "Amount"; hint: "A few flakes at 0, a blizzard at 1"
            Range { value: c.skyAmount; from: 0; to: 1; step: 0.05; decimals: 2; onMoved: v => c.skyAmount = v }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "wallpaper"; title: "Behaviour"
        SetRow {
            icon: "3d_rotation"; label: "Parallax"; hint: "The wallpaper drifts as you move between workspaces"
            Toggle { checked: c.parallax; onToggled: on => c.parallax = on }
        }
        SetRow {
            icon: "motion_photos_on"; label: "Colours follow the video"; hint: "The island and widgets drift with a live wallpaper's scenes"
            Toggle { checked: c.liveColours; onToggled: on => c.liveColours = on }
        }
        SetRow {
            icon: "pause_circle"; label: "Pause videos under windows"; hint: "Saves battery: off keeps live wallpapers playing behind your windows"
            Toggle { checked: c.pauseCovered; onToggled: on => c.pauseCovered = on }
        }
        SetRow {
            icon: "schedule"; label: "Change every"; hint: "0 keeps the wallpaper until you change it"
            Range { value: c.rotateMinutes; from: 0; to: 180; step: 5; suffix: " min"; onMoved: v => c.rotateMinutes = v }
        }
        SetRow {
            icon: "shuffle"; label: "Shuffle"; hint: "Pick at random when it changes on its own, instead of in order"
            Toggle { checked: c.shuffle; onToggled: on => c.shuffle = on }
        }
        SetRow {
            icon: "folder"; label: "Folders"; hint: "Separated by commas"
            Field { width: 320; text: c.dirs.join(", "); onEdited: t => c.dirs = t.split(",").map(s => s.trim()).filter(s => s !== "") }
        }
    }
}
