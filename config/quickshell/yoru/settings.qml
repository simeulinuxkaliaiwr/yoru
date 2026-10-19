//@ pragma IconTheme Papirus-Dark
// yoru's settings window (mod+i):  qs -p ~/.config/quickshell/yoru/settings.qml
// It edits ~/.config/yoru/config.json; the shell picks every change up live.
// YORU_SETTINGS_PAGE=clock opens on a page by its id.

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
        implicitWidth: 1100
        implicitHeight: 740
        color: Theme.surface
        onClosed: Qt.quit()

        // id, icon, name, what it's for, group, words to find it by
        readonly property var pages: [
            { id: "quick", icon: "tune", name: "Quick", about: "The wallpaper, its colours and how fast things move", group: "Look", words: "scheme colour palette music speed animation" },
            { id: "wallpaper", icon: "wallpaper", name: "Wallpaper", about: "Transitions, live wallpapers and where they come from", group: "Look", words: "transition fade wipe disc parallax video folders rotate shuffle backend skwd skwd-wall daemon" },
            { id: "clock", icon: "schedule", name: "Clock", about: "The clock on the desktop", group: "Look", words: "time style kanji serif analog position" },
            { id: "widgets", icon: "widgets", name: "Widgets", about: "Which widgets, what they sit on, and where", group: "Look", words: "weather calendar system media today arrangement column grid row free custom edit mode place move resize drag glass neon frosted blur gradient hud stack" },
            { id: "layouts", icon: "dashboard_customize", name: "Widget layouts", about: "How each widget lays itself out", group: "Look", words: "hero pill week date cover chips bars rings graph split dots vinyl record sun sunrise sunset" },
            { id: "visualizer", icon: "graphic_eq", name: "Visualizer", about: "The music, rising off the bottom of the screen", group: "Look", words: "cava bars wave mirror dots audio" },
            { id: "start", icon: "tab", name: "Start page", about: "Firefox's new tab page", group: "Look", words: "firefox new tab browser search engine links greeting address bar focus cursor keyboard" },
            { id: "island", icon: "toolbar", name: "Island", about: "The bar that becomes everything", group: "Shell", words: "clock 24 hour battery workspaces notifications" },
            { id: "focus", icon: "timer", name: "Focus & quiet", about: "The focus timer and do not disturb", group: "Shell", words: "pomodoro break dnd quiet hours night" },
            { id: "lock", icon: "lock", name: "Lock screen", about: "What you see when you come back", group: "Shell", words: "blur dim idle password power characters shapes dots" },
            { id: "weather", icon: "partly_cloudy_day", name: "Weather", about: "Where the forecast is for", group: "More", words: "city fahrenheit location" },
            { id: "about", icon: "info", name: "About", about: "yoru, its keys and its config", group: "More", words: "keys rice config" },
            { id: "about", icon: "info", name: "About", about: "yoru, its keys", group: "More", words: "keys rice" },
        ]
        readonly property var comps: ({
            quick: quickC, wallpaper: wallC, clock: clockC, widgets: widgetsC, layouts: layoutsC, visualizer: visC, start: startC,
            island: islandC, focus: focusC, lock: lockC, weather: weatherC, about: aboutC
        })
        Component { id: quickC; QuickPage {} }
        Component { id: wallC; WallpaperPage {} }
        Component { id: clockC; ClockPage {} }
        Component { id: widgetsC; WidgetsPage {} }
        Component { id: layoutsC; LayoutsPage {} }
        Component { id: visC; VisualizerPage {} }
        Component { id: startC; StartPage {} }
        Component { id: islandC; IslandPage {} }
        Component { id: focusC; FocusPage {} }
        Component { id: lockC; LockPage {} }
        Component { id: weatherC; WeatherPage {} }
        Component { id: aboutC; AboutPage {} }

        property string current: {
            const want = Quickshell.env("YORU_SETTINGS_PAGE") || "quick";
            return pages.some(p => p.id === want) ? want : "quick";
        }
        readonly property var page: pages.find(p => p.id === current)
        property string query: ""
        readonly property var found: pages.filter(p => query === "" || (p.name + " " + p.about + " " + p.words).toLowerCase().includes(query.toLowerCase()))

        // the sidebar
        Item {
            id: side
            width: 236
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }

            Row {
                x: 22; y: 22
                spacing: 10
                Txt { text: "夜"; size: 30; color: Theme.primary; font.family: "Noto Sans JP" }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt { text: "yoru"; size: 16; weight: Font.DemiBold }
                    Txt { text: "settings"; size: 11; color: Theme.inkDim }
                }
            }

            Rectangle {
                id: search
                x: 14; y: 80
                width: parent.width - 28; height: 40
                radius: Theme.r(20)
                color: Theme.surfaceMid
                border.width: field.activeFocus ? 2 : 0
                border.color: Theme.primary
                Icon { id: glass; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 18; color: Theme.inkDim }
                TextInput {
                    id: field
                    anchors { left: glass.right; leftMargin: 8; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: Theme.ink
                    font { family: Theme.sans; pixelSize: 13 }
                    onTextChanged: win.query = text
                    Keys.onReturnPressed: if (win.found.length) win.current = win.found[0].id
                    Keys.onEscapePressed: text = ""
                    Txt { anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""; text: "Find a setting"; size: 13; color: Theme.outline }
                }
            }

            Flickable {
                anchors { top: search.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 12 }
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: list
                    width: parent.width
                    Repeater {
                        model: ["Look", "Shell", "More"]
                        Column {
                            id: group
                            required property string modelData
                            readonly property var items: win.found.filter(p => p.group === modelData)
                            visible: items.length > 0
                            width: list.width
                            Txt { x: 26; topPadding: 12; bottomPadding: 6; text: group.modelData.toUpperCase(); size: 10; weight: Font.Bold; color: Theme.outline; font.letterSpacing: 1.5 }
                            Repeater {
                                model: group.items
                                Item {
                                    id: tab
                                    required property var modelData
                                    readonly property bool on: win.current === modelData.id
                                    width: list.width; height: 44
                                    Rectangle {
                                        x: 12; width: parent.width - 24; height: 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: Theme.r(20)
                                        color: tab.on ? Theme.secondaryContainer : hover.containsMouse ? Theme.alpha(Theme.ink, 0.06) : "transparent"
                                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                                    }
                                    Icon {
                                        x: 28; anchors.verticalCenter: parent.verticalCenter
                                        name: tab.modelData.icon; size: 20; fill: tab.on ? 1 : 0
                                        color: tab.on ? Theme.inkSecondaryContainer : Theme.inkDim
                                    }
                                    Txt {
                                        x: 60; anchors.verticalCenter: parent.verticalCenter
                                        text: tab.modelData.name; size: 13
                                        weight: tab.on ? Font.DemiBold : Font.Normal
                                        color: tab.on ? Theme.inkSecondaryContainer : Theme.ink
                                    }
                                    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.current = tab.modelData.id }
                                }
                            }
                        }
                    }
                    Txt { visible: win.found.length === 0; x: 26; topPadding: 12; text: "Nothing matches"; size: 12; color: Theme.outline }
                }
            }
        }

        // the page
        Rectangle {
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12; leftMargin: 0 }
            radius: Theme.r(28)
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
                    Column {
                        id: head
                        leftPadding: 8; topPadding: 6
                        spacing: 2
                        Txt { text: win.page.name; size: 28; weight: Font.DemiBold }
                        Txt { text: win.page.about; size: 13; color: Theme.inkDim }
                    }
                    Loader {
                        id: loader
                        width: parent.width
                        sourceComponent: win.comps[win.current]
                        onLoaded: { item.width = Qt.binding(() => loader.width); scroll.contentY = 0; enter.restart(); }
                    }
                }
            }
            // each page slides up into place
            ParallelAnimation {
                id: enter
                NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { target: loader; property: "y"; from: head.height + 58; to: head.height + 18; duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }
        }
    }
}
