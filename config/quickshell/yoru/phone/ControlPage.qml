import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Shapes
import qs
import qs.parts
import "actions.js" as Actions

// quick settings: the battery and the ways out, your tiles (Wi-Fi and Bluetooth open their
// panels), what's playing, and the brightness and the volume as tall sliders
Item {
    id: cp
    required property var phone
    property bool live: false
    property bool compact: false
    readonly property int pad: compact ? 12 : 18
    readonly property int gap: compact ? 8 : 10
    readonly property real unit: (width - 2 * pad - 3 * gap) / 4
    readonly property var tiles: (phone.c.tiles ?? []).filter((x, i, a) => x in Actions.all && a.indexOf(x) === i)

    onLiveChanged: {
        if (live) { Status.readBrightness(); Status.readUptime(); }
        asking(live);
    }
    // the processor and memory are read only while something shows them
    property bool watching: false
    function watch(on) {
        if (on === watching) return;
        SysStats.watchers += on ? 1 : -1;
        watching = on;
    }
    readonly property bool wantsStats: live && !compact
    onWantsStatsChanged: watch(wantsStats)
    Component.onCompleted: watch(wantsStats)
    Component.onDestruction: { watch(false); asking(false); }
    // and your real phone (KDE Connect), while this page shows
    property bool asked: false
    function asking(on) {
        if (on === asked) return;
        KDEConnect.users += on ? 1 : -1;
        asked = on;
    }

    // a ring that fills, its value inside and its name under it
    component Gauge: Column {
        id: g
        property real value: 0
        property string text
        property string label
        spacing: 4
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48; height: 48
            Shape {
                id: arc
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.alpha(Theme.ink, 0.12); strokeWidth: 5; fillColor: "transparent"
                    PathAngleArc { centerX: 24; centerY: 24; radiusX: 20; radiusY: 20; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: g.value > 0.85 ? Theme.danger : Theme.primary
                    strokeWidth: 5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 24; centerY: 24; radiusX: 20; radiusY: 20; startAngle: -90; sweepAngle: Math.max(1, 360 * Math.min(1, g.value)) }
                }
            }
            Txt { anchors.centerIn: parent; text: g.text; size: 11; weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: g.label; size: 10; color: Theme.inkDim }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    function key(e) {
        if (e.key === Qt.Key_Down || e.key === Qt.Key_Up) {
            const to = flick.contentY + (e.key === Qt.Key_Down ? 90 : -90);
            flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), to));
            return true;
        }
        return false;
    }

    // "3 h 12 min"
    function span(s) {
        const h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60);
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }
    readonly property string power: {
        const b = Status.battery;
        if (!Status.hasBattery || !b) return "Up " + Status.uptime;
        if (b.state === UPowerDeviceState.FullyCharged) return "Full";
        if (b.state === UPowerDeviceState.Charging) return b.timeToFull > 0 ? span(b.timeToFull) + " to full" : "Charging";
        if (b.timeToEmpty > 0) return span(b.timeToEmpty) + " left";
        return "On battery";
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + (cp.compact ? 10 : 18)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Behavior on contentY { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

        Column {
            id: col
            x: cp.pad
            y: cp.compact ? 6 : 10
            width: cp.width - 2 * cp.pad
            spacing: cp.compact ? 10 : 14

            // the battery (or how long it's been up) and the ways out
            Item {
                width: parent.width
                height: cp.compact ? 38 : 50
                Column {
                    anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                    Row {
                        spacing: 4
                        Txt {
                            text: Status.hasBattery ? Math.round(Status.charge * 100) + "%" : Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm")
                            size: cp.compact ? 20 : 26; weight: Font.DemiBold
                            color: Status.hasBattery && Status.charge < 0.15 && !Status.charging ? Theme.danger : Theme.ink
                            font.features: { "tnum": 1 }
                        }
                        Icon {
                            visible: Status.charging
                            anchors.verticalCenter: parent.verticalCenter
                            name: "bolt"; size: cp.compact ? 16 : 20; fill: 1; color: Theme.primary
                        }
                    }
                    Txt { text: cp.power; size: cp.compact ? 10 : 12; color: Theme.inkDim }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    IconButton { size: cp.compact ? 30 : 38; icon: "settings"; filled: true; onClicked: cp.phone.run("settings") }
                    IconButton { size: cp.compact ? 30 : 38; icon: "lock"; filled: true; onClicked: cp.phone.run("lock") }
                    IconButton { size: cp.compact ? 30 : 38; icon: "power_settings_new"; filled: true; onClicked: cp.phone.run("power") }
                }
            }

            Flow {
                width: parent.width + 1
                spacing: cp.gap
                Repeater {
                    model: cp.tiles
                    Tile {
                        required property string modelData
                        phone: cp.phone
                        name: modelData
                        wide: Actions.wide.includes(modelData)
                        compact: cp.compact
                        unit: cp.unit
                        gap: cp.gap
                    }
                }
            }

            // what's playing, beside the brightness and the volume
            Row {
                visible: !cp.compact
                spacing: cp.gap
                MediaTile {
                    phone: cp.phone
                    width: cp.unit * 2 + cp.gap
                    height: width
                }
                TallSlider {
                    width: cp.unit; height: cp.unit * 2 + cp.gap
                    value: Status.brightness
                    icon: Status.brightIcon
                    onMoved: v => Status.setBrightness(v)
                }
                TallSlider {
                    width: cp.unit; height: cp.unit * 2 + cp.gap
                    value: Audio.volume
                    muted: Audio.muted
                    icon: Audio.icon
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }
            }
            // this computer: how busy, how full, how warm
            Rectangle {
                visible: !cp.compact
                width: parent.width
                height: 96
                radius: Theme.r(28)
                color: Theme.alpha(Theme.surfaceHigh, 0.72)
                border.width: Theme.border
                border.color: Theme.borderColour
                Row {
                    anchors.centerIn: parent
                    spacing: (parent.width - 3 * 64) / 4
                    Gauge { width: 64; value: SysStats.cpu; text: Math.round(SysStats.cpu * 100) + "%"; label: "Processor" }
                    Gauge { width: 64; value: SysStats.mem; text: SysStats.memUsedGb.toFixed(1); label: "Memory, GB" }
                    Gauge { width: 64; value: SysStats.temp / 100; text: Math.round(SysStats.temp) + "°"; label: "Heat" }
                }
            }
            // your real phone, through KDE Connect: its battery, ringing it, and what it's been told
            Rectangle {
                id: real
                readonly property var d: KDEConnect.device
                visible: !!d
                width: parent.width
                height: realCol.implicitHeight + (cp.compact ? 16 : 24)
                radius: Theme.r(cp.compact ? 20 : 28)
                color: Theme.alpha(Theme.surfaceHigh, 0.72)
                border.width: Theme.border
                border.color: Theme.borderColour
                Column {
                    id: realCol
                    x: cp.compact ? 10 : 14; y: cp.compact ? 8 : 12
                    width: parent.width - 2 * x
                    spacing: 8
                    Item {
                        width: parent.width; height: 34
                        Icon { id: ph; anchors.verticalCenter: parent.verticalCenter; name: "smartphone"; size: 22; fill: 1; color: Theme.primary }
                        Column {
                            anchors { left: ph.right; leftMargin: 10; right: acts.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            Txt { width: parent.width; text: real.d?.name ?? ""; size: 13; weight: Font.DemiBold }
                            Txt {
                                width: parent.width
                                text: (real.d && real.d.battery >= 0 ? real.d.battery + "%" + (real.d.charging ? ", charging" : "") : "Connected") + "  ·  KDE Connect"
                                size: 10; color: Theme.inkDim
                            }
                        }
                        Row {
                            id: acts
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            IconButton { size: cp.compact ? 28 : 32; icon: "ring_volume"; filled: true; onClicked: KDEConnect.act("ring") }
                            IconButton { size: cp.compact ? 28 : 32; icon: "content_paste_go"; filled: true; onClicked: KDEConnect.act("clipboard") }
                            IconButton { size: cp.compact ? 28 : 32; icon: "waving_hand"; filled: true; onClicked: KDEConnect.act("ping") }
                        }
                    }
                    Repeater {
                        model: (real.d?.notifications ?? []).slice(0, cp.compact ? 2 : 3)
                        Row {
                            required property var modelData
                            spacing: 8
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: Theme.tertiary }
                            Txt {
                                width: realCol.width - 12
                                text: "<b>" + (modelData.app || "") + "</b>  " + [modelData.title, modelData.text].filter(x => x).join(": ")
                                textFormat: Text.StyledText
                                size: 11; color: Theme.inkDim
                            }
                        }
                    }
                }
            }
            // a flip's screen is short: the sliders lie down, the music is a row
            Column {
                visible: cp.compact
                width: parent.width
                spacing: 8
                Slider {
                    width: parent.width; h: 32
                    value: Status.brightness; icon: Status.brightIcon
                    onMoved: x => Status.setBrightness(x)
                }
                Slider {
                    width: parent.width; h: 32
                    value: Audio.volume; muted: Audio.muted; icon: Audio.icon
                    onMoved: x => Audio.setVolume(x)
                    onIconClicked: Audio.toggleMute()
                }
                MediaTile {
                    phone: cp.phone
                    width: parent.width
                    height: 58
                    row: true
                }
            }
        }
    }
}
