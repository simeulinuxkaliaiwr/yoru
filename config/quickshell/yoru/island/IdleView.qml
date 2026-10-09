import Quickshell
import QtQuick
import Quickshell.Widgets
import qs
import qs.parts

// the island at rest: workspaces · what's playing · the time · status
Item {
    id: v
    required property var isle
    required property string output
    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36

    readonly property var ws: Aro.wsFor(output)
    readonly property int cur: Aro.current(output)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16

        // ── workspaces: the current one stretches into a pill ──────
        Item {
            implicitWidth: pills.implicitWidth
            implicitHeight: 36
            Row {
                id: pills
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                Repeater {
                    model: v.ws
                    Rectangle {
                        required property var modelData
                        readonly property bool on: modelData.index === v.cur
                        readonly property bool numbers: Config.o.island.workspaces === "numbers"
                        width: numbers ? (on ? 26 : 18) : (on ? 22 : 8)
                        height: numbers ? 18 : 8
                        radius: numbers ? 9 : 4
                        Txt {
                            anchors.centerIn: parent
                            visible: parent.numbers
                            text: parent.modelData.index
                            size: 10; weight: Font.DemiBold
                            color: parent.on ? Theme.inkPrimary : Theme.ink
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        color: on ? Theme.primary : numbers ? (modelData.windows > 0 ? Theme.surfaceHighest : "transparent")
                             : modelData.windows > 0 ? Theme.inkDim : Theme.alpha(Theme.inkDim, 0.28)
                        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        MouseArea {
                            anchors { fill: parent; margins: -6 }
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Aro.dispatch("workspace", String(parent.modelData.index))
                        }
                    }
                }
            }
        }

        // ── now playing: a live activity that grows the island ─────
        Item {
            id: mediaSeg
            readonly property bool on: Config.o.island.showMedia && !!Media.player && Media.title !== ""
            visible: width > 1
            implicitWidth: on ? mediaRow.implicitWidth : 0
            implicitHeight: 36
            clip: true
            opacity: on ? 1 : 0
            Behavior on implicitWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            Row {
                id: mediaRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                ClippingRectangle {
                    width: 22; height: 22; radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceHigh
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(64, 64)
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Icon { anchors.centerIn: parent; name: "music_note"; size: 14; visible: Media.art === ""; color: Theme.inkDim }
                }
                Txt {
                    width: Math.min(implicitWidth, 190)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.title
                    size: 12
                    color: Theme.inkDim
                }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Media.playing ? "graphic_eq" : "pause"
                    size: 16
                    color: Media.playing ? Theme.primary : Theme.inkDim
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: v.isle.open("media", v.output) }
        }

        // ── the time ────────────────────────────────────────────────
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm AP")
            size: 14
            weight: Font.DemiBold
            font.features: { "tnum": 1 }
            MouseArea {
                anchors { fill: parent; margins: -8 }
                cursorShape: Qt.PointingHandCursor
                onClicked: v.isle.open("calendar", v.output)
            }
        }

        // ── status ──────────────────────────────────────────────────
        Item {
          implicitWidth: status.implicitWidth
          implicitHeight: 36
          Row {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Rectangle {
                visible: Notifs.count > 0 || Notifs.dnd
                width: 6; height: 6; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: Notifs.dnd ? Theme.outline : Theme.tertiary
            }
            Icon { name: "bluetooth_connected"; size: 16; color: Theme.inkDim; visible: Status.btConnected.length > 0 }
            Icon { name: Status.netIcon; size: 16; fill: 1; color: Theme.inkDim }
            Icon { name: Audio.icon; size: 16; fill: 1; color: Theme.inkDim }
            Row {
                visible: Status.hasBattery
                spacing: 2
                Icon {
                    name: Status.batteryIcon; size: 16; fill: 1
                    rotation: 90
                    color: Status.charge < 0.15 && !Status.charging ? Theme.danger : Theme.inkDim
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Config.o.island.batteryPercent
                    text: Math.round(Status.charge * 100)
                    size: 11; weight: Font.Medium
                    color: Theme.inkDim
                    font.features: { "tnum": 1 }
                }
            }
          }
          MouseArea {
              anchors { fill: parent; margins: -8 }
              cursorShape: Qt.PointingHandCursor
              onClicked: v.isle.open("control", v.output)
          }
        }
    }

    // scroll anywhere on the island to walk the workspaces
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real acc: 0
        onWheel: e => {
            acc += e.angleDelta.y;
            if (Math.abs(acc) < 100) return;
            const n = Math.max(1, Math.min(32, v.cur + (acc > 0 ? -1 : 1)));
            acc = 0;
            if (n !== v.cur) Aro.dispatch("workspace", String(n));
        }
    }
}
