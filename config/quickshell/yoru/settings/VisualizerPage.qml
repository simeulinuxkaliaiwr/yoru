import QtQuick
import qs
import qs.parts

Column {
    spacing: 14
    readonly property var c: Config.o.desktop

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
            options: [{ value: "bars", label: "Bars" }, { value: "mirror", label: "Mirror" }, { value: "wave", label: "Wave" }, { value: "dots", label: "Dots" },
                      { value: "aurora", label: "Aurora", icon: "auto_awesome" }, { value: "silk", label: "Silk", icon: "airwave" },
                      { value: "glass", label: "Glass", icon: "water_drop" }]
            onPicked: v => c.visualizerStyle = v
        }
        Item { width: 1; height: 8 }
    }
}
