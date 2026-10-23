import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs
import qs.parts
import qs.phone

// the control centre's sound: where it plays (a click makes one the default), the mic,
// and each app that's playing, with its own volume
Item {
    id: sp
    required property var host              // the control centre, as the phone's panels want it
    implicitHeight: Math.min(590, head.height + body.implicitHeight + 12)

    // by their type: their properties and volumes only arrive once they're tracked
    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.type === PwNodeType.AudioSink && !n.properties?.["node.virtual"])
    readonly property var inputs: nodes.filter(n => n.type === PwNodeType.AudioSource && !n.properties?.["node.virtual"])
    readonly property var apps: nodes.filter(n => n.type === PwNodeType.AudioOutStream)
    PwObjectTracker { objects: sp.outputs.concat(sp.inputs, sp.apps) }

    function nameOf(n) { return n.nickname || n.description || n.name; }
    function glyph(n, input) {
        const p = n.properties ?? {}, s = (nameOf(n) + " " + (p["device.icon-name"] ?? "") + " " + (p["device.form-factor"] ?? "")).toLowerCase();
        if (/headset|headphone|earbud|buds|airpods/.test(s) || p["device.bus"] === "bluetooth") return input ? "headset_mic" : "headphones";
        if (/hdmi|displayport|\btv\b|monitor/.test(s)) return "tv";
        if (p["device.bus"] === "usb") return input ? "mic_external_on" : "speaker";
        return input ? "mic" : "speaker";
    }
    function appName(n) { return n.properties?.["application.name"] || nameOf(n); }
    function appIcon(n) {
        const p = n.properties ?? {};
        const e = DesktopEntries.heuristicLookup(p["application.process.binary"] ?? "") ?? DesktopEntries.heuristicLookup(appName(n));
        return Quickshell.iconPath(p["application.icon-name"] ?? e?.icon ?? "", "audio-x-generic");
    }

    PanelHead {
        id: head
        phone: sp.host
        title: "Sound"
        switchable: false
    }

    // a device to pick: the default one is filled
    component Device: Rectangle {
        id: dev
        required property var node
        property bool input: false
        readonly property bool on: input ? Pipewire.defaultAudioSource === node : Pipewire.defaultAudioSink === node
        width: parent.width; height: 46
        radius: Theme.r(on ? 16 : 23)
        color: on ? Theme.primaryContainer : Theme.surfaceMid
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Icon {
            id: dico
            x: 14; anchors.verticalCenter: parent.verticalCenter
            name: sp.glyph(dev.node, dev.input); size: 20; fill: dev.on ? 1 : 0
            color: dev.on ? Theme.inkPrimaryContainer : Theme.inkDim
        }
        Txt {
            anchors { left: dico.right; leftMargin: 12; right: tick.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: sp.nameOf(dev.node); size: 13; weight: dev.on ? Font.DemiBold : Font.Medium
            color: dev.on ? Theme.inkPrimaryContainer : Theme.ink
        }
        Icon {
            id: tick
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            name: "check"; size: 18; visible: dev.on; color: Theme.inkPrimaryContainer
        }
        StateLayer {
            tint: dev.on ? Theme.inkPrimaryContainer : Theme.ink
            onClicked: {
                if (dev.input) Pipewire.preferredDefaultAudioSource = dev.node;
                else Pipewire.preferredDefaultAudioSink = dev.node;
            }
        }
    }
    component Label: Txt {
        x: 6; topPadding: 4
        size: 12; weight: Font.DemiBold; color: Theme.inkDim
    }

    Flickable {
        anchors { top: head.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: body
            width: parent.width
            spacing: 8

            Label { text: "Output" }
            Repeater { model: sp.outputs; Device { required property var modelData; node: modelData } }
            Txt { visible: sp.outputs.length === 0; x: 6; text: "Nothing to play on"; size: 12; color: Theme.outline }
            Slider {
                width: parent.width
                visible: Audio.ready
                value: Audio.volume; muted: Audio.muted; icon: Audio.icon
                onMoved: x => Audio.setVolume(x)
                onIconClicked: Audio.toggleMute()
            }

            Label { text: "Input"; visible: sp.inputs.length > 0 }
            Repeater { model: sp.inputs; Device { required property var modelData; node: modelData; input: true } }
            Slider {
                width: parent.width
                visible: !!Audio.source?.audio
                value: Audio.source?.audio?.volume ?? 0; muted: Audio.micMuted
                icon: Audio.micMuted ? "mic_off" : "mic"
                onMoved: x => { if (Audio.source?.audio) { Audio.source.audio.muted = false; Audio.source.audio.volume = x; } }
                onIconClicked: Audio.toggleMic()
            }

            Label { text: "Apps"; visible: sp.apps.length > 0 }
            Repeater {
                model: sp.apps
                Rectangle {
                    id: app
                    required property var modelData
                    readonly property var a: modelData.audio
                    // apps go past 100% (PipeWire allows it, and some sit there): the slider reaches 150%
                    readonly property real most: Math.max(1.5, a?.volume ?? 0)
                    width: body.width; height: 74
                    radius: Theme.r(20)
                    color: Theme.surfaceMid
                    Image {
                        id: aico
                        x: 12; y: 10
                        width: 22; height: 22
                        sourceSize: Qt.size(44, 44)
                        source: sp.appIcon(app.modelData)
                        asynchronous: true
                    }
                    Txt {
                        id: pct
                        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 10 }
                        text: (app.a?.muted ?? false) ? "muted" : Math.round((app.a?.volume ?? 0) * 100) + "%"
                        size: 11; weight: Font.Medium; color: Theme.inkDim
                        font.features: { "tnum": 1 }
                    }
                    Column {
                        anchors { left: aico.right; leftMargin: 10; right: pct.left; rightMargin: 8; top: parent.top; topMargin: 8 }
                        Txt { width: parent.width; text: sp.appName(app.modelData); size: 12; weight: Font.DemiBold }
                        Txt {
                            width: parent.width; visible: text !== "" && text !== sp.appName(app.modelData)
                            text: app.modelData.properties?.["media.name"] ?? ""; size: 11; color: Theme.inkDim
                        }
                    }
                    Slider {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
                        h: 26
                        value: (app.a?.volume ?? 0) / app.most; muted: app.a?.muted ?? false
                        icon: (app.a?.muted ?? false) ? "volume_off" : "volume_up"
                        onMoved: x => { if (app.a) { app.a.muted = false; app.a.volume = x * app.most; } }
                        onIconClicked: if (app.a) app.a.muted = !app.a.muted
                    }
                }
            }
            Txt { visible: sp.apps.length === 0; x: 6; text: "No app is playing"; size: 12; color: Theme.outline }
        }
    }
}
