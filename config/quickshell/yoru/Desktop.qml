import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// on the wallpaper, under the windows: a big quiet clock, and the music
// rising off the bottom edge while something plays
Scope {
    id: desk

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scr
            required property var modelData
            readonly property bool covered: Aro.busy(modelData.name) || Aro.fullscreen(modelData.name)

            PanelWindow {
                screen: scr.modelData
                anchors { bottom: true; left: true }
                margins { left: 64; bottom: 56 }
                implicitWidth: 760
                implicitHeight: 260
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "yoru-clock"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {}

                Column {
                    id: face
                    anchors { left: parent.left; bottom: parent.bottom }
                    spacing: -6
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.55)
                        shadowBlur: 0.8
                        shadowVerticalOffset: 2
                    }
                    Txt {
                        text: Qt.formatTime(clock.date, "HH:mm")
                        size: 136
                        weight: Font.ExtraLight
                        font.letterSpacing: -6
                        font.features: { "tnum": 1 }
                        color: Theme.ink
                    }
                    Row {
                        spacing: 12
                        leftPadding: 8
                        Rectangle { width: 26; height: 3; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Txt {
                            text: Qt.formatDate(clock.date, "dddd, d MMMM")
                            size: 22; weight: Font.Light
                            color: Theme.ink
                            opacity: 0.85
                        }
                    }
                    Item { width: 1; height: 14 }
                    Row {
                        visible: Media.title !== ""
                        spacing: 8
                        leftPadding: 10
                        Icon { name: Media.playing ? "graphic_eq" : "music_note"; size: 18; color: Theme.primary }
                        Txt {
                            width: Math.min(implicitWidth, 560)
                            text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
                            size: 14; color: Theme.inkDim
                        }
                    }
                }
            }

            // ── the visualizer ──────────────────────────────────────
            LazyLoader {
                active: Media.playing && !scr.covered
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
                        id: bars
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
