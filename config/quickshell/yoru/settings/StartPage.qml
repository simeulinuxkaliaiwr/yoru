import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// Firefox's new tab page: yoru-start.html reads these from ~/startpages/yoru-start.js
Column {
    id: page
    spacing: 14
    readonly property var c: Config.o.start
    readonly property var links: (c.links ?? []).filter(l => l && l.url).slice(0, 9)
    readonly property var engines: [["google", "Google"], ["duckduckgo", "DuckDuckGo"], ["youtube", "YouTube"], ["github", "GitHub"], ["wikipedia", "Wikipedia"]]

    function setLinks(l) { c.links = l; }
    function editLink(i, key, value) {
        const l = c.links.slice();
        l[i] = Object.assign({}, l[i], { [key]: value });
        setLinks(l);
    }
    function moveLink(i, by) {
        const l = c.links.slice(), j = i + by;
        if (j < 0 || j >= l.length) return;
        [l[i], l[j]] = [l[j], l[i]];
        setLinks(l);
    }

    // a small Firefox with the page in it
    Section {
        icon: "preview"; title: "Preview"
        ClippingRectangle {
            id: shot
            x: 10
            width: Math.min(parent.width - 20, 640); height: width * 10 / 16
            radius: Theme.r(18)
            color: Theme.surfaceLowest
            border.width: 1; border.color: Theme.alpha(Theme.outlineVariant, 0.6)
            readonly property real k: width / 1600

            // the wallpaper, blurred and dimmed as the page will have it
            Image {
                id: wall
                anchors.fill: parent
                source: Theme.still ? "file://" + Theme.still : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(400, 250)
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                // the page's blur, at the preview's scale
                blurEnabled: page.c.blur > 0
                blur: Math.min(1, page.c.blur * shot.width / 1920 / 12)
                blurMax: 32
            }
            Rectangle { anchors.fill: parent; color: "black"; opacity: page.c.dim }

            // Firefox's toolbar: the address bar is empty, it's a start page
            Rectangle {
                width: parent.width; height: 34
                color: Theme.alpha(Theme.surfaceLowest, 0.85)
                Rectangle {
                    x: 64; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.38; height: 20; radius: Theme.r(6)
                    color: Theme.alpha(Theme.ink, 0.06)
                    border.width: page.c.focus === "address" ? 1.5 : 0
                    border.color: Theme.primary
                    Rectangle {      // where the typing goes
                        visible: page.c.focus === "address"
                        x: 8; anchors.verticalCenter: parent.verticalCenter
                        width: 1.5; height: 11; color: Theme.ink
                    }
                }
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Repeater { model: 3; Rectangle { width: 9; height: 9; radius: Theme.r(4.5); color: Theme.alpha(Theme.ink, 0.25) } }
                }
            }

            // the page, laid out at 1600x966 and scaled down
            Item {
                id: stage
                y: 34
                width: 1600; height: 966
                scale: shot.k
                transformOrigin: Item.TopLeft
                readonly property string layout: page.c.layout
                readonly property bool centred: layout !== "left"

                Column {
                    id: col
                    x: stage.centred ? 0 : 144
                    width: stage.centred ? stage.width : 1000
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -30
                    spacing: stage.layout === "minimal" ? 26 : 20

                    component Line: Txt {
                        x: stage.centred ? (col.width - implicitWidth) / 2 : 0
                    }
                    Line {
                        visible: page.c.greeting && stage.layout !== "minimal"
                        text: "Good evening, " + (page.c.name || Quickshell.env("USER"))
                        size: 22; color: Theme.inkDim
                    }
                    Line {
                        visible: page.c.clock
                        text: page.c.seconds ? "23:11:42" : "23:11"
                        size: stage.layout === "minimal" ? 64 : stage.layout === "left" ? 190 : 150
                        weight: stage.layout === "minimal" ? Font.Light : Font.ExtraLight
                        font.letterSpacing: stage.layout === "left" ? -8 : -5
                    }
                    Line {
                        visible: page.c.date && stage.layout !== "minimal"
                        text: "—  Friday 9 October"
                        size: 22; color: Theme.inkDim
                    }
                    // the search
                    Rectangle {
                        x: stage.centred ? (col.width - width) / 2 : 0
                        width: stage.layout === "left" ? 620 : 700; height: 66; radius: Theme.r(33)
                        color: Theme.alpha(Theme.surfaceLowest, 0.72)
                        border.width: page.c.focus === "search" ? 2.5 : 1
                        border.color: page.c.focus === "search" ? Theme.primary : Theme.alpha(Theme.ink, 0.12)
                        Rectangle {
                            id: chip
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            width: engineName.implicitWidth + 32; height: 46; radius: Theme.r(23)
                            color: Theme.primaryContainer
                            Txt { id: engineName; anchors.centerIn: parent; size: 16; weight: Font.DemiBold; color: Theme.inkPrimaryContainer
                                  text: (page.engines.find(e => e[0] === page.c.engine) ?? page.engines[0])[1] }
                        }
                        Rectangle {
                            visible: page.c.focus === "search"
                            anchors { left: chip.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            width: 2.5; height: 26; color: Theme.ink
                            SequentialAnimation on opacity {
                                running: visible; loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                        Txt {
                            anchors { left: chip.right; leftMargin: 24; verticalCenter: parent.verticalCenter }
                            text: "Search, or type an address"; size: 19; color: Theme.inkDim
                        }
                    }
                    // the links: tiles, pills or plain icons
                    Grid {
                        x: stage.centred ? (col.width - width) / 2 : 0
                        visible: page.links.length > 0
                        columns: stage.layout === "left" ? 2 : 9
                        spacing: stage.layout === "left" ? 12 : 14
                        Repeater {
                            model: page.links
                            Rectangle {
                                id: tile
                                required property var modelData
                                required property int index
                                readonly property string host: (modelData.url.match(/^\w+:\/\/([^/]+)/) ?? ["", ""])[1].replace(/^www\./, "")
                                width: stage.layout === "left" ? 290 : stage.layout === "minimal" ? 62 : 124
                                height: stage.layout === "left" ? 64 : stage.layout === "minimal" ? 62 : 116
                                radius: stage.layout === "left" || stage.layout === "minimal" ? height / 2 : 28
                                color: Theme.alpha(Theme.surfaceLowest, 0.62)
                                border.width: 1; border.color: Theme.alpha(Theme.ink, 0.09)
                                // a letter stands in for the site's icon
                                Rectangle {
                                    id: badge
                                    width: 40; height: 40; radius: stage.layout === "centre" ? 12 : 20
                                    x: stage.layout === "left" ? 14 : (parent.width - width) / 2
                                    y: stage.layout === "centre" ? 22 : (parent.height - height) / 2
                                    color: Theme.alpha(Theme.ink, 0.9)
                                    Txt { anchors.centerIn: parent; text: (tile.modelData.name || tile.host).charAt(0).toUpperCase(); size: 20; weight: Font.Bold; color: Theme.surfaceLowest }
                                }
                                Txt {
                                    visible: stage.layout !== "minimal"
                                    x: stage.layout === "left" ? 70 : (parent.width - width) / 2
                                    width: Math.min(implicitWidth, parent.width - 16)
                                    y: stage.layout === "left" ? (parent.height - height) / 2 : 74
                                    text: tile.modelData.name || tile.host; size: 15; weight: Font.Medium
                                }
                                Txt {
                                    visible: stage.layout !== "minimal"
                                    anchors { right: parent.right; rightMargin: stage.layout === "left" ? 22 : 12 }
                                    y: stage.layout === "left" ? (parent.height - height) / 2 : 10
                                    text: tile.index + 1; size: 12; color: Theme.inkDim; font.family: Theme.mono
                                }
                            }
                        }
                    }
                }
                Txt {
                    visible: page.c.keys
                    x: stage.centred ? (stage.width - width) / 2 : 144
                    y: stage.height - 46
                    text: (page.links.length ? "Esc then 1–" + page.links.length + " links  ·  " : "") + "/ search  ·  Tab engine"
                    size: 14; color: Theme.inkDim; opacity: 0.8
                }
            }
        }
        Txt {
            x: 10; width: parent.width - 20
            text: "Changes reach the next new tab you open."
            size: 12; color: Theme.inkDim
        }
        Item { width: 1; height: 4 }
    }

    // how it's laid out and how it behaves
    Section {
        icon: "tab"; title: "Start page"
        SetRow { icon: "dashboard"; label: "Layout"; hint: "Centred tiles, a poster down the left, or only the search and some icons" }
        Choice {
            x: 10; current: page.c.layout
            options: [{ value: "centre", label: "Centre" }, { value: "left", label: "Left" }, { value: "minimal", label: "Minimal" }]
            onPicked: v => page.c.layout = v
        }
        Item { width: 1; height: 6 }
        SetRow { icon: "keyboard"; label: "Typing goes to"; hint: "Where the keyboard is when a new tab opens" }
        Choice {
            x: 10; current: page.c.focus
            options: [{ value: "search", label: "The page's search" }, { value: "address", label: "Firefox's address bar" }]
            onPicked: v => page.c.focus = v
        }
        Item { width: 1; height: 6 }
        SetRow { icon: "search"; label: "Search with"; hint: "Tab on the page switches for that search" }
        Choice {
            x: 10; current: page.c.engine
            options: page.engines.map(e => ({ value: e[0], label: e[1] }))
            onPicked: v => page.c.engine = v
        }
        Item { width: 1; height: 6 }
    }

    Section {
        icon: "visibility"; title: "What it shows"
        SetRow { icon: "waving_hand"; label: "Greeting"; Toggle { checked: page.c.greeting; onToggled: on => page.c.greeting = on } }
        SetRow {
            icon: "badge"; label: "Name"; hint: "Who it greets; empty uses your user name"
            Field { text: page.c.name; placeholder: Quickshell.env("USER"); onEdited: t => page.c.name = t }
        }
        SetRow { icon: "schedule"; label: "Clock"; Toggle { checked: page.c.clock; onToggled: on => page.c.clock = on } }
        SetRow { icon: "timer"; label: "Seconds"; Toggle { checked: page.c.seconds; onToggled: on => page.c.seconds = on } }
        SetRow { icon: "today"; label: "Date"; Toggle { checked: page.c.date; onToggled: on => page.c.date = on } }
        SetRow { icon: "keyboard_command_key"; label: "Shortcut hints"; hint: "The line of keys along the bottom"; Toggle { checked: page.c.keys; onToggled: on => page.c.keys = on } }
        SetRow { icon: "blur_on"; label: "Wallpaper blur"; Range { value: page.c.blur; from: 0; to: 60; step: 1; suffix: " px"; onMoved: v => page.c.blur = v } }
        SetRow { icon: "contrast"; label: "Wallpaper dim"; Range { value: page.c.dim; from: 0; to: 0.85; step: 0.05; shownScale: 100; suffix: "%"; onMoved: v => page.c.dim = v } }
    }

    // the links
    Section {
        icon: "link"; title: "Links"
        Txt { x: 10; width: parent.width - 20; text: "Up to nine; the number keys open them in order."; size: 12; color: Theme.inkDim; bottomPadding: 8 }
        Repeater {
            model: page.c.links
            Item {
                id: linkRow
                required property var modelData
                required property int index
                width: parent.width; height: 52
                Txt { x: 14; anchors.verticalCenter: parent.verticalCenter; text: linkRow.index + 1; size: 13; color: Theme.inkDim; font.family: Theme.mono }
                Row {
                    x: 40; anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Field { width: 150; text: linkRow.modelData.name ?? ""; placeholder: "Name"; onEdited: t => page.editLink(linkRow.index, "name", t) }
                    Field {
                        width: Math.max(200, linkRow.width - 40 - 150 - 8 * 3 - 3 * 36 - 10)
                        text: linkRow.modelData.url ?? ""; placeholder: "https://…"
                        onEdited: t => page.editLink(linkRow.index, "url", /^[a-z]+:\/\//i.test(t) || t === "" ? t : "https://" + t)
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        IconButton { icon: "arrow_upward"; size: 36; opacity: linkRow.index > 0 ? 1 : 0.35; onClicked: page.moveLink(linkRow.index, -1) }
                        IconButton { icon: "arrow_downward"; size: 36; opacity: linkRow.index < page.c.links.length - 1 ? 1 : 0.35; onClicked: page.moveLink(linkRow.index, 1) }
                        IconButton { icon: "close"; size: 36; onClicked: { const l = page.c.links.slice(); l.splice(linkRow.index, 1); page.setLinks(l); } }
                    }
                }
            }
        }
        Item { width: 1; height: 6 }
        Btn {
            x: 10
            visible: page.c.links.length < 9
            icon: "add"; label: "Add a link"; tonal: true
            onClicked: page.setLinks(page.c.links.concat([{ name: "", url: "" }]))
        }
        Item { width: 1; height: 8 }
    }

    // Firefox's half: needs root once
    Section {
        id: setup
        icon: "extension"; title: "Firefox"
        readonly property string cmd: "sudo install -m644 " + Theme.home + "/Projects/yoru/config/firefox/mozilla.cfg /usr/lib/firefox/"
        readonly property bool ready: cfg.text().includes("chrome.js")
        FileView { id: cfg; path: "/usr/lib/firefox/mozilla.cfg"; printErrors: false }
        SetRow {
            icon: setup.ready ? "check_circle" : "error"
            label: setup.ready ? "Firefox loads yoru's script" : "Firefox doesn't load yoru's script yet"
            hint: setup.ready ? "New tabs open on this page with an empty address bar (restart Firefox once after installing it)"
                              : "Without it the address bar keeps the cursor and shows the page's path. Run this once, then restart Firefox:"
        }
        Rectangle {
            visible: !setup.ready
            x: 10; width: parent.width - 20; height: 46; radius: Theme.r(14)
            color: Theme.surfaceLowest
            Txt { anchors { left: parent.left; leftMargin: 16; right: copy.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                  text: setup.cmd; size: 12; font.family: Theme.mono; color: Theme.ink }
            IconButton { id: copy; anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                         icon: "content_copy"; size: 36; onClicked: Quickshell.execDetached(["wl-copy", setup.cmd]) }
        }
        Item { width: 1; height: 8 }
    }
}
