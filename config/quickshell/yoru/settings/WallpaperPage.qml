import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.wallpaper
    readonly property bool skwd: c.backend === "skwd"

    Section {
        icon: "brush"; title: "Drawn by"
        SetRow {
            icon: "layers"; label: "Wallpaper backend"
            hint: backend.error !== "" ? backend.error
                : skwd ? "skwd-wall v2 draws it, with its own transitions; yoru still takes its colours, and follows what you pick in skwd's picker"
                : "yoru draws it itself: transitions, parallax and the sky"
        }
        Choice {
            x: 10; width: parent.width - 20
            options: [
                { value: "yoru", label: "yoru", icon: "nights_stay" },
                { value: "skwd", label: "skwd-wall", icon: "view_carousel" }
            ]
            current: c.backend
            // the engine writes the setting once skwd's daemon is set up (or stopped)
            onPicked: v => {
                if (v === c.backend || backend.running)
                    return;
                backend.error = "";
                backend.command = ["yoru", "backend", v];
                backend.running = true;
            }
        }
        SetRow {
            visible: skwd
            icon: "photo_library"; label: "skwd-wall's picker"; hint: "Its slices, hexes and library; what you pick there re-themes yoru too"
            Btn { icon: "open_in_new"; label: "Open"; onClicked: Quickshell.execDetached(["skwd-wall-v2"]) }
        }
        Item { width: 1; height: 8 }

        Process {
            id: backend
            property string error: ""
            stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") backend.error = text.trim().split("\n")[0].replace(/^yoru: /, "") }
        }
    }

    Section {
        visible: !skwd
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
        icon: "travel_explore"; title: "From the internet"
        SetRow { icon: "public"; label: "Source"; hint: "A random picture, safe for work, at least 1920x1080" }
        Choice {
            x: 10; width: parent.width - 20
            options: [
                { value: "wallhaven", label: "Wallhaven", icon: "landscape" },
                { value: "konachan", label: "Konachan", icon: "draw" }
            ]
            current: c.online.source
            onPicked: v => c.online.source = v
        }
        SetRow {
            icon: "search"; label: "Search"; hint: c.online.source === "konachan" ? "Tags, like night sky (underscores join words)" : "Words, like night city; empty for anything"
            Field { width: 260; text: c.online.search; placeholder: "anything"; onEdited: t => c.online.search = t.trim() }
        }
        SetRow {
            icon: "download"; label: "Save to"; hint: "Keep it among the folders below to see it in the picker"
            Field { width: 260; text: c.online.folder; placeholder: "~/Pictures/Wallpapers"; onEdited: t => c.online.folder = t.trim() }
        }
        SetRow {
            icon: "wallpaper"; label: "Get one"
            hint: fetch.running ? "Downloading…" : fetch.error !== "" ? fetch.error : fetch.got !== "" ? "Saved as " + fetch.got.split("/").pop() : "Downloads it and makes it the wallpaper"
            Btn {
                icon: fetch.running ? "hourglass_top" : "download"
                label: fetch.running ? "Fetching" : "Get wallpaper"
                onClicked: {
                    if (fetch.running)
                        return;
                    forceActiveFocus();   // a field still being typed in saves first
                    fetch.error = "";
                    fetch.got = "";
                    fetch.running = true;
                }
            }
        }
        Item { width: 1; height: 8 }

        Process {
            id: fetch
            property string error: ""
            property string got: ""
            command: ["yoru", "wall", "fetch", c.online.source].concat(c.online.search.split(/\s+/).filter(w => w !== ""))
            stdout: StdioCollector { onStreamFinished: fetch.got = text.trim().split("\n")[0] }
            stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") fetch.error = text.trim().replace(/^yoru: /, "Failed: ") }
        }
    }

    Section {
        visible: !skwd
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
            visible: !skwd
            icon: "3d_rotation"; label: "Parallax"; hint: "The wallpaper drifts as you move between workspaces"
            Toggle { checked: c.parallax; onToggled: on => c.parallax = on }
        }
        SetRow {
            visible: !skwd
            icon: "motion_photos_on"; label: "Colours follow the video"; hint: "The island and widgets drift with a live wallpaper's scenes"
            Toggle { checked: c.liveColours; onToggled: on => c.liveColours = on }
        }
        SetRow {
            visible: !skwd
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
            icon: "routine"; label: "By time of day"; hint: "Dark wallpapers at night, bright ones by day, softer ones at dawn and dusk, by your city's sunrise and sunset"
            Toggle { checked: c.byTime; onToggled: on => c.byTime = on }
        }
        Repeater {
            model: [["dawn", "wb_twilight", "Dawn"], ["day", "light_mode", "Day"], ["evening", "wb_twilight", "Evening"], ["night", "dark_mode", "Night"]]
            SetRow {
                required property var modelData
                visible: c.byTime
                icon: modelData[1]; label: modelData[2] + " folder"; hint: "Empty: picked by brightness from the folders below"
                Field { width: 260; text: c.timeDirs[modelData[0]]; placeholder: "~/Pictures/" + modelData[0]; onEdited: t => c.timeDirs[modelData[0]] = t.trim() }
            }
        }
        SetRow {
            icon: "folder"; label: "Folders"; hint: "Separated by commas"
            Field { width: 320; text: c.dirs.join(", "); onEdited: t => c.dirs = t.split(",").map(s => s.trim()).filter(s => s !== "") }
        }
    }
}
