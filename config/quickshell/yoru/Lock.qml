import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.parts
import qs.desktop

// yoru's lock screen (ext-session-lock): the wallpaper, blurred, with a clock,
// a password pill and the music. If this shell dies while locked, aro keeps
// the session locked and lets another locker take over: from a TTY,
// `WAYLAND_DISPLAY=wayland-0 aro-lock` unlocks with your password as usual.
Scope {
    id: root

    property string pw: ""
    property bool checking: false
    property bool failed: false
    property bool leaving: false        // the unlock animation is playing
    property int fails: 0
    readonly property bool locked: lock.locked
    signal shake()

    function lockNow() {
        if (lock.locked) return;
        findFace.running = true;
        pw = ""; failed = false; checking = false; leaving = false;
        lock.locked = true;
    }
    function submit() {
        if (pw === "" || checking) return;
        checking = true;
        failed = false;
        pam.start();
    }

    PamContext {
        id: pam
        config: "swaylock"              // `auth include login`, the same as swaylock
        onResponseRequiredChanged: if (responseRequired) respond(root.pw)
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.leaving = true;
                away.start();
            } else {
                root.failed = true;
                root.fails++;
                root.pw = "";
                root.shake();
            }
        }
        onError: root.checking = false
    }
    Timer { id: away; interval: 520; onTriggered: { lock.locked = false; root.leaving = false; root.pw = ""; } }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // your picture: ~/.face, else ~/.face.icon, else the one AccountsService keeps
    // (what display managers and GNOME set). Looked for at each lock; the file's
    // mtime in the URL makes a replaced picture a new image (Qt caches by URL)
    property string face: ""
    Process {
        id: findFace
        command: ["sh", "-c", "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do [ -s \"$f\" ] && { echo \"file://$f?$(stat -c %Y \"$f\")\"; break; }; done"]
        stdout: StdioCollector { onStreamFinished: root.face = text.trim() }
    }
    Component.onCompleted: findFace.running = true

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            id: surf
            color: "black"

            // the wallpaper, blurred and dimmed
            Image {
                id: wall
                anchors.fill: parent
                source: Theme.still ? "file://" + Theme.still : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width / 2, height / 2)   // blurred anyway
                visible: false
            }
            MultiEffect {
                id: blurred
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blurMax: 64
                blur: shown ? Config.o.lock.blur : 0
                brightness: shown ? -Config.o.lock.dim : 0
                saturation: 0.1
                property bool shown: lock.locked && !root.leaving
                Behavior on blur { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                Behavior on brightness { NumberAnimation { duration: 700 } }
            }

            Item {
                id: face
                anchors.fill: parent
                readonly property bool on: lock.locked && !root.leaving
                opacity: on ? 1 : 0
                scale: on ? 1 : 1.06
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

                // status, top right
                Row {
                    anchors { top: parent.top; right: parent.right; margins: 28 }
                    spacing: 14
                    Icon { name: Status.netIcon; size: 20; fill: 1; color: Theme.ink }
                    Row {
                        visible: Status.hasBattery
                        spacing: 4
                        Icon { name: Status.batteryIcon; size: 20; fill: 1; rotation: 90; color: Theme.ink }
                        Txt { text: Math.round(Status.charge * 100) + "%"; size: 14; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // the clock
                Column {
                    id: time
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.14 }
                    spacing: 0
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.6); shadowBlur: 0.9; shadowVerticalOffset: 2 }
                    ClockFace { style: Config.o.lock.clockStyle; centred: true; k: 1.05; anchors.horizontalCenter: parent.horizontalCenter }
                }

                // who, and the password
                Column {
                    id: who
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.2 }
                    spacing: 16
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.6); shadowBlur: 0.9; shadowVerticalOffset: 2 }

                    ClippingRectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 88; height: 88; radius: Theme.r(44)
                        color: Theme.primaryContainer
                        Txt {
                            anchors.centerIn: parent
                            visible: avatar.status !== Image.Ready
                            text: (Quickshell.env("USER") || "?")[0].toUpperCase()
                            size: 38; weight: Font.DemiBold; color: Theme.inkPrimaryContainer
                        }
                        Image {
                            id: avatar
                            anchors.fill: parent
                            source: root.face
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(176, 176)
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.failed ? (root.fails > 2 ? "Still not it — caps lock?" : "That's not it")
                            : root.checking ? "Checking…" : "Welcome back, " + Quickshell.env("USER")
                        size: 15; weight: Font.Medium
                        color: root.failed ? Theme.danger : Theme.ink
                    }

                    Rectangle {
                        id: pill
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 340; height: 54; radius: Theme.r(27)
                        color: Theme.alpha(Theme.surfaceLowest, 0.6)
                        border.width: input.activeFocus ? 2 : 1
                        border.color: root.failed ? Theme.danger : root.checking ? Theme.tertiary : Theme.alpha(Theme.primary, 0.7)
                        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                        TextInput {
                            id: input
                            anchors.fill: parent
                            opacity: 0
                            echoMode: TextInput.Password
                            focus: true
                            enabled: !root.checking
                            Component.onCompleted: forceActiveFocus()
                            onTextChanged: root.pw = text
                            Keys.onReturnPressed: root.submit()
                            Keys.onEnterPressed: root.submit()
                            Keys.onEscapePressed: text = ""
                            Connections {
                                target: root
                                function onPwChanged() { if (root.pw === "" && input.text !== "") input.text = ""; }
                            }
                        }
                        // a mark per character, popping in: dots, or Material shapes in
                        // turn (after end-4's lock) that arrive in the accent and settle to ink
                        Row {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -14
                            spacing: Config.o.lock.chars === "shapes" ? 4 : 8
                            readonly property var kinds: ["clover", "arrow", "pill", "burst", "diamond", "scallop", "pentagon"]
                            Repeater {
                                model: Math.min(root.pw.length, Config.o.lock.chars === "shapes" ? 13 : 18)
                                Item {
                                    id: mark
                                    required property int index
                                    readonly property bool shaped: Config.o.lock.chars === "shapes"
                                    width: shaped ? 18 : 10; height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    scale: 0.4; opacity: 0
                                    property color tint: shaped ? Theme.primary : Theme.ink
                                    Component.onCompleted: { scale = 1; opacity = 1; tint = Theme.ink; }
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                                    Behavior on opacity { NumberAnimation { duration: 80 } }
                                    Behavior on tint { ColorAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                                    Rectangle {
                                        visible: !mark.shaped
                                        anchors.centerIn: parent
                                        width: 10; height: 10; radius: Theme.r(5)
                                        color: mark.tint
                                    }
                                    Blob {
                                        visible: mark.shaped
                                        anchors.centerIn: parent
                                        size: 18
                                        kind: parent.parent.kinds[mark.index % 7]
                                        color: mark.tint
                                    }
                                }
                            }
                        }
                        Txt {
                            anchors.centerIn: parent
                            visible: root.pw === ""
                            text: "Password"
                            size: 15; color: Theme.outline
                        }
                        Rectangle {
                            anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                            width: 40; height: 40; radius: root.checking ? 12 : 20
                            color: root.pw !== "" ? Theme.primary : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                            Behavior on radius { NumberAnimation { duration: Theme.normal } }
                            rotation: root.checking ? 360 : 0
                            RotationAnimation on rotation {
                                running: root.checking; loops: Animation.Infinite
                                from: 0; to: 360; duration: 900
                            }
                            Icon {
                                anchors.centerIn: parent
                                name: root.checking ? "progress_activity" : "arrow_forward"
                                size: 22
                                color: root.pw !== "" ? Theme.inkPrimary : Theme.outline
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
                        }

                        // a wrong password shakes the pill, like a head saying no
                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -18; duration: 50 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 16; duration: 70 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -12; duration: 70 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 8; duration: 70 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 90; easing.type: Easing.OutCubic }
                        }
                        Connections { target: root; function onShake() { shakeAnim.restart(); } }
                    }
                }

                // the focus timer, while it runs
                Rectangle {
                    visible: Focus.active
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Config.o.lock.media && Media.title !== "" ? 120 : 36 }
                    width: focusRow.implicitWidth + 36; height: 40; radius: Theme.r(20)
                    color: Theme.alpha(Theme.surfaceLowest, 0.55)
                    Row {
                        id: focusRow
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: Focus.phase === "break" ? "self_improvement" : "timer"; size: 18
                            color: Focus.phase === "break" ? Theme.tertiary : Theme.primary
                        }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (Focus.phase === "break" ? "Break  " : "Focus  ") + Focus.clock(Focus.left)
                            size: 13; weight: Font.DemiBold
                        }
                    }
                }

                // the music
                Rectangle {
                    visible: Config.o.lock.media && Media.title !== ""
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
                    width: 380; height: 72; radius: Theme.r(26)
                    color: Theme.alpha(Theme.surfaceLowest, 0.55)
                    ClippingRectangle {
                        id: art
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        width: 48; height: 48; radius: Theme.r(14)
                        color: Theme.surfaceHigh
                        Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96); asynchronous: true }
                    }
                    Column {
                        anchors { left: art.right; leftMargin: 12; right: ctl.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        Txt { width: parent.width; text: Media.title; size: 14; weight: Font.DemiBold }
                        Txt { width: parent.width; text: Media.artist; size: 12; color: Theme.inkDim }
                    }
                    Row {
                        id: ctl
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        IconButton { icon: "skip_previous"; size: 36; onClicked: Media.prev() }
                        IconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 40; active: true; onClicked: Media.toggle() }
                        IconButton { icon: "skip_next"; size: 36; onClicked: Media.next() }
                    }
                }

                // power
                Row {
                    visible: Config.o.lock.power
                    anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
                    spacing: 10
                    IconButton { icon: "bedtime"; filled: true; size: 44; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
                    IconButton { icon: "restart_alt"; filled: true; size: 44; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                    IconButton { icon: "power_settings_new"; filled: true; size: 44; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }
        }
    }
}
