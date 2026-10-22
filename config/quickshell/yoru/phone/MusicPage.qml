import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// the music: the cover, large, glowing in its own colours; a line that waves while it plays
// (click it to seek); the controls, with shuffle and repeat when the player has them; and the
// words a line at a time, when lrclib knows them. Nothing playing: your music apps.
// Keys: Space or Enter plays and pauses, [ and ] skip
Item {
    id: mp
    required property var phone
    property bool live: false
    property bool compact: false
    readonly property int pad: compact ? 14 : 24
    readonly property var player: Media.player
    readonly property real frac: Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0

    // the words are only fetched while something shows them
    readonly property bool singing: live && phone.c.lyrics && !!player
    property bool counted: false
    function count(on) {
        if (on === counted) return;
        Lyrics.users += on ? 1 : -1;
        counted = on;
    }
    onSingingChanged: count(singing)
    Component.onCompleted: count(singing)
    Component.onDestruction: count(false)

    function key(e) {
        if (!player) return false;
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { Media.toggle(); return true; }
        if (e.key === Qt.Key_BracketLeft) { Media.prev(); return true; }
        if (e.key === Qt.Key_BracketRight) { Media.next(); return true; }
        return false;
    }

    // the cover again, blurred, as light behind everything
    Image {
        id: glowSrc
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(96, 96)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: glowSrc
        visible: !!mp.player && glowSrc.status === Image.Ready
        blurEnabled: true; blur: 1; blurMax: 64
        saturation: 0.25
        opacity: 0.4
    }

    Column {
        id: col
        visible: !!mp.player
        x: mp.pad
        y: mp.compact ? 6 : 14
        width: parent.width - 2 * mp.pad
        spacing: mp.compact ? 6 : 12

        ClippingRectangle {
            id: cover
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real side: Math.min(col.width, mp.height * (mp.compact ? 0.4 : 0.44))
            width: side; height: side
            radius: Theme.r(mp.compact ? 18 : 30)
            color: Theme.surfaceHigh
            // no cover: your colours, and a record
            Rectangle {
                anchors.fill: parent
                visible: art.status !== Image.Ready
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.primaryContainer }
                    GradientStop { position: 1; color: Theme.tertiaryContainer }
                }
            }
            Image {
                id: art
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(cover.side * 2, cover.side * 2)
                asynchronous: true
            }
            Icon { anchors.centerIn: parent; visible: art.status !== Image.Ready; name: "album"; size: cover.side * 0.36; color: Theme.inkPrimaryContainer; opacity: 0.8 }
            // a little bounce when the track changes
            Connections {
                target: Media
                function onTitleChanged() { bump.restart(); }
            }
            SequentialAnimation on scale {
                id: bump; running: false
                NumberAnimation { to: 0.92; duration: 120; easing.type: Easing.OutQuad }
                NumberAnimation { to: 1; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatialSlow }
            }
        }

        Column {
            width: parent.width
            topPadding: mp.compact ? 0 : 4
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Media.title || "Untitled"
                size: mp.compact ? 15 : 19; weight: Font.DemiBold
            }
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Media.artist + (mp.player?.identity && mp.player.identity !== Media.artist ? "  ·  " + mp.player.identity : "")
                size: mp.compact ? 11 : 13; color: Theme.inkDim
            }
        }

        // where it is: a wave while playing, a straight line while paused
        Item {
            width: parent.width
            height: 18
            Canvas {
                id: wave
                anchors.fill: parent
                property real frac: mp.frac
                property real amp: Media.playing ? 2.6 : 0
                property color fillColour: Theme.primary
                property color restColour: Theme.alpha(Theme.ink, 0.22)
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
                    ctx.lineWidth = 3.5;
                    ctx.strokeStyle = fillColour;
                    ctx.beginPath();
                    for (let i = 2; i <= Math.max(2, x - 6); i += 2)
                        ctx.lineTo(i, mid + Math.sin(i / 6) * amp);
                    ctx.stroke();
                    ctx.strokeStyle = restColour;
                    ctx.beginPath();
                    ctx.moveTo(Math.min(width - 2, x + 7), mid);
                    ctx.lineTo(width - 2, mid);
                    ctx.stroke();
                    ctx.fillStyle = fillColour;
                    ctx.fillRect(x - 2, mid - 8, 4, 16);
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: mp.player?.canSeek ?? false
                cursorShape: Qt.PointingHandCursor
                onClicked: e => Media.seek(e.x / width)
            }
        }
        Item {
            width: parent.width
            height: 12
            Txt { text: Media.time(Media.position); size: 10; color: Theme.inkDim; font.features: { "tnum": 1 } }
            Txt { anchors.right: parent.right; text: Media.length > 0 ? Media.time(Media.length) : ""; size: 10; color: Theme.inkDim; font.features: { "tnum": 1 } }
        }

        // the controls
        Item {
            width: parent.width
            height: mp.compact ? 44 : 60
            IconButton {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                visible: mp.player?.shuffleSupported ?? false
                size: mp.compact ? 30 : 36; icon: "shuffle"
                active: mp.player?.shuffle ?? false
                onClicked: mp.player.shuffle = !mp.player.shuffle
            }
            Row {
                anchors.centerIn: parent
                spacing: mp.compact ? 8 : 14
                IconButton { anchors.verticalCenter: parent.verticalCenter; size: mp.compact ? 34 : 42; icon: "skip_previous"; onClicked: Media.prev() }
                // play and pause: a squircle that rounds off while it plays
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: mp.compact ? 54 : 70; height: mp.compact ? 42 : 54
                    radius: Theme.r(Media.playing ? height / 2 : height * 0.32)
                    color: Theme.primary
                    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Icon { anchors.centerIn: parent; name: Media.playing ? "pause" : "play_arrow"; size: mp.compact ? 24 : 30; fill: 1; color: Theme.inkPrimary }
                    StateLayer { tint: Theme.inkPrimary; onClicked: Media.toggle() }
                }
                IconButton { anchors.verticalCenter: parent.verticalCenter; size: mp.compact ? 34 : 42; icon: "skip_next"; onClicked: Media.next() }
            }
            IconButton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: mp.player?.loopSupported ?? false
                size: mp.compact ? 30 : 36
                icon: mp.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                active: (mp.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                // off, then the list, then this one
                onClicked: mp.player.loopState = mp.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                               : mp.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
    }

    // the words: the line being sung, the ones either side quieter
    Item {
        id: words
        visible: !!mp.player && mp.phone.c.lyrics
        anchors { left: parent.left; right: parent.right; top: col.bottom; bottom: parent.bottom; leftMargin: mp.pad; rightMargin: mp.pad; topMargin: mp.compact ? 4 : 10; bottomMargin: 4 }
        clip: true
        readonly property var lines: Lyrics.lines
        readonly property int at: Lyrics.index
        function line(i) { return i >= 0 && i < lines.length ? (lines[i][1] || "♪") : ""; }
        property real lift: 0
        onAtChanged: { lift = 12; settle.restart(); }
        NumberAnimation { id: settle; target: words; property: "lift"; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }
        Column {
            visible: Lyrics.status === "ok"
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: words.lift
            spacing: mp.compact ? 2 : 6
            Txt {
                width: parent.width; visible: !mp.compact
                horizontalAlignment: Text.AlignHCenter
                text: words.line(words.at - 1)
                size: 12; color: Theme.inkDim; opacity: 0.55
            }
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: words.at < 0 ? "♪" : words.line(words.at)
                size: mp.compact ? 13 : 16; weight: Font.DemiBold
                color: Theme.ink
                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
            }
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: words.line(words.at + 1)
                size: 12; color: Theme.inkDim; opacity: 0.75
            }
        }
        Txt {
            anchors.centerIn: parent
            visible: Lyrics.status === "loading"
            text: "Looking for the words…"
            size: 11; color: Theme.outline
        }
    }

    // nothing playing: the apps that would
    Column {
        visible: !mp.player
        anchors.centerIn: parent
        width: parent.width - 2 * mp.pad
        spacing: 10
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: mp.compact ? 64 : 96; height: width
            radius: Theme.r(width * 0.32)
            color: Theme.alpha(Theme.surfaceHigh, 0.72)
            Icon { anchors.centerIn: parent; name: "music_note"; size: parent.width * 0.44; color: Theme.inkDim }
        }
        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing playing"; size: mp.compact ? 14 : 16; weight: Font.DemiBold }
        Txt {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: players.count > 0 ? "Start something" : "Play something, and it shows here"
            size: 12; color: Theme.inkDim
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                id: players
                // players, not mixers: Music or Player among their categories
                model: Apps.entries.filter(e => (e.categories ?? []).some(c => c === "Music" || c === "Player"))
                                   .sort((a, b) => (Apps.counts[b.id] ?? 0) - (Apps.counts[a.id] ?? 0)).slice(0, 4)
                AppCell {
                    width: mp.compact ? 54 : 66; height: width
                    docked: true
                    labels: false
                    onOpened: { Apps.launch(modelData); mp.phone.close(); }
                }
            }
        }
    }
}
