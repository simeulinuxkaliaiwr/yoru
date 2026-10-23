import QtQuick
import qs
import qs.parts

// volume, brightness or the mic, in the island for a moment
Item {
    id: v
    required property var isle
    readonly property string kind: isle?.osdKind ?? "volume"
    readonly property var idle: isle?.idle ?? null
    readonly property real value: kind === "brightness" ? Status.brightness : kind === "mic" ? (Audio.micMuted ? 0 : 1)
        : kind === "idle" ? (idle && idle.secs > 0 ? idle.left / idle.secs : 0) : Audio.volume
    readonly property bool muted: kind === "volume" ? Audio.muted : kind === "mic" ? Audio.micMuted : false
    readonly property string icon: kind === "brightness" ? Status.brightIcon : kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
        : kind === "idle" ? "lock_clock" : Audio.icon

    implicitWidth: 320
    implicitHeight: 44

    Row {
        anchors.centerIn: parent
        spacing: 12
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: v.icon; size: 20; fill: 1
            color: v.muted ? Theme.outline : Theme.primary
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 200; height: 6; radius: Theme.r(3)
            color: Theme.surfaceHighest
            Rectangle {
                height: parent.height; radius: Theme.r(3)
                width: Math.max(6, parent.width * Math.min(1, v.value))
                color: v.muted ? Theme.outline : Theme.primary
                Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            }
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            horizontalAlignment: Text.AlignRight
            text: v.kind === "mic" ? (v.muted ? "off" : "on") : v.kind === "idle" ? (v.idle?.left ?? 0) + "s" : Math.round(v.value * 100)
            size: 12; weight: Font.DemiBold
            color: Theme.inkDim
            font.features: { "tnum": 1 }
        }
    }
}
