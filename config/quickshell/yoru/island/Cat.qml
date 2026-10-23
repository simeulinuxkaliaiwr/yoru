import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Shapes
import qs
import qs.parts

// a cat that lives on the island (island.pet). It sleeps, breathing, the odd z rising;
// a notification or the pointer wakes it a moment; it bobs its head to the music; while
// you focus it curls up and keeps still; a click and it purrs. It moves in small steps
// on timers, not every frame: the island stays still most of the time
Item {
    id: cat
    width: 30; height: 26

    readonly property bool focusing: Focus.phase === "focus"
    readonly property bool dancing: Media.playing && !focusing
    property bool woken: false          // a notification, the pointer: a moment awake
    property bool purring: false
    readonly property bool awake: woken || purring || hover.hovered || (dancing && !focusing)
    readonly property color fur: Theme.primary
    readonly property color dark: Theme.island

    Timer { id: sleepAgain; interval: 6000; onTriggered: cat.woken = false }
    function wake() { woken = true; sleepAgain.restart(); }
    Connections { target: Notifs; function onArrived() { cat.wake(); } }

    // breathing, asleep: a slow rise and fall in two steps
    property bool inhale: false
    Timer { interval: 1700; repeat: true; running: !cat.awake; onTriggered: cat.inhale = !cat.inhale }

    // the head to the music: the output's peaks, a few times a second
    property real bob: 0
    PwNodePeakMonitor { id: peaks; node: Pipewire.defaultAudioSink; enabled: cat.dancing && cat.visible }
    Timer {
        interval: 140; repeat: true; running: cat.dancing && cat.visible
        onTriggered: cat.bob = Math.min(1, peaks.peak * 1.6)
        onRunningChanged: if (!running) cat.bob = 0
    }

    // a z now and then, asleep (not while focusing: it's thinking)
    Timer { interval: 3800; repeat: true; running: !cat.awake && !cat.focusing && cat.visible; onTriggered: zz.restart() }
    Txt {
        id: zed
        x: 23; y: 2
        text: "z"; size: 8; weight: Font.Bold
        color: Theme.inkDim
        opacity: 0
    }
    ParallelAnimation {
        id: zz
        NumberAnimation { target: zed; property: "y"; from: 4; to: -6; duration: 1600; easing.type: Easing.OutQuad }
        SequentialAnimation {
            NumberAnimation { target: zed; property: "opacity"; from: 0; to: 0.9; duration: 300 }
            NumberAnimation { target: zed; property: "opacity"; to: 0; duration: 1300 }
        }
    }

    // a purr: a heart floats up, eyes happy
    Icon {
        id: heart
        x: 9; y: -2
        name: "favorite"; fill: 1; size: 9
        color: Qt.tint(Theme.danger, Theme.alpha(Theme.primary, 0.25))
        opacity: 0
    }
    ParallelAnimation {
        id: love
        NumberAnimation { target: heart; property: "y"; from: 2; to: -10; duration: 1200; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: heart; property: "opacity"; from: 0; to: 1; duration: 200 }
            PauseAnimation { duration: 500 }
            NumberAnimation { target: heart; property: "opacity"; to: 0; duration: 500 }
        }
    }
    Timer { id: purrEnd; interval: 2200; onTriggered: cat.purring = false }

    // the tail, behind: wrapped round asleep, up and swaying awake
    Item {
        id: tailBox
        x: 19; y: 9; width: 12; height: 16
        transformOrigin: Item.BottomLeft
        rotation: cat.awake ? (cat.dancing ? -10 + cat.bob * 22 : tailFlick ? 8 : -6) : 0
        property bool tailFlick: false
        Timer { interval: 900; repeat: true; running: cat.awake && !cat.dancing; onTriggered: tailBox.tailFlick = !tailBox.tailFlick }
        Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: cat.fur; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                startX: 1; startY: 14
                PathQuad { x: cat.awake ? 9 : 10; y: cat.awake ? 3 : 13; controlX: cat.awake ? 11 : 9; controlY: cat.awake ? 12 : 16 }
            }
        }
    }

    // the body: a loaf, rising and falling as it breathes
    Rectangle {
        id: body
        x: 3; y: 12; width: 21; height: 13
        radius: 6.5
        color: cat.fur
        transform: Scale { origin.y: body.height; yScale: cat.inhale && !cat.awake ? 1.07 : 1; Behavior on yScale { NumberAnimation { duration: 900; easing.type: Easing.InOutSine } } }
        // front paws, awake
        Rectangle { visible: cat.awake; x: 5; y: parent.height - 3; width: 4; height: 3; radius: 1.5; color: Qt.lighter(cat.fur, 1.15) }
        Rectangle { visible: cat.awake; x: 12; y: parent.height - 3; width: 4; height: 3; radius: 1.5; color: Qt.lighter(cat.fur, 1.15) }
    }

    // the head: dropped asleep, up awake, bobbing to the music
    Item {
        id: head
        x: 5; width: 17; height: 15
        y: (cat.awake ? 0 : 4) + cat.bob * 2
        rotation: cat.dancing ? (cat.bob > 0.45 ? 7 : -4) : 0
        Behavior on y { NumberAnimation { duration: cat.dancing ? 110 : 420; easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: 140 } }
        // ears: perked awake, flat asleep
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: cat.fur; strokeWidth: 0; strokeColor: "transparent"
                startX: 1.5; startY: 7
                PathLine { x: cat.awake ? 2.5 : 1; y: cat.awake ? -1 : 2 }
                PathLine { x: 7; y: 3.5 }
            }
            ShapePath {
                fillColor: cat.fur; strokeWidth: 0; strokeColor: "transparent"
                startX: 10; startY: 3.5
                PathLine { x: cat.awake ? 14.5 : 16; y: cat.awake ? -1 : 2 }
                PathLine { x: 15.5; y: 7 }
            }
        }
        Rectangle { x: 0; y: 2; width: 17; height: 13; radius: 6.5; color: cat.fur }
        // eyes: shut asleep, open awake, happy arcs purring
        Item {
            x: 3.5; y: 6.5; width: 10; height: 4
            Rectangle { visible: cat.awake && !cat.purring; x: 0; width: 2.4; height: 2.8; radius: 1.2; color: cat.dark }
            Rectangle { visible: cat.awake && !cat.purring; x: 7.2; width: 2.4; height: 2.8; radius: 1.2; color: cat.dark }
            Shape {
                visible: !cat.awake || cat.purring
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                // asleep the arcs hang down; purring they smile up
                ShapePath {
                    strokeColor: cat.dark; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    startX: 0; startY: cat.purring ? 2.4 : 1
                    PathQuad { x: 2.6; y: cat.purring ? 2.4 : 1; controlX: 1.3; controlY: cat.purring ? -0.2 : 2.8 }
                }
                ShapePath {
                    strokeColor: cat.dark; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    startX: 7.1; startY: cat.purring ? 2.4 : 1
                    PathQuad { x: 9.7; y: cat.purring ? 2.4 : 1; controlX: 8.4; controlY: cat.purring ? -0.2 : 2.8 }
                }
            }
        }
        // a nose
        Rectangle { x: 7.5; y: 10; width: 2; height: 1.4; radius: 0.7; color: Qt.darker(cat.fur, 1.5) }
    }

    HoverHandler { id: hover; onHoveredChanged: if (hovered) cat.wake() }
    TapHandler {
        onTapped: {
            cat.purring = true;
            purrEnd.restart();
            love.restart();
        }
    }
}
