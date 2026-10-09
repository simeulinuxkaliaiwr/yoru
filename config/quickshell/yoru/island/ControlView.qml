import Quickshell
import QtQuick
import qs
import qs.parts

// the control centre: sliders, toggles, what's playing and the notifications
Item {
    id: v
    required property var isle
    readonly property bool shown: isle?.mode === "control"
    implicitWidth: 440
    implicitHeight: col.implicitHeight + 36

    onShownChanged: if (shown) { Status.readBrightness(); Status.readUptime(); }
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
            width: 42; height: 42; radius: 21
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

        // ── hello ───────────────────────────────────────────────────
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
                IconButton { icon: "lock"; filled: true; onClicked: { v.isle.close(); Quickshell.execDetached(["aro-lock", "-f"]); } }
                IconButton { icon: "power_settings_new"; filled: true; onClicked: v.isle.open("power", v.isle.output) }
            }
        }

        // ── sliders ─────────────────────────────────────────────────
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

        // ── toggles ─────────────────────────────────────────────────
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
                sub: Notifs.dnd ? "Quiet" : "Off"
                on: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Tile {
                icon: "wallpaper"; label: "Wallpaper"; sub: "Pick a new night"
                onClicked: v.isle.open("walls", v.isle.output)
            }
        }

        // ── media, small ────────────────────────────────────────────
        Rectangle {
            visible: !!Media.player
            width: parent.width; height: 64
            radius: 22
            color: Theme.surfaceMid
            Rectangle {
                id: art
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 44; radius: 12
                color: Theme.surfaceHigh; clip: true
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

        // ── notifications ───────────────────────────────────────────
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
        ListView {
            id: notes
            visible: Notifs.count > 0
            width: parent.width
            height: Math.min(contentHeight, 260)
            spacing: 6
            clip: true
            model: Notifs.list
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal } }
            removeDisplaced: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            delegate: Rectangle {
                id: card
                required property var modelData
                width: notes.width
                height: Math.max(58, body.implicitHeight + 22)
                radius: 18
                color: Theme.surfaceMid
                Image {
                    id: nimg
                    x: 12; y: 12
                    width: 34; height: 34
                    source: Notifs.image(card.modelData)
                    sourceSize: Qt.size(68, 68)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Column {
                    id: body
                    anchors { left: nimg.visible ? nimg.right : parent.left; leftMargin: 12; right: x.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Txt { width: parent.width; text: card.modelData.summary; size: 13; weight: Font.DemiBold }
                    Txt {
                        width: parent.width; visible: text !== ""
                        text: card.modelData.body; textFormat: Text.StyledText
                        wrapMode: Text.Wrap; maximumLineCount: 3; size: 12; color: Theme.inkDim
                    }
                }
                IconButton { id: x; anchors { right: parent.right; rightMargin: 6; top: parent.top; topMargin: 6 } icon: "close"; size: 28; onClicked: card.modelData.dismiss() }
            }
        }
    }
}
