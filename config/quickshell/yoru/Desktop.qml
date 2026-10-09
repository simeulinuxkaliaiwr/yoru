import Quickshell
import Quickshell.Io
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

            // ── the clock ───────────────────────────────────────────
            LazyLoader {
                active: desk.c.clock
                PanelWindow {
                    id: clockWin
                    screen: scr.modelData
                    readonly property string pos: desk.c.clockPosition
                    // a strip across the screen; the clock sits in it where asked
                    anchors { left: true; right: true; top: pos !== "bottom-left"; bottom: pos !== "top-left" }
                    implicitHeight: 380
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-clock"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}

                    Column {
                        id: face
                        readonly property string style: desk.c.clockStyle
                        readonly property bool centred: clockWin.pos === "center"
                        x: centred ? (parent.width - width) / 2 : 64
                        y: centred ? (parent.height - height) / 2 - 40
                         : clockWin.pos === "top-left" ? 70 : parent.height - height - 56
                        spacing: face.style === "stacked" ? 6 : -6
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.55)
                            shadowBlur: 0.8
                            shadowVerticalOffset: 2
                        }
                        Txt {
                            anchors.horizontalCenter: face.centred ? parent.horizontalCenter : undefined
                            visible: face.style !== "stacked"
                            text: Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm")
                            size: face.style === "bold" ? 124 : 136
                            weight: face.style === "bold" ? Font.Bold : Font.ExtraLight
                            font.letterSpacing: face.style === "bold" ? -3 : -6
                            font.features: { "tnum": 1 }
                        }
                        Column {
                            anchors.horizontalCenter: face.centred ? parent.horizontalCenter : undefined
                            visible: face.style === "stacked"
                            spacing: -34
                            Txt { text: Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH" : "hh"); size: 150; weight: Font.Black; color: Theme.primary; font.features: { "tnum": 1 } }
                            Txt { text: Qt.formatTime(clock.date, "mm"); size: 150; weight: Font.Black; font.features: { "tnum": 1 } }
                        }
                        Row {
                            anchors.horizontalCenter: face.centred ? parent.horizontalCenter : undefined
                            spacing: 12
                            leftPadding: face.centred ? 0 : 8
                            Rectangle { width: 26; height: 3; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            Txt {
                                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                                size: 22; weight: Font.Light
                                opacity: 0.85
                            }
                        }
                    }
                }
            }

            // ── the widgets ─────────────────────────────────────────
            LazyLoader {
                active: desk.c.widgets && (desk.c.weather || desk.c.system || desk.c.media)
                PanelWindow {
                    screen: scr.modelData
                    anchors { top: true; right: desk.c.widgetSide === "right"; left: desk.c.widgetSide === "left" }
                    margins { top: 70; right: 28; left: 28 }
                    implicitWidth: 320
                    implicitHeight: col.implicitHeight + 4
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-widgets"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region { item: col }

                    Column {
                        id: col
                        width: 320
                        spacing: 12
                        WeatherCard { visible: desk.c.weather && Weather.ready }
                        SystemCard { visible: desk.c.system }
                        MediaCard { visible: desk.c.media && Media.title !== "" }
                    }
                }
            }

            // ── the visualizer ──────────────────────────────────────
            LazyLoader {
                active: desk.c.visualizer && Media.playing && !scr.covered
                PanelWindow {
                    id: vis
                    screen: scr.modelData
                    anchors { bottom: true; left: true; right: true }
                    implicitHeight: 150
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "yoru-visualizer"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}

                    property var levels: []
                    Process {
                        running: true
                        command: ["cava", "-p", Quickshell.shellDir + "/cava.conf"]
                        stdout: SplitParser {
                            onRead: line => vis.levels = line.split(";").filter(s => s !== "").map(n => parseInt(n) / 1000)
                        }
                    }

                    Row {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        spacing: 7
                        opacity: 0.6
                        Repeater {
                            model: 56
                            Rectangle {
                                required property int index
                                anchors.bottom: parent.bottom
                                width: Math.floor((vis.width - 55 * 7) / 56)
                                height: Math.max(4, (vis.levels[index] ?? 0) * vis.height)
                                radius: width / 2
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Theme.tertiary }
                                    GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0.2) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
