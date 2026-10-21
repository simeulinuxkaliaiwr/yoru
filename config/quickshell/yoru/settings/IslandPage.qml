import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.island
    readonly property var l: Config.o.launcher

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
}
