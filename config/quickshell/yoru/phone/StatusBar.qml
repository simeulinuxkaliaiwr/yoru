import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.parts

// the top of the phone's screen. slab: the time, a little island that shows what the big
// one would (the music, a recording, the focus timer), and the status; keitai: signal bars,
// the time in the middle and the battery, as on a flip phone; bare: the time and the status
Item {
    id: sb
    required property var phone
    property string look: "slab"
    property bool compact: false
    height: look === "keitai" ? 24 : look === "slab" ? 46 : 40

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property string time: Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm")
    readonly property color dim: Theme.inkDim

    // slab and bare: the time on the left, the status on the right
    Txt {
        visible: sb.look !== "keitai"
        x: sb.look === "slab" ? 32 : 22
        anchors { verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
        text: sb.time
        size: 15; weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    Row {
        visible: sb.look !== "keitai"
        anchors { right: parent.right; rightMargin: sb.look === "slab" ? 26 : 20; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
        spacing: 5
        Rectangle {
            visible: Notifs.unseen > 0 || Notifs.dnd
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: Notifs.dnd ? Theme.outline : Theme.tertiary
        }
        Icon { anchors.verticalCenter: parent.verticalCenter; visible: Status.btConnected.length > 0; name: "bluetooth"; size: 15; color: sb.dim }
        Icon { anchors.verticalCenter: parent.verticalCenter; name: Status.netIcon; size: 15; fill: 1; color: sb.dim }
        Row {
            visible: Status.hasBattery
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Status.batteryIcon; size: 15; fill: 1
                rotation: 90
                color: Status.charge < 0.15 && !Status.charging ? Theme.danger : sb.dim
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Status.charge * 100)
                size: 11; weight: Font.DemiBold; color: sb.dim
                font.features: { "tnum": 1 }
            }
        }
    }

    // the little island: a dark pill, wider while something's happening
    Rectangle {
        id: pill
        visible: sb.look === "slab"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 9
        height: 28
        readonly property string doing: Recorder.active ? "rec" : Focus.active ? "focus" : Media.playing ? "media" : ""
        width: doing !== "" ? 156 : 92
        radius: Theme.r(14)
        color: Qt.darker(Theme.island, 1.4)
        border.width: 1
        border.color: Theme.alpha(Theme.ink, 0.06)
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        // the camera, at the right end
        Rectangle {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            width: 9; height: 9; radius: 4.5
            color: Qt.darker(Theme.island, 2)
            border.width: 1; border.color: Theme.alpha(Theme.primary, 0.18)
        }
        Item {
            anchors { fill: parent; leftMargin: 6; rightMargin: 26 }
            opacity: pill.doing !== "" && pill.width > 140 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            // the music: its cover, and bars that move while it plays
            Row {
                visible: pill.doing === "media"
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 8
                ClippingRectangle {
                    width: 18; height: 18; radius: Theme.r(6)
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceHigh
                    Image { id: thumb; anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(36, 36); asynchronous: true }
                    Icon { anchors.centerIn: parent; visible: thumb.status !== Image.Ready; name: "music_note"; size: 12; color: Theme.inkDim }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    text: Media.title
                    size: 11; color: Theme.inkDim
                }
            }
            Row {
                visible: pill.doing === "media"
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; radius: 1.5
                        height: 4
                        color: Theme.primary
                        // a beat each, out of step with the others
                        SequentialAnimation on height {
                            running: Media.playing && sb.phone.shown && pill.doing === "media"
                            loops: Animation.Infinite
                            NumberAnimation { to: 6 + (index * 5) % 9; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 3; duration: 300 + index * 50; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
            // recording: a red dot and the time
            Row {
                visible: pill.doing === "rec"
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                spacing: 7
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 9; radius: 4.5; color: "#ff4f5e" }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Focus.clock(Recorder.seconds); size: 11; weight: Font.DemiBold; color: "#ff8a94"; font.features: { "tnum": 1 } }
            }
            // focusing: what's left
            Row {
                visible: pill.doing === "focus"
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; name: Focus.phase === "break" ? "self_improvement" : "timer"; size: 14; fill: 1; color: Focus.phase === "break" ? Theme.tertiary : Theme.primary }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Focus.clock(Focus.left); size: 11; weight: Font.DemiBold; color: Focus.phase === "break" ? Theme.tertiary : Theme.primary; font.features: { "tnum": 1 } }
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: pill.doing !== ""
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.phone.go(pill.doing === "media" ? "music" : "control")
        }
    }

    // keitai: a band across the top, as on a flip phone
    Rectangle {
        visible: sb.look === "keitai"
        anchors.fill: parent
        color: Theme.alpha(Theme.surfaceLowest, 0.72)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.ink, 0.08) }
        // signal: four bars from the Wi-Fi's strength; a cross with none
        Row {
            anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
            spacing: 2
            readonly property int bars: Status.ethernet ? 4 : !Status.wifiOn || Status.signal < 0 ? 0 : Math.max(1, Math.ceil(Status.signal / 25))
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: 3; height: 4 + index * 2.5; radius: 1
                    color: index < parent.bars ? Theme.ink : Theme.alpha(Theme.ink, 0.22)
                }
            }
            Txt {
                visible: parent.bars === 0
                anchors.bottom: parent.bottom
                text: "×"; size: 11; weight: Font.Bold; color: Theme.danger
                height: 12
            }
        }
        Row {
            anchors.centerIn: parent
            spacing: 5
            Icon { anchors.verticalCenter: parent.verticalCenter; visible: Notifs.unseen > 0; name: "mail"; size: 13; fill: 1; color: Theme.tertiary }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: sb.time; size: 12; weight: Font.DemiBold; font.features: { "tnum": 1 } }
            Icon { anchors.verticalCenter: parent.verticalCenter; visible: Status.btConnected.length > 0; name: "bluetooth"; size: 12; color: sb.dim }
        }
        // the battery: three blocks in an outline
        Item {
            id: cell
            visible: Status.hasBattery
            anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
            width: 24; height: 11
            readonly property int blocks: Math.min(3, Math.ceil(Status.charge * 3 - 0.05))
            Rectangle {
                width: 21; height: 11; radius: 2
                color: "transparent"
                border.width: 1.2; border.color: Status.charge < 0.15 && !Status.charging ? Theme.danger : Theme.ink
                Row {
                    anchors { fill: parent; margins: 2 }
                    spacing: 1.5
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: (17 - 3) / 3; height: 7; radius: 0.5
                            color: Status.charging ? Theme.primary : Theme.ink
                            opacity: index < cell.blocks ? 1 : 0.15
                        }
                    }
                }
            }
            Rectangle { x: 21; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 5; radius: 1; color: Theme.ink }
        }
    }
}
