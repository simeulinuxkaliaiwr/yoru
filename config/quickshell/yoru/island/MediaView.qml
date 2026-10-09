import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// the player, opened out: the cover, a wavy progress line, the controls
Item {
    id: v
    required property var isle
    implicitWidth: 480
    implicitHeight: 196
    readonly property real frac: Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0

    // the cover again, blurred, as a glow behind everything
    Image {
        id: glow
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(96, 96)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: glow
        visible: glow.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: 0.2
        opacity: 0.32
    }

    Rectangle {
        id: cover
        x: 22; y: 22
        width: 152; height: 152
        radius: 22
        color: Theme.surfaceHigh
        clip: true
        Image {
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(304, 304)
            asynchronous: true
        }
        Icon { anchors.centerIn: parent; visible: Media.art === ""; name: "album"; size: 56; color: Theme.inkDim }
        // a little bounce when the track changes
        scale: 1
        Connections {
            target: Media
            function onTitleChanged() { bump.restart(); }
        }
        SequentialAnimation on scale {
            id: bump; running: false
            NumberAnimation { to: 0.9; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatialSlow }
        }
    }

    Column {
        anchors { left: cover.right; leftMargin: 20; right: parent.right; rightMargin: 22; top: cover.top; topMargin: 4 }
        spacing: 2
        Txt { width: parent.width; text: Media.title || "Nothing playing"; size: 17; weight: Font.DemiBold }
        Txt { width: parent.width; text: Media.artist; size: 13; color: Theme.inkDim }
    }

    // ── progress: a wave while playing, a straight line while paused
    Item {
        id: bar
        anchors { left: cover.right; leftMargin: 20; right: parent.right; rightMargin: 22 }
        y: 98
        height: 20
        Canvas {
            id: wave
            anchors.fill: parent
            property real frac: v.frac
            property real amp: Media.playing ? 3 : 0
            property color fillColour: Theme.primary
            property color restColour: Theme.surfaceHighest
            Behavior on amp { NumberAnimation { duration: Theme.normal } }
            onFracChanged: requestPaint()
            onAmpChanged: requestPaint()
            onFillColourChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const mid = height / 2, x = width * frac;
                ctx.lineCap = "round";
                ctx.lineWidth = 4;
                ctx.strokeStyle = fillColour;
                ctx.beginPath();
                for (let i = 2; i <= Math.max(2, x - 6); i += 2)
                    ctx.lineTo(i, mid + Math.sin(i / 7) * amp);
                ctx.stroke();
                ctx.strokeStyle = restColour;
                ctx.beginPath();
                ctx.moveTo(Math.min(width - 2, x + 8), mid);
                ctx.lineTo(width - 2, mid);
                ctx.stroke();
                ctx.fillStyle = fillColour;
                ctx.fillRect(x - 2, mid - 9, 4, 18);
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: e => Media.seek(e.x / width)
        }
    }
    Row {
        anchors { left: bar.left; right: bar.right; top: bar.bottom; topMargin: 2 }
        Txt { width: parent.width / 2; text: Media.time(Media.position); size: 11; color: Theme.inkDim; font.features: { "tnum": 1 } }
        Txt {
            width: parent.width / 2; horizontalAlignment: Text.AlignRight
            text: Media.length > 0 ? Media.time(Media.length) : ""
            size: 11; color: Theme.inkDim; font.features: { "tnum": 1 }
        }
    }

    Row {
        anchors { horizontalCenter: bar.horizontalCenter; bottom: cover.bottom }
        spacing: 14
        IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "skip_previous"; size: 40; onClicked: Media.prev() }
        // play/pause: a squircle that rounds off while playing
        Rectangle {
            width: 64; height: 48
            radius: Media.playing ? 24 : 16
            color: Theme.primary
            Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
            Icon { anchors.centerIn: parent; name: Media.playing ? "pause" : "play_arrow"; size: 28; fill: 1; color: Theme.inkPrimary }
            StateLayer { tint: Theme.inkPrimary; onClicked: Media.toggle() }
        }
        IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "skip_next"; size: 40; onClicked: Media.next() }
    }
}
