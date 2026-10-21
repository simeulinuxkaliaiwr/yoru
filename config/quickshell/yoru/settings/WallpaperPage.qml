import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.wallpaper
    readonly property bool skwd: c.backend === "skwd"

    // skwd-wall's own settings, as `yoru skwd get` reads them (null: skwd's default)
    property var k: ({})
    onSkwdChanged: if (skwd) skwdGet.running = true
    Component.onCompleted: if (skwd) skwdGet.running = true
    Process {
        id: skwdGet
        command: ["yoru", "skwd", "get"]
        stdout: StdioCollector { onStreamFinished: { try { k = JSON.parse(text); } catch (e) {} } }
    }
    // shown at once, written once a slider settles: skwd's daemon reloads on every write
    property var pending: ({})
    function kset(path, value) {
        const n = Object.assign({}, k);
        n[path] = value;
        k = n;
        pending[path] = value;
        flush.restart();
    }
    Timer {
        id: flush
        interval: 400
        onTriggered: {
            // the config's in one go: two writers at once would lose one of them
            let set = [];
            for (const path in pending) {
                const v = pending[path];
                if (path === "volume")
                    Quickshell.execDetached(["skwd-helm", "volume", String(v)]);
                else if (path === "mute")
                    Quickshell.execDetached(["skwd-helm", v ? "mute" : "unmute"]);
                else
                    set.push(path, JSON.stringify(v));
            }
            if (set.length)
                Quickshell.execDetached(["yoru", "skwd", "set"].concat(set));
            pending = {};
        }
    }
    // skwd's transitions (skwd-wall-v2's list); the sand ones are slow to start
    readonly property var skwdShaders: ["crossfade", "fadecolor", "colour-distance", "perlin", "smoke", "soft-warp-fade",
        "pixelfade-wave", "directional", "directional-scaled", "circle-crop", "squares", "polka-dots-curtain",
        "puzzle-right", "ink-splash", "inkwell-drop", "crosshatch", "crosswarp", "morph", "heat-melt", "plasma-flow",
        "zoom-blur-pull", "chromatic-bloom", "glitch", "glitch-displace", "parametric-glitch", "mosaic-tumble",
        "voronoi-shatter", "random"]
    readonly property var skwdSand: ["sand-bloom", "sand-donut", "sand-galaxy", "sand-globe", "sand-helix",
        "sand-maelstrom", "sand-mobius", "sand-tornado"]
    function nice(n) { return n === "random" ? "Random" : (n[0].toUpperCase() + n.slice(1)).replace(/-/g, " "); }

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
            icon: "keyboard"; label: "mod+w opens"; hint: "Either picker re-themes yoru: yoru's shows your folders, skwd-wall's its whole library"
        }
        Choice {
            visible: skwd
            x: 10; width: parent.width - 20
            options: [
                { value: "yoru", label: "yoru's picker", icon: "nights_stay" },
                { value: "skwd", label: "skwd-wall's picker", icon: "view_carousel" }
            ]
            current: c.picker
            onPicked: v => c.picker = v
        }
        SetRow {
            visible: skwd
            icon: "photo_library"; label: "skwd-wall"; hint: "Its picker, the mixer (one wallpaper per screen), and its own settings: effects, playlists, schedules, Wallpaper Engine"
            Row {
                spacing: 8
                Btn { icon: "view_carousel"; label: "Picker"; tonal: true; onClicked: Quickshell.execDetached(["skwd-wall-v2"]) }
                Btn { icon: "tune"; label: "Mixer"; tonal: true; onClicked: Quickshell.execDetached(["skwd-wall-v2", "--mixer"]) }
                Btn {
                    icon: "settings"; label: "Settings"; tonal: true
                    // its settings open from a running picker
                    onClicked: Quickshell.execDetached(["sh", "-c", "skwd-helm ui open settings >/dev/null 2>&1 || { skwd-wall-v2 & for i in $(seq 40); do sleep 0.25; skwd-helm ui open settings >/dev/null 2>&1 && break; done; }"])
                }
            }
        }
        SetRow {
            visible: skwd && k.installed === true && k.running === false
            icon: "warning"; label: "skwd-wall's daemon isn't running"; hint: "Pick skwd-wall above again to start it"
        }
        Item { width: 1; height: 8 }

        Process {
            id: backend
            property string error: ""
            stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") backend.error = text.trim().split("\n")[0].replace(/^yoru: /, "") }
        }
    }

    Section {
        visible: skwd
        icon: "animation"; title: "Transitions (skwd-wall)"
        SetRow {
            icon: "animation"; label: "Animate changes"; hint: "Off cuts straight to the next wallpaper: the quickest"
            Toggle { checked: k["transition.enabled"] !== false; onToggled: on => kset("transition.enabled", on) }
        }
        SetRow {
            visible: k["transition.enabled"] !== false
            icon: "timer"; label: "Duration"
            hint: skwdSand.includes(k["transition.shader"]) ? "Sand needs 4000 ms or more for the grains to show" : ""
            Range { value: k["transition.durationMs"] ?? 1000; from: 100; to: 8000; step: 100; suffix: " ms"; onMoved: v => kset("transition.durationMs", v) }
        }
        SetRow { visible: k["transition.enabled"] !== false; icon: "auto_awesome"; label: "Transition"; hint: "Fades, wipes, warps and break-ups: they start at once" }
        Choice {
            visible: k["transition.enabled"] !== false
            x: 10; width: parent.width - 20
            options: skwdShaders.map(n => ({ value: n, label: nice(n), icon: n === "random" ? "casino" : "" }))
            current: k["transition.shader"] ?? ""
            onPicked: v => kset("transition.shader", v)
        }
        SetRow {
            visible: k["transition.enabled"] !== false
            icon: "grain"; label: "Sand"; hint: "Every pixel becomes a grain and flies into a shape. Beautiful, but it takes a second or two to get going, and it's heavy on a laptop"
        }
        Choice {
            visible: k["transition.enabled"] !== false
            x: 10; width: parent.width - 20
            options: skwdSand.map(n => ({ value: n, label: nice(n).replace(/^Sand /, ""), icon: "" }))
            current: k["transition.shader"] ?? ""
            onPicked: v => kset("transition.shader", v)
        }
        SetRow {
            visible: k["transition.enabled"] !== false && skwdSand.includes(k["transition.shader"])
            icon: "speed"; label: "Sand quality"; hint: "Auto is full on a graphics card and low on integrated graphics (30 fps, about 4.5x cheaper)"
        }
        Choice {
            visible: k["transition.enabled"] !== false && skwdSand.includes(k["transition.shader"])
            x: 10; width: parent.width - 20
            options: [{ value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "low", label: "Low" }]
            current: k["transition.sandQuality"] ?? "auto"
            onPicked: v => kset("transition.sandQuality", v)
        }
        Item { width: 1; height: 8 }
    }

    Section {
        visible: skwd
        icon: "volume_up"; title: "Sound and power (skwd-wall)"
        SetRow {
            icon: "music_note"; label: "Video sound"; hint: "Live wallpapers with their own audio"
            Toggle { checked: k.mute === false; onToggled: on => kset("mute", !on) }
        }
        SetRow {
            visible: k.mute === false
            icon: "volume_up"; label: "Volume"
            Range { value: k.volume ?? 100; from: 0; to: 100; step: 5; suffix: "%"; onMoved: v => kset("volume", v) }
        }
        SetRow {
            icon: "battery_saver"; label: "Battery saver"; hint: "On battery, live wallpapers run at a lower frame rate"
            Toggle { checked: k["performance.batterySaver"] === true; onToggled: on => kset("performance.batterySaver", on) }
        }
        SetRow {
            icon: "bedtime"; label: "Pause when idle"; hint: "Stops videos after this long without input; 0 never"
            Range { value: k["paper.idlePauseSeconds"] ?? 0; from: 0; to: 600; step: 30; suffix: " s"; onMoved: v => kset("paper.idlePauseSeconds", v) }
        }
        Item { width: 1; height: 8 }
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
        SetRow {
            icon: "public"; label: "Source"
            hint: c.online.source === "motionbgs" ? "A random live wallpaper, a looping video" : "A random picture, safe for work, at least 1920x1080"
        }
        Choice {
            x: 10; width: parent.width - 20
            options: [
                { value: "wallhaven", label: "Wallhaven", icon: "landscape" },
                { value: "konachan", label: "Konachan", icon: "draw" },
                { value: "motionbgs", label: "MotionBgs", icon: "animation" }
            ]
            current: c.online.source
            onPicked: v => c.online.source = v
        }
        SetRow {
            visible: c.online.source === "motionbgs"
            icon: "high_quality"; label: "Quality"; hint: "4K is several times the download, and the battery; HD when there's no 4K"
        }
        Choice {
            visible: c.online.source === "motionbgs"
            x: 10; width: parent.width - 20
            options: [
                { value: "hd", label: "HD", icon: "hd" },
                { value: "4k", label: "4K", icon: "4k" }
            ]
            current: c.online.quality
            onPicked: v => c.online.quality = v
        }
        SetRow {
            icon: "search"; label: "Search"; hint: c.online.source === "konachan" ? "Tags or a name, like night sky or kasane teto; commas between several" : "Words, like night city; empty for anything"
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
            icon: "pause_circle"; label: "Pause videos under windows"; hint: "Saves battery: off keeps live wallpapers playing behind your windows"
            Toggle { checked: c.pauseCovered; onToggled: on => c.pauseCovered = on }
        }
        SetRow {
            icon: "schedule"; label: "Change every"; hint: "0 keeps the wallpaper until you change it"
            Range { value: c.rotateMinutes; from: 0; to: 180; step: 5; suffix: " min"; onMoved: v => c.rotateMinutes = v }
        }
        // two clocks changing the wallpaper would fight
        SetRow {
            visible: skwd && (k["general.randomRotate"] === true || k["schedule.enabled"] === true)
            icon: "sync_problem"; label: "skwd-wall changes it on its own too"
            hint: "Its random rotation or schedule is on. With yoru's timer or time of day as well, the wallpaper changes twice"
            Btn {
                icon: "nights_stay"; label: "Leave it to yoru"
                onClicked: { kset("general.randomRotate", false); kset("schedule.enabled", false); }
            }
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
