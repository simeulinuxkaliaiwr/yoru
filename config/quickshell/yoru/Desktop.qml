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
            readonly property bool covered: Wm.busy(modelData.name) || Wm.fullscreen(modelData.name)
            readonly property bool busy: Wm.busy(modelData.name)
            // always under the windows: on a busy workspace it shows through the
            // gaps and the see-through windows. Never behind a fullscreen one
            readonly property bool visOn: desk.c.visualizer && Media.playing && !Wm.fullscreen(modelData.name)
                && (!busy || desk.c.visualizerBusy)

            // the clock
            // (once placed by hand, the clock is a Clock widget like the rest)
            LazyLoader {
                active: desk.c.clock && !(Desk.custom && desk.c.clockPlaced)
                PanelWindow {
                    id: clockWin
                    screen: scr.modelData
                    readonly property string pos: desk.c.clockPosition
                    // where the window sits, so the first edit can place the clock where it is
                    readonly property real frostX: 0
                    readonly property real frostY: anchors.top ? 0 : scr.modelData.height - height
                    // a strip across the screen; the clock sits in it where asked
                    anchors { left: true; right: true; top: pos !== "bottom-left"; bottom: pos !== "top-left" }
                    implicitHeight: 520
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-clock"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}

                    // where the wallpaper is bright, a soft dark patch behind it as well
                    Rectangle {
                        visible: face.visible && face.deep > 0.05
                        x: face.x - 48; y: face.y - 28
                        width: face.width + 96; height: face.height + 56
                        radius: height / 2
                        color: "black"
                        opacity: 0.3 * face.deep
                        layer.enabled: visible
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
                    }
                    ClockFace {
                        id: face
                        // so the first edit (Desk.snapshot) starts from where it is
                        Component.onCompleted: Desk.report(scr.modelData.name + ":clock", { item: face, win: clockWin, type: "clock", output: scr.modelData.name })
                        Component.onDestruction: Desk.report(scr.modelData.name + ":clock", null)
                        style: desk.c.clockStyle
                        centred: clockWin.pos === "center"
                        x: centred ? (parent.width - width) / 2 : 64
                        // the clock steps up out of the visualizer's way
                        y: centred ? (parent.height - height) / 2 - 40
                         // below the row of widgets when they run along the top
                         : clockWin.pos === "top-left" ? 70 + (desk.c.widgets && desk.c.arrangement === "row" ? 130 : 0)
                         : parent.height - height - 56 - (scr.visOn && !scr.busy ? 110 : 0)
                        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        // a deeper, wider shadow where the wallpaper under it is bright
                        readonly property real deep: parent && parent.width > 0
                            ? Theme.shade(Theme.brightAt(x / parent.width, y / parent.height, width / parent.width, height / parent.height)) : 0
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.55 + 0.35 * face.deep)
                            shadowBlur: 0.8 + 0.2 * face.deep
                            blurMax: 32 + Math.round(24 * face.deep)
                            shadowScale: 1 + 0.02 * face.deep
                            shadowVerticalOffset: 2
                        }
                    }
                }
            }

            // the widgets: a window per spot that has any
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

            // placed widgets (arrangement "custom"): one window for them all
            // a window per widget cost ~16 MB each (a GL context, a render thread,
            // glyph caches); one full-screen window takes clicks only where the
            // widgets are. Edit mode draws its own copies, so this steps aside
            LazyLoader {
                active: Desk.custom && desk.c.widgets && !Desk.editing && Desk.itemsOn(scr.modelData.name).length > 0
                PanelWindow {
                    id: placedWin
                    screen: scr.modelData
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-widgets"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    // the window covers the screen, for the frosted look
                    readonly property real frostX: 0
                    readonly property real frostY: 0
                    // by id, so moving one widget doesn't rebuild the others
                    readonly property var ids: Desk.itemsOn(scr.modelData.name).map(i => i.id)

                    Item {
                        id: holder
                        anchors.fill: parent
                        Repeater {
                            model: placedWin.ids
                            Placed {
                                required property string modelData
                                readonly property string wid: modelData
                                item: Desk.items.find(i => i.id === modelData) ?? null
                                x: item?.x ?? 0
                                y: item?.y ?? 0
                                visible: shown
                            }
                        }
                    }
                    // clicks go through except where a widget is showing
                    Variants {
                        id: areas
                        model: placedWin.ids
                        Region {
                            required property string modelData
                            readonly property Item view: holder.children.find(c => c.wid === modelData) ?? null
                            x: view?.x ?? 0
                            y: view?.y ?? 0
                            width: view && view.shown ? view.width : 0
                            height: view && view.shown ? view.height : 0
                        }
                    }
                    mask: Region { regions: areas.instances }
                }
            }

            // the visualizer: fades in and out with the music
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
