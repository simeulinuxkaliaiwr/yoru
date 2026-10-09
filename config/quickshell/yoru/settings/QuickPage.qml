import Quickshell
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
                radius: 20
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
            icon: "speed"; label: "Animation speed"; hint: "Everything in the shell, from the island to the wallpaper"
            Range { value: c.appearance.speed; from: 0.5; to: 2; step: 0.1; decimals: 1; suffix: "×"; onMoved: v => c.appearance.speed = v }
        }
    }
    // the file is written a moment after the change; recolour after that
    Timer { id: recolour; interval: 300; onTriggered: Quickshell.execDetached(["yoru"]) }

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
