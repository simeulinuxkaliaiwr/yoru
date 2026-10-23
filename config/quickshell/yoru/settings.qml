//@ pragma IconTheme Papirus-Dark
// yoru's settings window (mod+i):  qs -p ~/.config/quickshell/yoru/settings.qml
// It edits ~/.config/yoru/config.json; the shell picks every change up live.
// YORU_SETTINGS_PAGE=clock opens on a page by its id.

import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts
import qs.settings
import "settings/pages.js" as Pages

ShellRoot {
    settings.watchFiles: false

    FloatingWindow {
        id: win
        title: "yoru settings"
        implicitWidth: 1100
        implicitHeight: 740
        color: Theme.surface
        onClosed: Qt.quit()

        readonly property var pages: Pages.list
        readonly property var comps: ({
            quick: quickC, wallpaper: wallC, clock: clockC, widgets: widgetsC, layouts: layoutsC, visualizer: visC, start: startC,
            island: islandC, phone: phoneC, notifications: notifsC, focus: focusC, lock: lockC, screen: screenC, weather: weatherC, about: aboutC
        })
        Component { id: quickC; QuickPage {} }
        Component { id: wallC; WallpaperPage {} }
        Component { id: clockC; ClockPage {} }
        Component { id: widgetsC; WidgetsPage {} }
        Component { id: layoutsC; LayoutsPage {} }
        Component { id: visC; VisualizerPage {} }
        Component { id: startC; StartPage {} }
        Component { id: islandC; IslandPage {} }
        Component { id: phoneC; PhonePage {} }
        Component { id: notifsC; NotificationsPage {} }
        Component { id: focusC; FocusPage {} }
        Component { id: lockC; LockPage {} }
        Component { id: screenC; ScreenPage {} }
        Component { id: weatherC; WeatherPage {} }
        Component { id: aboutC; AboutPage {} }

        property string current: {
            const want = Quickshell.env("YORU_SETTINGS_PAGE") || "quick";
            return pages.some(p => p.id === want) ? want : "quick";
        }
        readonly property var page: pages.find(p => p.id === current)
        property string query: ""
        readonly property var found: pages.filter(p => query === "" || (p.name + " " + p.about + " " + p.words).toLowerCase().includes(query.toLowerCase()))
        // single settings too, by their names: a click opens the page there and the row shines
        readonly property var foundRows: query.trim().length < 2 ? [] : SettingsIndex.search(query, 8) ?? []
        property string find: Quickshell.env("YORU_SETTINGS_FIND") || ""
        function show(id, label) {
            if (!pages.some(p => p.id === id)) return;
            find = label ?? "";
            if (current === id) seek();
            else current = id;
        }
        // the row with that label in the page: scrolled to and lit up
        function seek() {
            if (find === "" || !loader.item) return;
            const want = find;
            find = "";
            const walk = it => {
                if (it.label === want && typeof it.flash === "function") return it;
                for (const ch of it.children ?? []) { const r = walk(ch); if (r) return r; }
                return null;
            };
            const row = walk(loader.item);
            if (!row) return;
            const y = row.mapToItem(holder, 0, 0).y;
            scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, y - scroll.height / 3));
            row.flash();
        }
        // the launcher asking for a page while this window is open (not "show": that's qs ipc's own)
        IpcHandler {
            target: "settings"
            function open(page: string, label: string): void { win.show(page, label); }
        }

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
                    onTextChanged: { win.query = text; SettingsIndex.want(); }
                    Keys.onReturnPressed: {
                        if (win.found.length) win.current = win.found[0].id;
                        else if (win.foundRows.length) win.show(win.foundRows[0].page, win.foundRows[0].label);
                    }
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
                    // the single settings that match
                    Column {
                        visible: win.foundRows.length > 0
                        width: list.width
                        Txt { x: 26; topPadding: 12; bottomPadding: 6; text: "SETTINGS"; size: 10; weight: Font.Bold; color: Theme.outline; font.letterSpacing: 1.5 }
                        Repeater {
                            model: win.foundRows
                            Item {
                                id: hit
                                required property var modelData
                                width: list.width; height: 48
                                Rectangle {
                                    x: 12; width: parent.width - 24; height: 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: Theme.r(20)
                                    color: hitHover.containsMouse ? Theme.alpha(Theme.ink, 0.06) : "transparent"
                                }
                                Icon { x: 28; anchors.verticalCenter: parent.verticalCenter; name: hit.modelData.icon; size: 18; color: Theme.inkDim }
                                Column {
                                    x: 60; width: parent.width - 72; anchors.verticalCenter: parent.verticalCenter
                                    Txt { width: parent.width; text: hit.modelData.label; size: 13 }
                                    Txt { width: parent.width; text: hit.modelData.pageName + (hit.modelData.section && hit.modelData.section !== hit.modelData.pageName ? " › " + hit.modelData.section : ""); size: 11; color: Theme.inkDim }
                                }
                                MouseArea { id: hitHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.show(hit.modelData.page, hit.modelData.label) }
                            }
                        }
                    }
                    Txt { visible: win.found.length === 0 && win.foundRows.length === 0; x: 26; topPadding: 12; text: "Nothing matches"; size: 12; color: Theme.outline }
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
                        onLoaded: { item.width = Qt.binding(() => loader.width); scroll.contentY = 0; enter.restart(); seekSoon.restart(); }
                    }
                }
            }
            // once the page has laid itself out (and slid in): the row asked for
            Timer { id: seekSoon; interval: Theme.slow; onTriggered: win.seek() }
            // each page slides up into place
            ParallelAnimation {
                id: enter
                NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { target: loader; property: "y"; from: head.height + 58; to: head.height + 18; duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }
        }
    }
}
