import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o

    Section {
        icon: "format_paint"; title: "Wallpaper & colours"
        Item {
            width: parent.width; height: 230
            ClippingRectangle {
                id: preview
                x: 10; y: 4
                width: 340; height: 200
                radius: Theme.r(20)
                color: Theme.surfaceHigh
                Image {
                    anchors.fill: parent
                    source: Theme.still ? "file://" + Theme.still : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(680, 400)
                    asynchronous: true
                }
            }
            Column {
                anchors { left: preview.right; leftMargin: 20; top: preview.top }
                spacing: 10
                Btn { icon: "photo_library"; label: "Browse wallpapers"; onClicked: Quickshell.execDetached(["qs", "-c", "yoru", "ipc", "call", "island", "toggle", "walls"]) }
                Btn { icon: "shuffle"; label: "Random"; tonal: true; onClicked: Quickshell.execDetached(["yoru", "wall", "random"]) }
                Btn { icon: "skip_next"; label: "Next"; tonal: true; onClicked: Quickshell.execDetached(["yoru", "wall", "next"]) }
                Txt { width: 260; text: Theme.wallpaper.split("/").pop(); size: 12; color: Theme.inkDim }
            }
        }
        SetRow {
            icon: "palette"; label: "Colour scheme"; hint: "How the palette is drawn out of the wallpaper"
        }
        Choice {
            x: 10; width: parent.width - 20
            current: c.appearance.scheme
            options: [
                { value: "scheme-tonal-spot", label: "Tonal spot" }, { value: "scheme-expressive", label: "Expressive" },
                { value: "scheme-vibrant", label: "Vibrant" }, { value: "scheme-content", label: "Content" },
                { value: "scheme-fidelity", label: "Fidelity" }, { value: "scheme-fruit-salad", label: "Fruit salad" },
                { value: "scheme-rainbow", label: "Rainbow" }, { value: "scheme-neutral", label: "Neutral" },
                { value: "scheme-monochrome", label: "Monochrome" }
            ]
            onPicked: v => { c.appearance.scheme = v; recolour.restart(); }
        }
        Item { width: 1; height: 10 }
        SetRow {
            icon: "colorize"; label: "Accent from"
            hint: c.appearance.accent === "main" ? "The colour the wallpaper is mostly made of"
                : "The most vivid colour in it, even a small one"
        }
        Choice {
            x: 10; width: parent.width - 20
            current: c.appearance.accent
            options: [{ value: "vivid", label: "Most vivid" }, { value: "main", label: "Main colour" }]
            onPicked: v => { c.appearance.accent = v; recolour.restart(); }
        }
        Item { width: 1; height: 10 }
        SetRow {
            icon: "album"; label: "Colours from the music"; hint: "While a track with cover art plays, the island and widgets take its colours"
            Toggle { checked: c.appearance.musicColours; onToggled: on => c.appearance.musicColours = on }
        }
        SetRow {
            icon: "speed"; label: "Animation speed"; hint: "Everything in the shell, from the island to the wallpaper"
            Range { value: c.appearance.speed; from: 0.5; to: 2; step: 0.1; decimals: 1; suffix: "×"; onMoved: v => c.appearance.speed = v }
        }
    }
    // the file is written a moment after the change; recolour after that
    Timer { id: recolour; interval: 300; onTriggered: Quickshell.execDetached(["yoru"]) }

    // modes: whole looks from a folder (yoru mode)
    property var modes: []
    Process {
        id: listModes
        running: true
        command: ["yoru", "mode"]
        stdout: StdioCollector {
            onStreamFinished: { try { modes = JSON.parse(this.text).modes; } catch (e) {} }
        }
    }
    Section {
        icon: "auto_awesome"; title: "Mode"
        SetRow {
            icon: "theater_comedy"; label: "A whole look"
            hint: modes.length ? "Colours, type, shapes and wallpapers from a mode instead of the wallpaper's palette"
                               : "None yet: a mode is a folder with a mode.json in ~/.config/yoru/modes"
        }
        Choice {
            x: 10; width: parent.width - 20
            current: c.appearance.mode
            options: [{ value: "", label: "None", icon: "wallpaper" }].concat(modes.map(m => ({ value: m.name, label: m.name.charAt(0).toUpperCase() + m.name.slice(1) })))
            // yoru writes the setting itself, with the mode's wallpapers and hooks
            onPicked: v => Quickshell.execDetached(["yoru", "mode", v === "" ? "off" : v])
        }
    }

    Section {
        icon: "animation"; title: "Wallpaper transition"
        Choice {
            x: 10; width: parent.width - 20
            current: c.wallpaper.transition
            options: [
                { value: "random", label: "Random", icon: "casino" }, { value: "ripple", label: "Ripple" }, { value: "fade", label: "Fade" },
                { value: "wipe", label: "Wipe" }, { value: "disc", label: "Disc" }, { value: "stripes", label: "Stripes" },
                { value: "zoom", label: "Zoom" }, { value: "honeycomb", label: "Honeycomb" }, { value: "pixelate", label: "Pixelate" }
            ]
            onPicked: v => c.wallpaper.transition = v
        }
        Item { width: 1; height: 6 }
        SetRow {
            icon: "play_circle"; label: "Try it"; hint: "Moves to the next wallpaper"
            Btn { label: "Next wallpaper"; tonal: true; onClicked: Quickshell.execDetached(["yoru", "wall", "next"]) }
        }
    }
}
