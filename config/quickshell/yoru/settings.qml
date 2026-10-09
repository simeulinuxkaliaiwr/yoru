//@ pragma IconTheme Papirus-Dark
// yoru's settings window (mod+i):  qs -p ~/.config/quickshell/yoru/settings.qml
// It edits ~/.config/yoru/config.json; the shell picks every change up live.

import Quickshell
import QtQuick
import qs
import qs.parts
import qs.settings

ShellRoot {
    settings.watchFiles: false

    FloatingWindow {
        id: win
        title: "yoru settings"
        implicitWidth: 1000
        implicitHeight: 700
        color: Theme.surface
        onClosed: Qt.quit()

        // YORU_SETTINGS_PAGE=2 opens on the third page (Desktop)
        property int page: Math.max(0, Math.min(pages.length - 1, parseInt(Quickshell.env("YORU_SETTINGS_PAGE") || "0") || 0))
        readonly property var pages: [
            { icon: "tune", label: "Quick", comp: quick },
            { icon: "wallpaper", label: "Wallpaper", comp: wall },
            { icon: "desktop_windows", label: "Desktop", comp: desk },
            { icon: "toolbar", label: "Island", comp: isl },
            { icon: "lock", label: "Lock", comp: lck },
            { icon: "partly_cloudy_day", label: "Weather", comp: wth },
            { icon: "info", label: "About", comp: abt },
        ]
        Component { id: quick; QuickPage {} }
        Component { id: wall; WallpaperPage {} }
        Component { id: desk; DesktopPage {} }
        Component { id: isl; IslandPage {} }
        Component { id: lck; LockPage {} }
        Component { id: wth; WeatherPage {} }
        Component { id: abt; AboutPage {} }

        // ── the rail ────────────────────────────────────────────────
        Column {
            id: rail
            x: 12; y: 20
            width: 88
            spacing: 6
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "夜"; size: 30; color: Theme.primary
                bottomPadding: 14
            }
            Repeater {
                model: win.pages
                Item {
                    id: tab
                    required property var modelData
                    required property int index
                    readonly property bool on: win.page === index
                    width: 88; height: 62
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 2
                        width: tab.on ? 60 : 32; height: 32; radius: 16
                        color: tab.on ? Theme.secondaryContainer : "transparent"
                        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        Icon {
                            anchors.centerIn: parent
                            name: tab.modelData.icon; size: 22; fill: tab.on ? 1 : 0
                            color: tab.on ? Theme.inkSecondaryContainer : Theme.inkDim
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 38
                        text: tab.modelData.label; size: 12
                        weight: tab.on ? Font.DemiBold : Font.Normal
                        color: tab.on ? Theme.ink : Theme.inkDim
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.page = tab.index }
                }
            }
        }

        // ── the page ────────────────────────────────────────────────
        Rectangle {
            anchors { left: rail.right; leftMargin: 12; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12 }
            radius: 28
            color: Theme.surfaceLowest

            Flickable {
                id: scroll
                anchors { fill: parent; margins: 16 }
                contentHeight: holder.height + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: holder
                    width: scroll.width
                    spacing: 18
                    Txt {
                        leftPadding: 8; topPadding: 6
                        text: win.pages[win.page].label
                        size: 28; weight: Font.DemiBold
                    }
                    Loader {
                        id: loader
                        width: parent.width
                        sourceComponent: win.pages[win.page].comp
                        onLoaded: { item.width = Qt.binding(() => loader.width); scroll.contentY = 0; enter.restart(); }
                    }
                }
            }
            // each page slides up into place
            ParallelAnimation {
                id: enter
                NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { target: loader; property: "y"; from: 40; to: holder.children[0].height + 18; duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }
        }
    }
}
