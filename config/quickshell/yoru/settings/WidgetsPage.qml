import Quickshell
import QtQuick
import qs
import qs.parts
import qs.desktop

Column {
    spacing: 14
    readonly property var c: Config.o.desktop

    // roughly where each widget lands, for the preview
    readonly property var names: ["day", "weather", "calendar", "system", "media"].filter(n => c.widgets && c[n] && !Desk.custom)
    function editDesktop() { Quickshell.execDetached(["qs", "-c", "yoru", "ipc", "call", "desktop", "edit"]); }
    readonly property var labels: ({ day: "Today", weather: "Weather", calendar: "Calendar", system: "System", media: "Now playing" })
    function spotOf(n) {
        if (c.arrangement === "row") return "top-center";
        if (c.arrangement === "free") return c.spots[n] || "top-right";
        return c.widgetSide === "left" ? "top-left" : "top-right";
    }
    function boxes() {
        const out = [], bySpot = {};
        names.forEach(n => (bySpot[spotOf(n)] = bySpot[spotOf(n)] || []).push(n));
        for (const spot in bySpot) {
            const list = bySpot[spot], w = 320, h = 150, gap = 14;
            const grid = c.arrangement === "grid";
            list.forEach((n, i) => {
                let x, y;
                if (spot === "top-center") { x = (1920 - list.length * (w + gap)) / 2 + i * (w + gap); y = 70; }
                else {
                    const col = grid ? i % 2 : 0, row = grid ? Math.floor(i / 2) : i;
                    const right = spot.endsWith("right");
                    x = right ? 1920 - 28 - w - (grid ? (1 - col) * (w + gap) : 0) : 28 + col * (w + gap);
                    const top = spot.startsWith("top") ? 70 : spot.startsWith("bottom") ? 1080 - 56 - h * list.length : (1080 - h * list.length) / 2;
                    y = top + row * (h + gap);
                }
                out.push({ name: n, x: x, y: y, w: w, h: h });
            });
        }
        return out;
    }

    Section {
        icon: "preview"; title: "Preview"
        ScreenPreview {
            x: 10
            Repeater {
                model: boxes()
                Rectangle {
                    required property var modelData
                    x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
                    radius: 28
                    color: Theme.alpha(Theme.surfaceLowest, 0.7)
                    border.width: 3; border.color: Theme.alpha(Theme.primary, 0.7)
                    Txt { anchors.centerIn: parent; text: labels[parent.modelData.name]; size: 34; weight: Font.DemiBold }
                    Behavior on x { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                }
            }
            // placed by hand: the real widgets, where they are on the first screen
            Repeater {
                model: Desk.custom && c.widgets ? Desk.itemsOn(Quickshell.screens[0]?.name ?? "") : []
                Placed { required property var modelData; item: modelData; force: true; x: modelData.x; y: modelData.y }
            }
        }
        Row {
            x: 10; spacing: 12
            Btn { icon: "edit"; label: "Edit on the desktop"; onClicked: editDesktop() }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Super+E: add, move and resize them where they live"; size: 12; color: Theme.inkDim }
        }
        Item { width: 1; height: 10 }
    }


    Section {
        icon: "widgets"; title: "Widgets"
        SetRow { icon: "dashboard"; label: "Show widgets"; Toggle { checked: c.widgets; onToggled: on => c.widgets = on } }
        SetRow { icon: "style"; label: "Style"; hint: "What the widgets sit on" }
        Choice {
            x: 10; current: c.widgetStyle
            options: [{ value: "glass", label: "Glass" }, { value: "frosted", label: "Frosted" }, { value: "solid", label: "Solid" },
                      { value: "tonal", label: "Tonal" }, { value: "gradient", label: "Gradient" }, { value: "stack", label: "Stack" },
                      { value: "outline", label: "Outline" }, { value: "neon", label: "Neon" }, { value: "hud", label: "HUD" },
                      { value: "minimal", label: "Minimal" }]
            onPicked: v => c.widgetStyle = v
        }
        Item { width: 1; height: 6 }
        SetRow {
            icon: "rounded_corner"; label: "Roundness"
            Range { value: c.widgetRadius; from: 0; to: 40; step: 2; suffix: " px"; onMoved: v => c.widgetRadius = v }
        }
        SetRow {
            visible: !Desk.custom
            icon: "align_horizontal_right"; label: "Side"
            Choice { width: 200; current: c.widgetSide; options: [{ value: "left", label: "Left" }, { value: "right", label: "Right" }]; onPicked: v => c.widgetSide = v }
        }
        SetRow { visible: !Desk.custom; icon: "partly_cloudy_day"; label: "Weather"; Toggle { checked: c.weather; onToggled: on => c.weather = on } }
        SetRow { visible: !Desk.custom; icon: "monitoring"; label: "System"; hint: "Processor, memory, temperature, battery"; Toggle { checked: c.system; onToggled: on => c.system = on } }
        SetRow { visible: !Desk.custom; icon: "album"; label: "Now playing"; Toggle { checked: c.media; onToggled: on => c.media = on } }
        SetRow { visible: !Desk.custom; icon: "calendar_month"; label: "Calendar"; Toggle { checked: c.calendar; onToggled: on => c.calendar = on } }
        SetRow { visible: !Desk.custom; icon: "hourglass_bottom"; label: "Today"; hint: "How much of the day, week and year has gone"; Toggle { checked: c.day; onToggled: on => c.day = on } }
    }

    Section {
        icon: "dashboard_customize"; title: "Arrangement"
        SetRow { icon: "view_quilt"; label: "Where the widgets go" }
        Choice {
            x: 10; current: c.arrangement
            options: [{ value: "column", label: "Column", icon: "view_agenda" }, { value: "grid", label: "Grid", icon: "grid_view" },
                      { value: "row", label: "Row under the island", icon: "view_week" }, { value: "free", label: "Free", icon: "open_with" },
                      { value: "custom", label: "Placed by hand", icon: "drag_pan" }]
            // placing by hand starts from where they are now, in the editor
            onPicked: v => { if (v === "custom") editDesktop(); else c.arrangement = v; }
        }
        Txt {
            visible: Desk.custom
            x: 10; width: parent.width - 20; topPadding: 8
            text: "Which widgets, where, their layouts and looks: all in the editor. The other arrangements keep their own settings, so you can go back and forth."
            size: 12; color: Theme.inkDim; wrapMode: Text.Wrap
        }
        Item { width: 1; height: 8 }
        // free: a spot for each widget
        Repeater {
            model: c.arrangement === "free" ? [["day", "Today"], ["weather", "Weather"], ["calendar", "Calendar"], ["system", "System"], ["media", "Now playing"]] : []
            Column {
                required property var modelData
                width: parent.width
                SetRow { icon: "pin_drop"; label: modelData[1] }
                Choice {
                    x: 10; current: c.spots[modelData[0]]
                    options: [{ value: "top-left", label: "Top left" }, { value: "top-center", label: "Top" }, { value: "top-right", label: "Top right" },
                              { value: "middle-left", label: "Left" }, { value: "middle-right", label: "Right" }, { value: "bottom-right", label: "Bottom right" }]
                    onPicked: v => c.spots[parent.modelData[0]] = v
                }
                Item { width: 1; height: 6 }
            }
        }
    }
}
