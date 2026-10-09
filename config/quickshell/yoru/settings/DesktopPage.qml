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

    Section {
        icon: "widgets"; title: "Widgets"
        SetRow { icon: "dashboard"; label: "Show widgets"; Toggle { checked: c.widgets; onToggled: on => c.widgets = on } }
        SetRow { icon: "style"; label: "Style"; hint: "What the widgets sit on" }
        Choice {
            x: 10; current: c.widgetStyle
            options: [{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }, { value: "tonal", label: "Tonal" },
                      { value: "outline", label: "Outline" }, { value: "neon", label: "Neon" }, { value: "minimal", label: "Minimal" }]
            onPicked: v => c.widgetStyle = v
        }
        Item { width: 1; height: 6 }
        SetRow {
            icon: "rounded_corner"; label: "Roundness"
            Range { value: c.widgetRadius; from: 0; to: 40; step: 2; suffix: " px"; onMoved: v => c.widgetRadius = v }
        }
        SetRow {
            icon: "align_horizontal_right"; label: "Side"
            Choice { width: 200; current: c.widgetSide; options: [{ value: "left", label: "Left" }, { value: "right", label: "Right" }]; onPicked: v => c.widgetSide = v }
        }
        SetRow { icon: "partly_cloudy_day"; label: "Weather"; Toggle { checked: c.weather; onToggled: on => c.weather = on } }
        SetRow { icon: "monitoring"; label: "System"; hint: "Processor, memory, temperature, battery"; Toggle { checked: c.system; onToggled: on => c.system = on } }
        SetRow { icon: "album"; label: "Now playing"; Toggle { checked: c.media; onToggled: on => c.media = on } }
        SetRow { icon: "calendar_month"; label: "Calendar"; Toggle { checked: c.calendar; onToggled: on => c.calendar = on } }
        SetRow { icon: "hourglass_bottom"; label: "Today"; hint: "How much of the day, week and year has gone"; Toggle { checked: c.day; onToggled: on => c.day = on } }
    }

    Section {
        icon: "graphic_eq"; title: "Visualizer"
        SetRow { icon: "music_note"; label: "Show while music plays"; Toggle { checked: c.visualizer; onToggled: on => c.visualizer = on } }
        SetRow {
            icon: "layers"; label: "Show on busy workspaces"; hint: "It stays under the windows, showing through the gaps and see-through windows"
            Toggle { checked: c.visualizerBusy; onToggled: on => c.visualizerBusy = on }
        }
        SetRow {
            icon: "opacity"; label: "Opacity"
            Range { value: c.visualizerOpacity; from: 0.15; to: 1; step: 0.05; decimals: 0; shownScale: 100; suffix: "%"; onMoved: v => c.visualizerOpacity = v }
        }
        SetRow { icon: "equalizer"; label: "Style" }
        Choice {
            x: 10; current: c.visualizerStyle
            options: [{ value: "bars", label: "Bars" }, { value: "mirror", label: "Mirror" }, { value: "wave", label: "Wave" }, { value: "dots", label: "Dots" }]
            onPicked: v => c.visualizerStyle = v
        }
        Item { width: 1; height: 8 }
    }
}
