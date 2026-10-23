import Quickshell
import QtQuick
import qs
import qs.parts
import qs.phone
import "../phone/actions.js" as Actions

Column {
    spacing: 14
    readonly property var c: Config.o.phone
    function tryIt() { Quickshell.execDetached(["qs", "-c", "yoru", "ipc", "call", "phone", "toggle"]); }
    readonly property var everything: Actions.order.map(id => ({ value: id, label: Actions.label(id), icon: Actions.icon(id) }))

    Section {
        icon: "smartphone"; title: "The phone"
        Item {
            width: parent.width
            height: Math.max(choices.implicitHeight, preview.height + 20)
            Column {
                id: choices
                width: parent.width - preview.width - 24
                spacing: 2
                SetRow {
                    icon: "style"; label: "Its body"
                    hint: c.skin === "flip" ? "A folding keitai: it opens on its hinge, and its keypad works"
                        : c.skin === "bare" ? "The screen alone, edged like the island"
                        : "A glass smartphone; its side buttons are the volume, and the right one puts it away"
                }
                Choice {
                    x: 10
                    current: c.skin
                    options: [{ value: "slab", label: "Slab", icon: "smartphone" }, { value: "flip", label: "Flip", icon: "dialpad" },
                              { value: "bare", label: "Bare", icon: "crop_portrait" }]
                    onPicked: v => c.skin = v
                }
                SetRow { icon: "animation"; label: "It comes"; hint: "The island drops down and turns into it, or it rises from the bottom of the screen" }
                Choice {
                    x: 10
                    current: c.from
                    options: [{ value: "island", label: "Out of the island" }, { value: "rise", label: "Up from below" }, { value: "fade", label: "Fading in" }]
                    onPicked: v => c.from = v
                }
                SetRow { icon: "align_horizontal_center"; label: "It stands" }
                Choice {
                    x: 10
                    current: c.side
                    options: [{ value: "left", label: "Left" }, { value: "center", label: "In the middle" }, { value: "right", label: "Right" }]
                    onPicked: v => c.side = v
                }
                SetRow { icon: "wallpaper"; label: "Its screen" }
                Choice {
                    x: 10
                    current: c.screen
                    options: [{ value: "wallpaper", label: "Your wallpaper" }, { value: "colours", label: "Your colours" }, { value: "plain", label: "Plain" }]
                    onPicked: v => c.screen = v
                }
            }
            // the body as it will look, with a still screen
            Item {
                id: preview
                anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 10 }
                readonly property real k: 0.34
                width: 384 * k
                height: (holder.item ? holder.item.implicitHeight : 784) * k
                Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                Loader {
                    id: holder
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: item ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : 0
                    scale: preview.k
                    transformOrigin: Item.Top
                    sourceComponent: c.skin === "flip" ? flipC : c.skin === "bare" ? bareC : slabC
                }
                Component { id: glimpseC; Glimpse {} }
                Component { id: slabC; SlabBody { screen: glimpseC } }
                Component { id: flipC; FlipBody { screen: glimpseC } }
                Component { id: bareC; BareBody { screen: glimpseC } }
            }
        }
        SetRow {
            icon: "zoom_in"; label: "Size"; hint: "It also shrinks to fit a short screen"
            Range { value: c.size; from: 0.8; to: 1.2; step: 0.05; shownScale: 100; suffix: "%"; onMoved: v => c.size = v }
        }
        SetRow {
            icon: "3d_rotation"; label: "Leans toward the pointer"; hint: "And holds still while the pointer's on it"
            Toggle { checked: c.tilt; onToggled: on => c.tilt = on }
        }
        SetRow {
            icon: "brightness_4"; label: "Darkens the screen behind"
            Toggle { checked: c.dim; onToggled: on => c.dim = on }
        }
        SetRow {
            icon: "keyboard_command_key"; label: "mod+y"; hint: "Or `qs -c yoru ipc call phone open control` (home, control, today, music, wifi, bluetooth)"
            Btn { label: "Try it"; icon: "smartphone"; tonal: true; onClicked: tryIt() }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "view_carousel"; title: "Pages"
        SetRow { icon: "swipe"; label: "Which, in this order"; hint: "Swipe, Tab or the pills along the bottom between them. One turned off and on again goes to the end" }
        Chips {
            x: 10
            numbered: true
            least: 1
            current: c.pages
            options: Actions.pages.map(p => ({ value: p, label: Actions.page[p][1], icon: Actions.page[p][0] }))
            onPicked: v => c.pages = v
        }
        SetRow { icon: "start"; label: "It opens on" }
        Choice {
            x: 10
            current: c.start
            options: Actions.pages.map(p => ({ value: p, label: Actions.page[p][1] })).concat([{ value: "last", label: "Where you left it" }])
            onPicked: v => c.start = v
        }
        SetRow {
            icon: "lyrics"; label: "Sing along"; hint: "The music page shows the words, a line at a time (from lrclib.net)"
            Toggle { checked: c.lyrics; onToggled: on => c.lyrics = on }
        }
        SetRow {
            icon: "smartphone"; label: "Your real phone"; hint: "With KDE Connect (kdeconnect) paired: its battery and notifications on the control page, and buttons to ring it, send it the clipboard or wave"
            Toggle { checked: c.kdeconnect; onToggled: on => c.kdeconnect = on }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "apps"; title: "Home screen"
        SetRow { icon: "schedule"; label: "Clock"; hint: "The desktop's styles" }
        Choice {
            x: 10
            current: c.clock
            options: [["none", "None"], ["thin", "Thin"], ["bold", "Bold"], ["stacked", "Stacked"], ["outline", "Outline"], ["mono", "Mono"],
                      ["split", "Split"], ["words", "Words"], ["kanji", "Kanji"], ["serif", "Serif"], ["analog", "Analog"]].map(o => ({ value: o[0], label: o[1] }))
            onPicked: v => c.clock = v
        }
        SetRow {
            icon: "grid_view"; label: "Icons in a row"
            Range { value: c.columns; from: 3; to: 5; step: 1; onMoved: v => c.columns = Math.round(v) }
        }
        SetRow {
            icon: "label"; label: "Names under the icons"
            Toggle { checked: c.labels; onToggled: on => c.labels = on }
        }
        SetRow {
            icon: "shelves"; label: "Dock"; hint: "The first four apps, on a shelf along the bottom"
            Toggle { checked: c.dock; onToggled: on => c.dock = on }
        }
        SetRow {
            icon: "push_pin"; label: "Apps"
            hint: "Desktop ids, separated by commas; empty for the ones you open most. Right-click one on the phone to take it off"
            Field {
                width: 300
                text: c.apps.join(", ")
                placeholder: "the ones you open most"
                onEdited: t => c.apps = t.split(/[,\s]+/).map(x => x.replace(/\.desktop$/, "")).filter(x => x !== "")
            }
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "toggle_on"; title: "Quick settings"
        SetRow { icon: "tune"; label: "Tiles, in this order"; hint: "On the control page. Wi-Fi and Bluetooth are wide, and open their lists" }
        Chips {
            x: 10
            numbered: true
            current: c.tiles
            options: everything
            onPicked: v => c.tiles = v
        }
        Item { width: 1; height: 8 }
    }

    Section {
        id: pad
        visible: c.skin === "flip"
        icon: "dialpad"; title: "Keypad"
        property int key: 0                 // the key being set, 0 for 1
        readonly property var keys: { const k = c.keys.map(x => x); while (k.length < 9) k.push(""); return k; }
        SetRow { icon: "touch_app"; label: "What 1 to 9 do"; hint: "Pick a key, then what it does. * mutes, 0 goes home and # locks; your keyboard's number keys press them too" }
        Grid {
            x: 10
            columns: 3
            spacing: 8
            Repeater {
                model: 9
                Rectangle {
                    id: keyCap
                    required property int index
                    readonly property bool on: pad.key === index
                    readonly property string act: pad.keys[index]
                    width: 168; height: 46
                    radius: Theme.r(16)
                    color: on ? Theme.secondaryContainer : Theme.surfaceMid
                    border.width: on ? 2 : 1
                    border.color: on ? Theme.primary : Theme.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Txt { x: 14; anchors.verticalCenter: parent.verticalCenter; text: keyCap.index + 1; size: 18; weight: Font.DemiBold; color: keyCap.on ? Theme.inkSecondaryContainer : Theme.ink }
                    Icon { x: 38; anchors.verticalCenter: parent.verticalCenter; visible: keyCap.act !== ""; name: Actions.icon(keyCap.act); size: 18; color: Theme.primary }
                    Txt {
                        anchors { left: parent.left; leftMargin: 64; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: keyCap.act !== "" ? Actions.label(keyCap.act) : "Nothing"
                        size: 12; color: keyCap.on ? Theme.inkSecondaryContainer : Theme.inkDim
                    }
                    StateLayer { onClicked: pad.key = keyCap.index }
                }
            }
        }
        SetRow { icon: "keyboard"; label: (pad.key + 1) + " does" }
        Choice {
            x: 10
            current: pad.keys[pad.key]
            options: everything.concat([{ value: "", label: "Nothing" }])
            onPicked: v => { const k = pad.keys.slice(); k[pad.key] = v; c.keys = k; }
        }
        Item { width: 1; height: 8 }
    }
}
