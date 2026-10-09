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
