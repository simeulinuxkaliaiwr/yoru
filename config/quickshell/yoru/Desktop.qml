import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs
import qs.parts
import qs.desktop

// on the wallpaper, under the windows: the clock, a column of widgets, and
// the music rising off the bottom edge while something plays. What shows and
// where is in the settings (mod+i → Desktop).
Scope {
    id: desk

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var c: Config.o.desktop

    Variants {
        model: Quickshell.screens

        Scope {
            id: scr
            required property var modelData
            readonly property bool covered: Aro.busy(modelData.name) || Aro.fullscreen(modelData.name)
            readonly property bool busy: Aro.busy(modelData.name)
            // always under the windows: on a busy workspace it shows through the
            // gaps and the see-through windows. Never behind a fullscreen one
            readonly property bool visOn: desk.c.visualizer && Media.playing && !Aro.fullscreen(modelData.name)
                && (!busy || desk.c.visualizerBusy)

            // ── the clock ───────────────────────────────────────────
            LazyLoader {
                active: desk.c.clock
                PanelWindow {
                    id: clockWin
                    screen: scr.modelData
                    readonly property string pos: desk.c.clockPosition
                    // a strip across the screen; the clock sits in it where asked
                    anchors { left: true; right: true; top: pos !== "bottom-left"; bottom: pos !== "top-left" }
                    implicitHeight: 520
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-clock"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}

                    ClockFace {
                        id: face
                        style: desk.c.clockStyle
                        centred: clockWin.pos === "center"
                        x: centred ? (parent.width - width) / 2 : 64
                        // the clock steps up out of the visualizer's way
                        y: centred ? (parent.height - height) / 2 - 40
                         // below the row of widgets when they run along the top
                         : clockWin.pos === "top-left" ? 70 + (desk.c.widgets && desk.c.arrangement === "row" ? 130 : 0)
                         : parent.height - height - 56 - (scr.visOn && !scr.busy ? 110 : 0)
                        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.55)
                            shadowBlur: 0.8
                            shadowVerticalOffset: 2
                        }
                    }
                }
            }

            // ── the widgets: a window per spot that has any ────────────
            readonly property var order: ["day", "weather", "calendar", "system", "media"]
            readonly property var enabledWidgets: order.filter(n => !Desk.custom && desk.c.widgets && desk.c[n] && (n !== "media" || Media.title !== "")
                                                               && (n !== "weather" || Weather.ready))
            function spotOf(n) {
                const a = desk.c.arrangement;
                if (a === "row") return "top-center";
                if (a === "free") return desk.c.spots[n] || "top-right";
                return desk.c.widgetSide === "left" ? "top-left" : "top-right";
            }
            readonly property var spots: {
                const used = [];
                for (const n of enabledWidgets) { const p = spotOf(n); if (!used.includes(p)) used.push(p); }
                return used;
            }

            Variants {
                model: scr.spots
                PanelWindow {
                    id: widgetWin
                    required property string modelData
                    readonly property string spot: modelData
                    readonly property bool right: spot.endsWith("right")
                    readonly property bool centred: spot.endsWith("center")
                    readonly property bool grid: desk.c.arrangement === "grid"
                    readonly property var names: scr.enabledWidgets.filter(n => scr.spotOf(n) === spot)
                    // room around the cards for their glow and shadows
                    readonly property int pad: 48
                    readonly property int edge: 28
                    screen: scr.modelData
                    anchors {
                        top: spot.startsWith("top")
                        bottom: spot.startsWith("bottom")
                        left: spot.endsWith("left")
                        right: spot.endsWith("right")
                    }
                    // under the clock when it sits in the same corner
                    readonly property int clockRoom: spot === "top-left" && desk.c.clock && desk.c.clockPosition === "top-left" ? 250 : 0
                    margins {
                        top: spot.startsWith("top") ? 70 - pad + clockRoom : 0
                        bottom: spot.startsWith("bottom") ? 56 - pad : 0
                    }
                    // where this window sits on the screen, for the frosted look
                    readonly property real frostX: right ? scr.modelData.width - implicitWidth : centred || !spot.endsWith("left") ? (scr.modelData.width - implicitWidth) / 2 : 0
                    readonly property real frostY: spot.startsWith("top") ? margins.top
                        : spot.startsWith("bottom") ? scr.modelData.height - implicitHeight - margins.bottom
                        : (scr.modelData.height - implicitHeight) / 2
                    implicitWidth: holder.width + (centred ? pad * 2 : pad + edge)
                    implicitHeight: holder.height + pad * 2
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-widgets"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region { item: holder }

                    // one widget, by name
                    component Widget: Loader {
                        id: w
                        required property string name
                        sourceComponent: ({ day: dayC, weather: weatherC, calendar: calC, system: sysC, media: mediaC })[name]
                        // so the first edit (Desk.snapshot) starts from where it is
                        readonly property string key: scr.modelData.name + ":" + name
                        Component.onCompleted: Desk.report(key, { item: w, win: widgetWin, type: name, output: scr.modelData.name })
                        Component.onDestruction: Desk.report(key, null)
                    }
                    Component { id: dayC; DayCard {} }
                    Component { id: weatherC; WeatherCard {} }
                    Component { id: calC; CalendarCard {} }
                    Component { id: sysC; SystemCard {} }
                    Component { id: mediaC; MediaCard {} }

                    Item {
                        id: holder
                        x: widgetWin.centred ? widgetWin.pad : widgetWin.right ? widgetWin.pad : widgetWin.edge
                        y: widgetWin.pad
                        width: widgetWin.centred ? row.implicitWidth : widgetWin.grid ? flow.width : col.width
                        height: widgetWin.centred ? row.implicitHeight : widgetWin.grid ? flow.height : col.implicitHeight

                        // a column, the cards lined up on the screen-edge side
                        Column {
                            id: col
                            visible: !widgetWin.centred && !widgetWin.grid
                            width: Math.max(...children.map(ch => ch.width), 1)
                            spacing: 12
                            Repeater {
                                model: !widgetWin.centred && !widgetWin.grid ? widgetWin.names : []
                                Widget {
                                    required property string modelData
                                    name: modelData
                                    x: widgetWin.right ? col.width - width : 0
                                }
                            }
                        }
                        // a grid: two columns, filled in turn
                        Row {
                            id: flow
                            visible: widgetWin.grid && !widgetWin.centred
                            spacing: 12
                            Repeater {
                                model: widgetWin.grid && !widgetWin.centred ? 2 : 0
                                Column {
                                    required property int index
                                    spacing: 12
                                    Repeater {
                                        model: widgetWin.names.filter((n, i) => i % 2 === parent.index)
                                        Widget { required property string modelData; name: modelData }
                                    }
                                }
                            }
                        }
                        // a row under the island
                        Row {
                            id: row
                            visible: widgetWin.centred
                            spacing: 12
                            Repeater {
                                model: widgetWin.centred ? widgetWin.names : []
                                Widget { required property string modelData; name: modelData }
                            }
                        }
                        // with no card under it, the text needs a shadow to read
                        layer.enabled: desk.c.widgetStyle === "minimal"
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.9)
                            shadowBlur: 0.35
                            shadowVerticalOffset: 1
                        }
                    }
                }
            }

            // ── placed widgets (arrangement "custom"): a window each ──
            // keyed by id, so moving one doesn't rebuild the others. Edit mode
            // draws its own copies, so these step aside while it's open
            Variants {
                model: Desk.custom && desk.c.widgets && !Desk.editing ? Desk.itemsOn(scr.modelData.name).map(i => i.id) : []
                PanelWindow {
                    id: placedWin
                    required property string modelData
                    readonly property var item: Desk.items.find(i => i.id === modelData) ?? null
                    // room for glows and shadows, less where it nears the screen's edge
                    readonly property int pad: 48
                    readonly property int padL: Math.min(pad, Math.max(0, item?.x ?? 0))
                    readonly property int padT: Math.min(pad, Math.max(0, item?.y ?? 0))
                    screen: scr.modelData
                    visible: !!item && view.shown
                    anchors { top: true; left: true }
                    margins { left: Math.max(0, (item?.x ?? 0) - pad); top: Math.max(0, (item?.y ?? 0) - pad) }
                    // where it sits on the screen, for the frosted look
                    readonly property real frostX: margins.left
                    readonly property real frostY: margins.top
                    implicitWidth: Math.max(1, view.width + padL + pad)
                    implicitHeight: Math.max(1, view.height + padT + pad)
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-widgets"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region { item: view }

                    Placed { id: view; x: placedWin.padL; y: placedWin.padT; item: placedWin.item }
                }
            }

            // ── the visualizer: fades in and out with the music ─────
            LazyLoader {
                active: scr.visOn || linger.running
                PanelWindow {
                    screen: scr.modelData
                    anchors { bottom: true; left: true; right: true }
                    implicitHeight: 140
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-visualizer"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}

                    Visualizer {
                        anchors { fill: parent; leftMargin: 24; rightMargin: 24; bottomMargin: 6 }
                        style: desk.c.visualizerStyle
                        opacity: scr.visOn ? desk.c.visualizerOpacity : 0
                        Behavior on opacity { NumberAnimation { duration: 500 } }
                    }
                }
            }
            Timer { id: linger; interval: 600 }
            onVisOnChanged: if (!visOn) linger.restart()
        }
    }
}
