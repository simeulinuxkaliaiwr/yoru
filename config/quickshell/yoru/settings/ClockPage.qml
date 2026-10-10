import Quickshell
import QtQuick
import qs
import qs.parts
import qs.desktop

Column {
    spacing: 14
    readonly property var c: Config.o.desktop
    readonly property bool placed: Desk.custom && c.clockPlaced

    // placed by hand: the clock is a widget in edit mode now
    Section {
        visible: placed
        icon: "schedule"; title: "Clock"
        Txt { x: 10; width: parent.width - 20; wrapMode: Text.Wrap; size: 13; color: Theme.inkDim
              text: "Your clock is a placed widget now: move it, size it and pick its style in edit mode. Add more from the palette (Clock), or remove it there." }
        Item { width: 1; height: 8 }
        Btn { x: 10; icon: "edit"; label: "Edit on the desktop"; onClicked: Quickshell.execDetached(["qs", "-c", "yoru", "ipc", "call", "desktop", "edit"]) }
        Item { width: 1; height: 8 }
    }

    Section {
        visible: !placed
        icon: "preview"; title: "Preview"
        ScreenPreview {
            x: 10
            ClockFace {
                id: face
                visible: c.clock
                style: c.clockStyle
                centred: c.clockPosition === "center"
                x: centred ? (1920 - width) / 2 : 64
                y: centred ? (1080 - height) / 2 - 40 : c.clockPosition === "top-left" ? 70 : 1080 - height - 56
            }
        }
        Item { width: 1; height: 10 }
    }


    Section {
        visible: !placed
        icon: "schedule"; title: "Clock"
        SetRow { icon: "visibility"; label: "Show the clock"; Toggle { checked: c.clock; onToggled: on => c.clock = on } }
        SetRow { icon: "format_size"; label: "Style" }
        Choice {
            x: 10; current: c.clockStyle
            options: [{ value: "thin", label: "Thin" }, { value: "bold", label: "Bold" }, { value: "stacked", label: "Stacked" },
                      { value: "outline", label: "Outline" }, { value: "mono", label: "Mono" }, { value: "split", label: "Split" },
                      { value: "words", label: "Words" }, { value: "kanji", label: "漢字" }, { value: "serif", label: "Serif" },
                      { value: "analog", label: "Analog" }]
            onPicked: v => c.clockStyle = v
        }
        SetRow { icon: "picture_in_picture"; label: "Position" }
        Choice {
            x: 10; current: c.clockPosition
            options: [{ value: "bottom-left", label: "Bottom left" }, { value: "center", label: "Centre" }, { value: "top-left", label: "Top left" }]
            onPicked: v => c.clockPosition = v
        }
        Item { width: 1; height: 8 }
    }
}
