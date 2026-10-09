import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs
import qs.parts
import qs.island

// The island: one dark shape at the top of the screen that is the whole
// shell. At rest it shows the workspaces, the time and the status; it grows
// into the launcher, the control centre, the player, the clipboard, the
// wallpaper picker or the power menu, and a notification or a volume change
// pushes it open for a moment. Every change is the same shape morphing.
Scope {
    id: island

    property string mode: "idle"        // what it is opened into
    property string output: ""          // the screen it is opened on
    property string flash: ""           // a passing state: "osd" or "toast"
    property string osdKind: "volume"
    property var toast: null
    property var queue: []

    readonly property var modal: ["launcher", "clip", "control", "calendar", "walls", "power", "media"]
    readonly property bool opened: modal.includes(mode)

    function open(m, out) {
        out = out || Aro.focusedOutput || Quickshell.screens[0]?.name;
        if (mode === m && output === out) { close(); return; }
        output = out;
        mode = m;
    }
    function close() { mode = "idle"; }

    // ── passing states ──────────────────────────────────────────────
    function showOsd(kind) {
        if (opened && (mode === "control" || mode === "launcher" || mode === "clip" || mode === "walls")) return;
        osdKind = kind;
        if (flash !== "toast") flash = "osd";
        osdTimer.restart();
    }
    Timer { id: osdTimer; interval: 1600; onTriggered: if (island.flash === "osd") island.flash = "" }

    function showToast(t) {
        if (flash === "toast") { queue = queue.concat([t]); return; }
        toast = t;
        flash = "toast";
        toastTimer.restart();
    }
    function dropToast() {
        if (queue.length > 0) {
            toast = queue[0];
            queue = queue.slice(1);
            toastTimer.restart();
        } else {
            flash = "";
        }
    }
    Timer {
        id: toastTimer
        interval: island.toast?.notif?.urgency === 2 ? 12000 : 5500
        onTriggered: {
            if (island.hoverToast) restart();
            else island.dropToast();
        }
    }
    property bool hoverToast: false

    // volume changes from anywhere (keys, pavucontrol, a script) show the OSD
    property bool audioSettled: false
    Timer { interval: 1500; running: true; onTriggered: island.audioSettled = true }
    Connections {
        target: Audio
        function onVolumeChanged() { if (island.audioSettled) island.showOsd("volume"); }
        function onMutedChanged() { if (island.audioSettled) island.showOsd("volume"); }
    }
    Connections {
        target: Notifs
        function onArrived(n) { island.showToast({ notif: n }); }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData
            readonly property string name: modelData.name
            readonly property bool here: island.output === name || (island.output === "" && Quickshell.screens[0] === modelData)
            readonly property bool openHere: island.opened && here
            readonly property bool hideIdle: Aro.fullscreen(name)
            // what this screen's island shows right now
            readonly property string shown: openHere ? island.mode
                : island.flash !== "" && here ? island.flash
                : "idle"

            // clicks outside the open island close it
            LazyLoader {
                active: perScreen.openHere
                PanelWindow {
                    screen: perScreen.modelData
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "yoru-scrim"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onClicked: island.close()
                    }
                }
            }

            PanelWindow {
                id: win
                screen: perScreen.modelData
                anchors { top: true; left: true; right: true }
                implicitHeight: 720
                color: "transparent"
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 46
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "yoru-island"
                WlrLayershell.keyboardFocus: perScreen.openHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                mask: Region { item: shape }

                readonly property var views: ({
                    idle: idleView, osd: osdView, toast: toastView, media: mediaView, launcher: launcherView,
                    clip: clipView, control: controlView, calendar: calendarView, walls: wallsView, power: powerView
                })
                readonly property Item current: views[perScreen.shown] ?? idleView
                readonly property bool round: perScreen.shown === "idle" || perScreen.shown === "osd"
                readonly property bool gone: perScreen.shown === "idle" && perScreen.hideIdle

                RectangularShadow {
                    anchors.fill: shape
                    radius: shape.radius
                    blur: win.round ? 18 : 42
                    spread: 0
                    offset: Qt.vector2d(0, win.round ? 3 : 12)
                    color: Qt.rgba(0, 0, 0, win.round ? 0.4 : 0.55)
                    opacity: shape.opacity
                    Behavior on blur { NumberAnimation { duration: Theme.slow } }
                }

                Rectangle {
                    id: shape
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: win.gone ? -height - 24 : 6
                    width: win.current.implicitWidth
                    height: win.current.implicitHeight
                    radius: win.round ? height / 2 : 30
                    color: Theme.island
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.45)
                    clip: true
                    opacity: win.gone ? 0 : 1

                    Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Behavior on height { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                    Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }

                    // a view fades and settles in once the shape has room for it;
                    // the one leaving goes quickly
                    component Face: Item {
                        id: face
                        property string name
                        readonly property bool on: perScreen.shown === name
                        default property alias content: holder.data
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: holder.childrenRect.width
                        height: holder.childrenRect.height
                        opacity: on ? 1 : 0
                        visible: opacity > 0.01
                        scale: on ? 1 : 0.94
                        transformOrigin: Item.Top
                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: face.on ? 90 : 0 }
                                NumberAnimation { duration: face.on ? 260 : 110; easing.type: Easing.OutCubic }
                            }
                        }
                        Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                        Item { id: holder; width: childrenRect.width; height: childrenRect.height }
                    }

                    Face { name: "idle"; IdleView { id: idleView; isle: island; output: perScreen.name } }
                    Face { name: "osd"; OsdView { id: osdView; isle: island } }
                    Face {
                        name: "toast"
                        ToastView {
                            id: toastView; isle: island
                            onHoveredChanged: island.hoverToast = hovered
                        }
                    }
                    Face { name: "media"; MediaView { id: mediaView; isle: island } }
                    Face { name: "launcher"; LauncherView { id: launcherView; isle: island } }
                    Face { name: "clip"; ClipView { id: clipView; isle: island } }
                    Face { name: "control"; ControlView { id: controlView; isle: island } }
                    Face { name: "calendar"; CalendarView { id: calendarView; isle: island } }
                    Face { name: "walls"; WallsView { id: wallsView; isle: island; screen: perScreen.modelData } }
                    Face { name: "power"; PowerView { id: powerView; isle: island } }
                }

                // Escape closes whatever is open, even views without a text field
                Item {
                    id: keys
                    Keys.onEscapePressed: island.close()
                }
                Connections {
                    target: perScreen
                    function onOpenHereChanged() {
                        if (!perScreen.openHere) return;
                        if (island.mode === "calendar") calendarView.forceActiveFocus();
                        else if (["media", "control"].includes(island.mode)) keys.forceActiveFocus();
                    }
                }
            }
        }
    }
}
