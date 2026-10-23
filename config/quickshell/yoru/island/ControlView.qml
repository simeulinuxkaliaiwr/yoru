import Quickshell
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// the control centre: sliders, toggles, what's playing and the notifications
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "control"
    implicitWidth: 440
    implicitHeight: col.implicitHeight + 36

    onShownChanged: if (shown) { Status.readBrightness(); Status.readUptime(); Notifs.unseen = 0; }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }

    // a quick-settings tile: icon, name, a line of state
    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        property string sub: ""
        property bool on: false
        signal clicked()
        width: (col.width - 8) / 2
        height: 62
        radius: on ? 20 : 31
        color: on ? Theme.primaryContainer : Theme.surfaceMid
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Rectangle {
            id: bubble
            x: 10; anchors.verticalCenter: parent.verticalCenter
            width: 42; height: 42; radius: Theme.r(21)
            color: tile.on ? Theme.primary : Theme.surfaceHighest
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Icon { anchors.centerIn: parent; name: tile.icon; size: 21; fill: tile.on ? 1 : 0; color: tile.on ? Theme.inkPrimary : Theme.ink }
        }
        Column {
            anchors { left: bubble.right; leftMargin: 10; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            Txt { width: parent.width; text: tile.label; size: 13; weight: Font.DemiBold; color: tile.on ? Theme.inkPrimaryContainer : Theme.ink }
            Txt { width: parent.width; visible: text !== ""; text: tile.sub; size: 11; color: tile.on ? Theme.inkPrimaryContainer : Theme.inkDim; opacity: 0.85 }
        }
        StateLayer { tint: tile.on ? Theme.inkPrimaryContainer : Theme.ink; onClicked: tile.clicked() }
    }

    Column {
        id: col
        x: 18; y: 18
        width: parent.width - 36
        spacing: 14

        // hello
        Item {
            width: parent.width; height: 44
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: v.greeting + ", " + Quickshell.env("USER"); size: 18; weight: Font.DemiBold }
                Txt {
                    text: Qt.formatDate(clock.date, "dddd, d MMMM") + "  ·  up " + Status.uptime
                    size: 12; color: Theme.inkDim
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6
                IconButton { icon: "lock"; filled: true; onClicked: { v.isle.close(); Quickshell.execDetached(["yoru-lock"]); } }
                IconButton { icon: "power_settings_new"; filled: true; onClicked: v.isle.open("power", v.isle.output) }
            }
        }

        // sliders
        Slider {
            width: parent.width
            value: Audio.volume; muted: Audio.muted; icon: Audio.icon
            onMoved: x => Audio.setVolume(x)
            onIconClicked: Audio.toggleMute()
        }
        Slider {
            width: parent.width
            value: Status.brightness; icon: Status.brightIcon
            onMoved: x => Status.setBrightness(x)
        }

        // toggles
        Grid {
            width: parent.width
            columns: 2
            spacing: 8
            Tile {
                icon: Status.netIcon; label: "Wi-Fi"; sub: Status.netName
                on: Status.wifiOn && (Status.signal >= 0 || Status.ethernet)
                onClicked: Status.toggleWifi()
            }
            Tile {
                icon: Status.btOn ? "bluetooth" : "bluetooth_disabled"; label: "Bluetooth"
                sub: !Status.btOn ? "Off" : Status.btConnected.length > 0 ? Status.btConnected[0].name : "On"
                on: Status.btOn
                onClicked: Status.toggleBt()
            }
            Tile {
                icon: "nightlight"; label: "Night light"; sub: Status.night ? "4000K" : "Off"
                on: Status.night
                onClicked: Status.night = !Status.night
            }
            Tile {
                icon: "coffee"; label: "Caffeine"; sub: Status.caffeine ? "Staying awake" : "Off"
                on: Status.caffeine
                onClicked: Status.caffeine = !Status.caffeine
            }
            Tile {
                icon: Notifs.dnd ? "notifications_off" : "notifications"; label: "Do not disturb"
                sub: !Notifs.dnd ? "Off" : Notifs.quietHours ? "Quiet hours" : Focus.active && !Notifs.manualDnd ? "Focusing" : "Quiet"
                on: Notifs.dnd
                onClicked: Notifs.toggleDnd()
            }
            Tile {
                icon: "wallpaper"; label: "Wallpaper"; sub: "Pick a new night"
                onClicked: v.isle.open("walls", v.isle.output)
            }
            Tile {
                icon: Focus.phase === "break" ? "self_improvement" : "timer"; label: "Focus"
                sub: !Focus.active ? Config.o.focus.minutes + " min" + (Focus.today > 0 ? "  ·  " + Focus.today + " today" : "")
                                   : (Focus.phase === "break" ? "Break · " : "") + Focus.clock(Focus.left)
                on: Focus.active
                onClicked: Focus.toggle()
            }
            Tile {
                icon: "screen_record"; label: "Record"; sub: Recorder.active ? Focus.clock(Recorder.seconds) : "The screen"
                on: Recorder.active
                onClicked: { v.isle.close(); Recorder.toggle(""); }
            }
        }

        // the countdown and the stopwatch, while either has time on it
        Rectangle {
            visible: Timers.counting || Timers.watched > 0
            width: parent.width; height: 52
            radius: Theme.r(22)
            color: Theme.surfaceMid
            Row {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 22
                Row {
                    visible: Timers.counting
                    spacing: 4
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "hourglass_top"; size: 18; color: Theme.tertiary }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter; rightPadding: 4
                        text: Timers.clock(Timers.left); size: 14; weight: Font.DemiBold; font.features: { "tnum": 1 }
                    }
                    IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "more_time"; size: 30; onClicked: Timers.add(1) }
                    IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "close"; size: 30; onClicked: Timers.cancel() }
                }
                Row {
                    visible: Timers.watched > 0 || Timers.watching
                    spacing: 4
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "timer"; size: 18; color: Theme.secondary }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter; rightPadding: 4
                        text: Timers.clock(Timers.watched); size: 14; weight: Font.DemiBold; font.features: { "tnum": 1 }
                    }
                    IconButton { anchors.verticalCenter: parent.verticalCenter; icon: Timers.watching ? "pause" : "play_arrow"; size: 30; onClicked: Timers.watchToggle() }
                    IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "restart_alt"; size: 30; onClicked: Timers.watchReset() }
                }
            }
        }

        // media, small
        Rectangle {
            visible: !!Media.player
            width: parent.width; height: 64
            radius: Theme.r(22)
            color: Theme.surfaceMid
            ClippingRectangle {
                id: art
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 44; radius: Theme.r(12)
                color: Theme.surfaceHigh
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(88, 88); asynchronous: true }
            }
            Column {
                anchors { left: art.right; leftMargin: 12; right: ctl.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                Txt { width: parent.width; text: Media.title; size: 13; weight: Font.DemiBold }
                Txt { width: parent.width; text: Media.artist; size: 11; color: Theme.inkDim }
            }
            MouseArea { anchors { left: parent.left; right: ctl.left; top: parent.top; bottom: parent.bottom }
                        cursorShape: Qt.PointingHandCursor; onClicked: v.isle.open("media", v.isle.output) }
            Row {
                id: ctl
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 2
                IconButton { icon: "skip_previous"; size: 34; onClicked: Media.prev() }
                IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 38; active: true; onClicked: Media.toggle() }
                IconButton { icon: "skip_next"; size: 34; onClicked: Media.next() }
            }
        }

        // notifications
        Item {
            width: parent.width; height: 24
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; size: 13; weight: Font.DemiBold; color: Theme.inkDim }
            Txt {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: Notifs.count > 0
                text: "Clear all"; size: 12; weight: Font.Medium; color: Theme.primary
                MouseArea { anchors { fill: parent; margins: -6 } cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clear() }
            }
        }
        Item {
            visible: Notifs.count === 0
            width: parent.width; height: 64
            Column {
                anchors.centerIn: parent
                spacing: 4
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bedtime"; size: 26; color: Theme.outline }
                Txt { text: "All quiet tonight"; size: 12; color: Theme.outline }
            }
        }
        // grouped by app: the newest two of each, the rest behind "more"
        Flickable {
            id: notes
            visible: Notifs.count > 0
            width: parent.width
            // whatever room the island's 720 px window has left; the rest scrolls
            height: Math.min(contentHeight, Math.max(140, 670 - y))
            contentHeight: groups.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            property var open: ({})             // app → shows all of its
            function ago(t) {
                const m = Math.floor((clock.date.getTime() - t) / 60000);
                if (m < 1) return "now";
                if (m < 60) return m + " min";
                const h = Math.floor(m / 60);
                return h < 24 ? h + " h" : Math.floor(h / 24) + " d";
            }
            Column {
                id: groups
                width: parent.width
                spacing: 8
                Repeater {
                    model: Notifs.groups
                    Rectangle {
                        id: group
                        required property var modelData
                        readonly property bool all: notes.open[modelData.app] === true
                        readonly property var shown: all ? modelData.items : modelData.items.slice(0, 2)
                        width: groups.width
                        height: inner.implicitHeight + 16
                        radius: Theme.r(20)
                        color: Theme.surfaceMid
                        Column {
                            id: inner
                            x: 8; y: 8
                            width: parent.width - 16
                            spacing: 2
                            // the app: its icon, name, how many, and clearing them all
                            Item {
                                width: parent.width; height: 30
                                Image {
                                    id: gimg
                                    x: 4; anchors.verticalCenter: parent.verticalCenter
                                    width: 20; height: 20
                                    source: group.modelData.icon
                                    sourceSize: Qt.size(40, 40)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }
                                Icon { x: 4; anchors.verticalCenter: parent.verticalCenter; visible: !gimg.visible; name: "notifications"; size: 18; color: Theme.inkDim }
                                Txt {
                                    anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
                                    text: group.modelData.app + (group.modelData.items.length > 1 ? "  ·  " + group.modelData.items.length : "")
                                    size: 12; weight: Font.DemiBold; color: Theme.inkDim
                                }
                                IconButton {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    icon: "clear_all"; size: 28
                                    onClicked: Notifs.forgetApp(group.modelData.app)
                                }
                            }
                            Repeater {
                                model: group.shown
                                Rectangle {
                                    id: card
                                    required property var modelData
                                    // still held by its app: its buttons work too
                                    readonly property var actions: (Notifs.live[modelData.key]?.actions ?? []).filter(a => a.identifier !== "default")
                                    width: inner.width
                                    height: Math.max(48, body.implicitHeight + 16)
                                    radius: Theme.r(14)
                                    color: press.containsMouse ? Theme.mix(Theme.surfaceHigh, Theme.ink, 0.05) : Theme.surfaceHigh
                                    // a click opens it, as the pop-up would have
                                    MouseArea {
                                        id: press
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        // taken first: opening it takes the card away mid-click
                                        onClicked: { const isle = v.isle; if (Notifs.open(card.modelData)) isle.close(); }
                                    }
                                    Column {
                                        id: body
                                        anchors { left: parent.left; leftMargin: 12; right: when.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                        spacing: 1
                                        Txt { width: parent.width; text: card.modelData.summary; size: 13; weight: Font.DemiBold }
                                        Txt {
                                            width: parent.width; visible: text !== ""
                                            text: card.modelData.body; textFormat: Text.StyledText
                                            wrapMode: Text.Wrap; maximumLineCount: 3; size: 12; color: Theme.inkDim
                                        }
                                        Flow {
                                            visible: card.actions.length > 0
                                            width: parent.width
                                            spacing: 6
                                            topPadding: 6; bottomPadding: 2
                                            Repeater {
                                                model: card.actions
                                                Rectangle {
                                                    required property var modelData
                                                    height: 26
                                                    width: alabel.implicitWidth + 22
                                                    radius: Theme.r(13)
                                                    color: Theme.secondaryContainer
                                                    Txt { id: alabel; anchors.centerIn: parent; text: parent.modelData.text; size: 11; weight: Font.Medium; color: Theme.inkSecondaryContainer }
                                                    StateLayer { onClicked: { const key = card.modelData.key; parent.modelData.invoke(); Notifs.forget(key); } }
                                                }
                                            }
                                        }
                                    }
                                    Txt {
                                        id: when
                                        anchors { right: x.left; rightMargin: 2; top: parent.top; topMargin: 11 }
                                        text: notes.ago(card.modelData.time); size: 11; color: Theme.outline
                                    }
                                    IconButton { id: x; anchors { right: parent.right; rightMargin: 4; top: parent.top; topMargin: 4 } icon: "close"; size: 26; onClicked: Notifs.forget(card.modelData.key) }
                                }
                            }
                            Txt {
                                visible: group.modelData.items.length > 2
                                x: 12; height: 24; verticalAlignment: Text.AlignVCenter
                                text: group.all ? "Show less" : (group.modelData.items.length - 2) + " more"
                                size: 12; weight: Font.Medium; color: Theme.primary
                                MouseArea {
                                    anchors { fill: parent; margins: -6 }
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { const o = Object.assign({}, notes.open); o[group.modelData.app] = !group.all; notes.open = o; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
