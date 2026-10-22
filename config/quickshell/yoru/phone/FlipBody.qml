import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.parts
import "actions.js" as Actions

// the flip: a folding keitai. It arrives shut, the little screen on its lid showing the time,
// and swings open on its hinge; the keypad lights up as it does. The keys work: the soft keys
// walk the pages, the ring moves and its middle picks, the green key goes home and the red one
// shuts it; 1–9 are shortcuts (the settings say which), * mutes, 0 goes home, # locks. Keys
// typed on the keyboard press them too
Item {
    id: body
    property var phone: null                // null in the settings' preview: nothing to press
    property Component screen: null
    property real t: 1                      // 0 gone … 1 open
    readonly property Item display: glass.item
    implicitWidth: 336
    implicitHeight: 846
    readonly property real half: 420
    readonly property real axis: half + 3   // the hinge, from the top
    readonly property real outer: Theme.r(46)
    // shut, it's the keypad's size: that's where the island lands
    readonly property var landing: ({ x: 0, y: base.y, w: width, h: base.height, r: outer })

    // it arrives shut and opens after: it takes longer than the others
    readonly property real span: 1.45
    function clamp01(x) { return Math.max(0, Math.min(1, x)); }
    function backOut(x) { const s = 1.4, c = s + 1; return 1 + c * Math.pow(x - 1, 3) + s * Math.pow(x - 1, 2); }
    // the lid: 180° shut over the keypad, 0 open. It gathers speed, swings a little past, and
    // settles back (eased in first: on its own, back-out does most of the swing at once)
    readonly property real angle: 180 * (1 - backOut(Math.pow(clamp01((t - 0.56) / 0.44), 1.6)))
    readonly property bool facing: angle < 90
    readonly property real power: clamp01((t - 0.8) / 0.2)

    // the keypad's light: on as it opens and while you press, dim after a while
    property real lit: 0
    Behavior on lit { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    function wake() { lit = 1; dimmer.restart(); }
    Timer { id: dimmer; interval: 6000; onTriggered: body.lit = 0.3 }
    onPowerChanged: if (power >= 1) wake(); else if (power <= 0) lit = 0

    // a key held down for a moment, pressed here or on the keyboard
    property string down: ""
    function press(name) { down = name; release.restart(); wake(); }
    Timer { id: release; interval: 150; onTriggered: body.down = "" }
    Connections {
        target: body.phone
        ignoreUnknownSignals: true
        function onKeyed(name) { body.press(name); }
    }

    // what each key does when it's clicked
    function hit(name) {
        if (!phone) return;
        press(name);
        const d = display;
        switch (name) {
        case "softL": if (d && !d.back()) d.step(-1); break;
        case "softR": d?.step(1); break;
        case "call": phone.panel = ""; phone.page = phone.pages[0]; break;
        case "end": phone.close(); break;
        case "up": d?.press(Qt.Key_Up); break;
        case "down": d?.press(Qt.Key_Down); break;
        case "left": d?.press(Qt.Key_Left); break;
        case "right": d?.press(Qt.Key_Right); break;
        case "ok": d?.press(Qt.Key_Return); break;
        default: phone.keypad(name);
        }
    }
    readonly property var kana: ({ "1": "あ", "2": "か", "3": "さ", "4": "た", "5": "な", "6": "は", "7": "ま", "8": "や", "9": "ら", "*": "゛゜", "0": "わ", "#": "、。" })
    function does(name) {
        if (/^[1-9]$/.test(name)) return Actions.label(Config.o.phone.keys[+name - 1] ?? "");
        return ({ "*": "Mute", "0": "Home", "#": "Lock", softL: "Back", softR: "Next page", call: "Home", end: "Put it away", ok: "Open" })[name] ?? "";
    }

    // a key on the keypad: it lights with the rest, sinks while it's pressed
    component Key: Item {
        id: k
        property string name
        property string tone: ""            // call (the accent), end (danger)
        default property alias face: inner.data
        readonly property bool pressed: area.pressed || body.down === name
        Rectangle {
            id: cap
            anchors.fill: parent
            anchors.topMargin: k.pressed ? 2 : 0
            radius: Math.min(height / 2, Theme.r(16))
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.mix(Theme.surfaceHigh, Theme.ink, k.pressed ? 0.02 : 0.1) }
                GradientStop { position: 1; color: Theme.mix(Theme.surfaceMid, Theme.surfaceLowest, k.pressed ? 0.4 : 0.15) }
            }
            border.width: 1
            border.color: k.tone === "call" ? Theme.alpha(Theme.primary, 0.35 + 0.35 * body.lit)
                        : k.tone === "end" ? Theme.alpha(Theme.danger, 0.35 + 0.35 * body.lit)
                        : Theme.alpha(Theme.primary, 0.08 + 0.22 * body.lit)
            // the light from under the keys
            Rectangle {
                anchors { fill: parent; margins: 1 }
                radius: parent.radius - 1
                color: Theme.alpha(Theme.primary, 0.07 * body.lit)
            }
            Item { id: inner; anchors.fill: parent }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            enabled: body.phone !== null
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: body.hit(k.name)
            onContainsMouseChanged: if (body.phone) body.phone.hint = containsMouse ? body.does(k.name) : ""
        }
    }
    readonly property color glowInk: Theme.mix(Theme.ink, Theme.primary, 0.7 * lit)

    // the keypad half
    RectangularShadow {
        visible: !Theme.hardShadow
        anchors.fill: base
        radius: body.outer
        blur: 48; spread: 2
        offset: Qt.vector2d(0, 22)
        color: Qt.rgba(0, 0, 0, 0.55)
    }
    Rectangle {
        id: base
        y: body.half + 6
        width: body.width
        height: body.half
        topLeftRadius: Theme.r(14); topRightRadius: Theme.r(14)
        bottomLeftRadius: body.outer; bottomRightRadius: body.outer
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.mix(Theme.island, Theme.ink, 0.1) }
            GradientStop { position: 0.08; color: Theme.mix(Theme.island, Theme.surfaceLow, 0.5) }
            GradientStop { position: 1; color: Theme.mix(Theme.island, Theme.ink, 0.12) }
        }
        border.width: Theme.border > 0 ? Theme.border : 1
        border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.ink, 0.1)

        // soft keys, call and end, round the ring
        Key {
            name: "softL"; x: 22; y: 24; width: 76; height: 30
            Rectangle { anchors.centerIn: parent; width: 22; height: 3; radius: 1.5; color: body.glowInk }
        }
        Key {
            name: "softR"; x: base.width - 98; y: 24; width: 76; height: 30
            Rectangle { anchors.centerIn: parent; width: 22; height: 3; radius: 1.5; color: body.glowInk }
        }
        Key {
            name: "call"; tone: "call"; x: 22; y: 68; width: 76; height: 42
            Icon { anchors.centerIn: parent; name: "call"; size: 20; fill: 1; color: Theme.mix(Theme.primary, Theme.ink, 0.15) }
        }
        Key {
            name: "end"; tone: "end"; x: base.width - 98; y: 68; width: 76; height: 42
            Icon { anchors.centerIn: parent; name: "call_end"; size: 20; fill: 1; color: Theme.danger }
        }
        // the ring: where it's pressed says the way; its middle picks
        Item {
            id: ring
            x: (base.width - width) / 2; y: 20
            width: 116; height: 116
            readonly property string held: ["up", "down", "left", "right"].includes(body.down) ? body.down : pad.pressed ? pad.way : ""
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.mix(Theme.surfaceHigh, Theme.ink, 0.12) }
                    GradientStop { position: 1; color: Theme.mix(Theme.surfaceMid, Theme.surfaceLowest, 0.2) }
                }
                border.width: 1
                border.color: Theme.alpha(Theme.primary, 0.1 + 0.25 * body.lit)
            }
            // the side being pressed sinks
            Item {
                visible: ring.held !== ""
                anchors.fill: parent
                rotation: ({ up: 0, right: 90, down: 180, left: 270 })[ring.held] ?? 0
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    width: 46; height: 26; radius: 13
                    color: Theme.alpha(Theme.surfaceLowest, 0.4)
                }
            }
            Icon { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 } name: "keyboard_arrow_up"; size: 18; color: body.glowInk }
            Icon { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 } name: "keyboard_arrow_down"; size: 18; color: body.glowInk }
            Icon { anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 4 } name: "keyboard_arrow_left"; size: 18; color: body.glowInk }
            Icon { anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 4 } name: "keyboard_arrow_right"; size: 18; color: body.glowInk }
            MouseArea {
                id: pad
                anchors.fill: parent
                enabled: body.phone !== null
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property string way: ""
                function aim(x, y) {
                    const dx = x - width / 2, dy = y - height / 2;
                    way = Math.hypot(dx, dy) < 30 ? "ok" : Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up");
                }
                onPressed: e => aim(e.x, e.y)
                onPositionChanged: e => { aim(e.x, e.y); if (body.phone) body.phone.hint = way === "ok" ? body.does("ok") : ""; }
                onExited: if (body.phone) body.phone.hint = ""
                onClicked: body.hit(way)
            }
            // the middle: pick
            Rectangle {
                anchors.centerIn: parent
                readonly property bool held: body.down === "ok" || (pad.pressed && pad.way === "ok")
                width: 50; height: 50
                radius: 25
                scale: held ? 0.94 : 1
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.mix(Theme.surfaceHighest, Theme.ink, parent.held ? 0.04 : 0.14) }
                    GradientStop { position: 1; color: Theme.mix(Theme.surfaceHigh, Theme.surfaceLowest, 0.2) }
                }
                border.width: 1
                border.color: Theme.alpha(Theme.primary, 0.15 + 0.4 * body.lit)
                Txt { anchors.centerIn: parent; text: "OK"; size: 12; weight: Font.Bold; color: body.glowInk }
            }
        }

        // the numbers
        Grid {
            x: 22; y: 154
            columns: 3
            columnSpacing: (base.width - 44 - 3 * 86) / 2
            rowSpacing: 10
            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
                Key {
                    id: num
                    required property string modelData
                    name: modelData
                    width: 86; height: 46
                    readonly property string act: /^[1-9]$/.test(modelData) ? (Config.o.phone.keys[+modelData - 1] ?? "") : ""
                    Txt {
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1
                        text: num.modelData
                        size: 19; weight: Font.DemiBold
                        color: body.glowInk
                        font.features: { "tnum": 1 }
                    }
                    Txt {
                        x: 33; anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1
                        text: body.kana[num.modelData] ?? ""
                        size: 10
                        font.family: "Noto Sans JP"
                        color: Theme.inkDim
                    }
                    Icon {
                        anchors { right: parent.right; rightMargin: 11; verticalCenter: parent.verticalCenter }
                        visible: name !== ""
                        name: num.act !== "" ? Actions.icon(num.act)
                            : ({ "*": "volume_off", "0": "home", "#": "lock" })[num.modelData] ?? ""
                        size: 15
                        fill: body.lit > 0.6 ? 1 : 0
                        color: Theme.alpha(Theme.primary, 0.45 + 0.55 * body.lit)
                    }
                }
            }
        }
        // the microphone, under the keys
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 22 }
            width: 26; height: 4; radius: 2
            color: Theme.alpha(Theme.surfaceLowest, 0.9)
        }
        // shade from the lid as it comes down
        Rectangle {
            anchors.fill: parent
            radius: body.outer
            color: "black"
            opacity: 0.55 * Math.max(0, Math.min(1, body.angle / 150))
            visible: opacity > 0.01
        }
    }

    // the hinge
    Rectangle {
        x: 24; y: body.half - 8
        width: body.width - 48; height: 26
        radius: 13
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.mix(Theme.island, Theme.ink, 0.05) }
            GradientStop { position: 0.45; color: Theme.mix(Theme.island, Theme.ink, 0.28) }
            GradientStop { position: 1.0; color: Theme.mix(Theme.island, Theme.surfaceLowest, 0.6) }
        }
    }

    // the lid, swinging on the hinge
    Item {
        id: lid
        width: body.width
        height: body.half
        z: 2
        transform: Rotation {
            origin.x: lid.width / 2
            origin.y: body.axis
            axis { x: 1; y: 0; z: 0 }
            angle: -body.angle
        }

        RectangularShadow {
            visible: !Theme.hardShadow && body.facing
            anchors.fill: front
            radius: body.outer
            blur: 48; spread: 2
            offset: Qt.vector2d(0, 18)
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        // inside: the screen
        Rectangle {
            id: front
            visible: body.facing
            anchors.fill: parent
            topLeftRadius: body.outer; topRightRadius: body.outer
            bottomLeftRadius: Theme.r(14); bottomRightRadius: Theme.r(14)
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.mix(Theme.island, Theme.ink, 0.2) }
                GradientStop { position: 0.06; color: Theme.mix(Theme.island, Theme.surfaceLow, 0.4) }
                GradientStop { position: 1; color: Theme.mix(Theme.island, Theme.ink, 0.06) }
            }
            border.width: Theme.border > 0 ? Theme.border : 1
            border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.ink, 0.1)
            // the earpiece
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                width: 58; height: 5; radius: 2.5
                color: Theme.alpha(Theme.surfaceLowest, 0.9)
            }
            ClippingRectangle {
                id: pane
                x: 20; y: 38
                width: parent.width - 40
                height: 356
                radius: Theme.r(16)
                color: "black"
                border.width: 1
                border.color: Theme.alpha(Theme.ink, 0.08)
                contentUnderBorder: true
                Loader {
                    id: glass
                    anchors.fill: parent
                    focus: true
                    sourceComponent: body.screen
                    onLoaded: {
                        if (item.look !== undefined) item.look = "keitai";
                        if (item.power !== undefined) item.power = Qt.binding(() => body.power);
                    }
                }
            }
            Txt {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                text: "Y O R U"
                size: 8; weight: Font.DemiBold
                color: Theme.alpha(Theme.ink, 0.28)
            }
        }

        // outside: glossy, the little screen and the camera
        Item {
            id: back
            visible: !body.facing
            anchors.fill: parent
            // the lid is upside down by now: turn what's on it the right way up
            transform: Scale { origin.y: back.height / 2; yScale: -1 }
            Rectangle {
                anchors.fill: parent
                topLeftRadius: body.outer; topRightRadius: body.outer
                bottomLeftRadius: Theme.r(14); bottomRightRadius: Theme.r(14)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.mix(Theme.island, Theme.primaryContainer, 0.28) }
                    GradientStop { position: 0.5; color: Theme.mix(Theme.island, Theme.primaryContainer, 0.12) }
                    GradientStop { position: 1.0; color: Theme.mix(Theme.island, Theme.ink, 0.1) }
                }
                border.width: Theme.border > 0 ? Theme.border : 1
                border.color: Theme.border > 0 ? Theme.borderColour : Theme.alpha(Theme.ink, 0.12)
            }
            // a shine across the shell
            Rectangle {
                x: 30; y: 22
                width: parent.width * 0.42; height: parent.height - 60
                radius: Theme.r(30)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.alpha(Theme.ink, 0.0) }
                    GradientStop { position: 0.4; color: Theme.alpha(Theme.ink, 0.06) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.ink, 0.0) }
                }
            }
            // the camera
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 32
                width: 26; height: 26; radius: 13
                color: Qt.darker(Theme.island, 1.6)
                border.width: 3
                border.color: Theme.mix(Theme.island, Theme.ink, 0.25)
                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.alpha(Theme.primary, 0.35) }
            }
            // the little screen: the time, and whatever's waiting
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 84
                width: 150; height: 64
                radius: Theme.r(14)
                color: Qt.darker(Theme.island, 1.5)
                border.width: 1
                border.color: Theme.alpha(Theme.primary, 0.25)
                SystemClock { id: clock; precision: SystemClock.Minutes }
                Txt {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
                    text: Qt.formatTime(clock.date, Config.o.island.clock24 ? "HH:mm" : "h:mm")
                    size: 26; weight: Font.Light
                    color: Theme.primary
                    font.features: { "tnum": 1 }
                }
                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                    spacing: 6
                    Txt { text: Qt.formatDate(clock.date, "ddd d"); size: 10; color: Theme.inkDim }
                    Icon { visible: (body.phone?.unseen ?? 0) > 0; name: "mail"; size: 12; fill: 1; color: Theme.tertiary }
                    Icon { visible: body.phone?.playing ?? false; name: "music_note"; size: 12; color: Theme.primary }
                }
            }
            Txt {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
                text: "夜"
                font.family: "Noto Sans JP"
                size: 40
                color: Theme.alpha(Theme.ink, 0.07)
            }
        }
    }
}
