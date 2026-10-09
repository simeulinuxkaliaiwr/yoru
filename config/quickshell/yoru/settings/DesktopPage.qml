import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.desktop

    Section {
        icon: "schedule"; title: "Clock"
        SetRow { icon: "visibility"; label: "Show the clock"; Toggle { checked: c.clock; onToggled: on => c.clock = on } }
        SetRow { icon: "format_size"; label: "Style" }
        Choice {
            x: 10; current: c.clockStyle
            options: [{ value: "thin", label: "Thin" }, { value: "bold", label: "Bold" }, { value: "stacked", label: "Stacked" }]
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

    Section {
        icon: "widgets"; title: "Widgets"
        SetRow { icon: "dashboard"; label: "Show widgets"; Toggle { checked: c.widgets; onToggled: on => c.widgets = on } }
        SetRow {
            icon: "align_horizontal_right"; label: "Side"
            Choice { width: 200; current: c.widgetSide; options: [{ value: "left", label: "Left" }, { value: "right", label: "Right" }]; onPicked: v => c.widgetSide = v }
        }
        SetRow { icon: "partly_cloudy_day"; label: "Weather"; Toggle { checked: c.weather; onToggled: on => c.weather = on } }
        SetRow { icon: "monitoring"; label: "System"; hint: "Processor, memory, temperature, battery"; Toggle { checked: c.system; onToggled: on => c.system = on } }
        SetRow { icon: "album"; label: "Now playing"; Toggle { checked: c.media; onToggled: on => c.media = on } }
        SetRow { icon: "graphic_eq"; label: "Visualizer"; hint: "Bars rising off the bottom edge while music plays"; Toggle { checked: c.visualizer; onToggled: on => c.visualizer = on } }
    }
}
