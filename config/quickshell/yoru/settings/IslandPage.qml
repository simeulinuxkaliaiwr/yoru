import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.island
    readonly property var l: Config.o.launcher
    readonly property var a: Config.o.anime

    Section {
        icon: "toolbar"; title: "The island"
        SetRow { icon: "schedule"; label: "24-hour clock"; Toggle { checked: c.clock24; onToggled: on => c.clock24 = on } }
        SetRow { icon: "music_note"; label: "Now playing"; hint: "The island grows to show the track"; Toggle { checked: c.showMedia; onToggled: on => c.showMedia = on } }
        SetRow {
            visible: c.showMedia
            icon: "lyrics"; label: "Sing along"; hint: "While it plays, the line being sung instead of the title (from lrclib.net)"
            Toggle { checked: c.lyrics; onToggled: on => c.lyrics = on }
        }
        SetRow { icon: "battery_5_bar"; label: "Battery percentage"; Toggle { checked: c.batteryPercent; onToggled: on => c.batteryPercent = on } }
        SetRow {
            icon: "pets"; label: "A cat on the island"; hint: "It sleeps, wakes for notifications, bobs to the music and curls up while you focus; click it"
            Toggle { checked: c.pet === "cat"; onToggled: on => c.pet = on ? "cat" : "off" }
        }
        SetRow {
            icon: "view_week"; label: "Workspaces"
            Choice { width: 200; current: c.workspaces; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }]; onPicked: v => c.workspaces = v }
        }
    }

    Section {
        icon: "apps"; title: "Launcher"
        SetRow { icon: "keyboard_command_key"; label: "mod+a opens"; hint: l.style === "ring" ? "Your apps in a ring: point and click, or type to search" : "The island's list: type to search apps, emoji, the web" }
        Choice {
            x: 10
            current: l.style
            options: [{ value: "list", label: "List", icon: "view_list" }, { value: "ring", label: "Ring", icon: "radio_button_unchecked" }]
            onPicked: v => l.style = v
        }
        SetRow {
            icon: "terminal"; label: "Terminal apps open in"; hint: "For apps like nvim, yazi and htop; foot also names the window after the app"
            Field { width: 200; text: l.terminal; placeholder: "foot"; onEdited: t => l.terminal = t.trim() }
        }
        SetRow {
            visible: l.style === "ring"
            icon: "my_location"; label: "Ring opens"
            Choice { width: 480; current: l.ringAt; options: [{ value: "pointer", label: "At the pointer" }, { value: "island", label: "Under the island" }, { value: "center", label: "In the middle" }]; onPicked: v => l.ringAt = v }
        }
        SetRow {
            visible: l.style === "ring"
            icon: "animation"; label: "Grow out of the island"; hint: "The island flies down and opens into the ring, and folds back up after"
            Toggle { checked: l.ringMorph; onToggled: on => l.ringMorph = on }
        }
        SetRow {
            visible: l.style === "ring"
            icon: "flare"; label: "Glowing icons"; hint: "Each app glows in its own colours, brightest where you point"
            Toggle { checked: l.ringGlow; onToggled: on => l.ringGlow = on }
        }
        SetRow {
            visible: l.style === "ring"
            icon: "push_pin"; label: "Ring apps"
            hint: "Desktop ids, separated by commas; empty for the ones you open most. Right-click one on the ring to take it off"
            Field {
                width: 300
                text: l.ringApps.join(", ")
                placeholder: "the ones you open most"
                onEdited: t => l.ringApps = t.split(/[,\s]+/).map(x => x.replace(/\.desktop$/, "")).filter(x => x !== "")
            }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "draw"; title: "Anime pictures"
        SetRow {
            icon: "keyboard_command_key"; label: "mod+u opens"
            hint: "Pictures from image boards by tag: Tab takes the tag it suggests, Enter opens one large, Ctrl+S saves it, Ctrl+B makes it the wallpaper"
        }
        SetRow {
            icon: "travel_explore"; label: "Board"
            hint: ({ danbooru: "The biggest, carefully tagged; two tags at a time without an account",
                     safebooru: "Danbooru's safe pictures, mirrored, with no limit on tags",
                     yandere: "Big, clean scans and art; its \"safe\" is a lenient one",
                     konachan: "Wallpaper-sized pictures, mostly landscape" })[a.source] ?? ""
        }
        Choice {
            x: 10
            current: a.source
            options: [{ value: "danbooru", label: "Danbooru", icon: "draw" }, { value: "safebooru", label: "Safebooru", icon: "shield" },
                      { value: "yandere", label: "yande.re", icon: "brush" }, { value: "konachan", label: "Konachan", icon: "landscape" }]
            onPicked: v => a.source = v
        }
        SetRow {
            icon: "sort"; label: "Order"
            Choice { width: 330; current: a.order; options: [{ value: "new", label: "Newest" }, { value: "top", label: "Top" }, { value: "random", label: "Random" }]; onPicked: v => a.order = v }
        }
        SetRow {
            icon: "dashboard"; label: "Layout"
            hint: ({ masonry: "Each picture its own shape, in columns", grid: "Even squares, row by row", strip: "One row of tall pictures, the one you're on in the middle" })[a.layout] ?? ""
        }
        Choice {
            x: 10
            current: a.layout
            options: [{ value: "masonry", label: "Masonry", icon: "dashboard" }, { value: "grid", label: "Grid", icon: "grid_view" }, { value: "strip", label: "Strip", icon: "view_carousel" }]
            onPicked: v => a.layout = v
        }
        SetRow {
            icon: "explicit"; label: "Not safe for work too"
            hint: a.nsfw ? "Every rating each board has: questionable and explicit pictures as well"
                         : "Off: only what Danbooru and Safebooru call general, and yande.re and Konachan safe"
            Toggle { checked: a.nsfw; onToggled: on => a.nsfw = on }
        }
        SetRow {
            visible: a.nsfw
            icon: "blur_on"; label: "Blur those"; hint: "Questionable and explicit ones stay blurred until the pointer's on one, or you open it"
            Toggle { checked: a.blur; onToggled: on => a.blur = on }
        }
        SetRow {
            icon: "folder"; label: "Saved to"
            Field { width: 260; text: a.folder; placeholder: "~/Pictures/Anime"; onEdited: t => a.folder = t.trim() || "~/Pictures/Anime" }
        }
        SetRow {
            icon: "push_pin"; label: "Pinned searches"; hint: "Ctrl+P in the view pins what's typed; they wait under the field. Separated by semicolons"
            Field {
                width: 260
                text: a.pinned.join("; ")
                placeholder: "none yet"
                onEdited: t => a.pinned = t.split(";").map(x => x.trim()).filter(x => x !== "")
            }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "content_paste"; title: "Clipboard"
        SetRow {
            icon: "content_paste_go"; label: "Enter pastes into your window"
            hint: Config.o.clip.paste ? "Into the window you were in (with wtype); Shift+Enter only copies" : "Enter only copies"
            Toggle { checked: Config.o.clip.paste; onToggled: on => Config.o.clip.paste = on }
        }
    }
}
