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
                         : clockWin.pos === "top-left" ? 70 : parent.height - height - 56 - (scr.visOn && !scr.busy ? 110 : 0)
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

            // ── the widgets ─────────────────────────────────────────
            LazyLoader {
                active: desk.c.widgets && (desk.c.weather || desk.c.system || desk.c.media || desk.c.calendar || desk.c.day)
                PanelWindow {
                    screen: scr.modelData
                    anchors { top: true; right: desk.c.widgetSide === "right"; left: desk.c.widgetSide === "left" }
                    // room around the cards for their glow and shadows to fall into;
                    // without it they were cut off at the window's edge
                    id: widgetWin
                    readonly property int pad: 48           // the side away from the edge
                    readonly property int edge: 28          // the cards' distance from the screen edge
                    readonly property bool right: desk.c.widgetSide === "right"
                    margins { top: 70 - pad; right: 0; left: 0 }
                    implicitWidth: 320 + pad + edge
                    implicitHeight: col.implicitHeight + pad * 2
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-widgets"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region { item: col }

                    Column {
                        id: col
                        x: widgetWin.right ? widgetWin.pad : widgetWin.edge
                        y: widgetWin.pad
                        width: 320
                        spacing: 12
                        DayCard { visible: desk.c.day }
                        WeatherCard { visible: desk.c.weather && Weather.ready }
                        CalendarCard { visible: desk.c.calendar }
                        SystemCard { visible: desk.c.system }
                        MediaCard { visible: desk.c.media && Media.title !== "" }
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
