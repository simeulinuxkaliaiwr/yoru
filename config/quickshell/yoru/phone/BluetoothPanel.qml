import Quickshell.Bluetooth
import QtQuick
import qs
import qs.parts

// Bluetooth: your devices (the connected ones first), then the ones nearby, found while it's
// open. A click connects or disconnects one of yours, or pairs a new one and trusts it, so it
// comes back by itself next time; right-click opens one of yours to forget it
Item {
    id: bp
    required property var phone
    property bool compact: false
    property string opened: ""              // the address of the device whose row is open
    property var wanted: ({})               // pairing started here: connect once it's paired
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool radio: adapter?.enabled ?? false
    readonly property var all: adapter ? adapter.devices.values : []
    // unnamed devices only have their address for a name: no use in a list
    function named(d) { return d.name !== "" && !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(d.name); }
    readonly property var mine: all.filter(d => d.paired || d.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var near: all.filter(d => !d.paired && !d.bonded && named(d))
        .sort((a, b) => a.name.localeCompare(b.name))

    // looking for devices while it's open
    readonly property bool looking: radio && phone.shown
    onLookingChanged: if (adapter) adapter.discovering = looking
    Component.onCompleted: if (adapter && looking) adapter.discovering = true
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    function glyph(d) {
        const i = d.icon ?? "";
        if (i.startsWith("audio-headset") || i.startsWith("audio-headphones")) return "headphones";
        if (i.startsWith("audio")) return "speaker";
        if (i === "input-gaming") return "sports_esports";
        if (i === "input-keyboard") return "keyboard";
        if (i === "input-mouse") return "mouse";
        if (i === "input-tablet") return "stylus";
        if (i.startsWith("phone")) return "smartphone";
        if (i.startsWith("computer")) return "computer";
        if (i.startsWith("video")) return "tv";
        if (i.startsWith("camera")) return "photo_camera";
        if (i === "printer") return "print";
        return "bluetooth";
    }
    function about(d) {
        if (d.pairing) return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        if (d.connected) return "Connected" + (d.batteryAvailable ? "  ·  " + Math.round(d.battery * 100) + "%" : "");
        if (d.paired || d.bonded) return "Not connected";
        return "Click to pair";
    }
    // everything this panel asks of BlueZ
    function act(d, what) {
        if (what === "connect") d.connect();
        else if (what === "disconnect") d.disconnect();
        else if (what === "pair") d.pair();
        else if (what === "cancel") d.cancelPair();
        else if (what === "forget") d.forget();
        else if (what === "trust") d.trusted = true;
    }
    function pick(d) {
        opened = "";
        if (d.pairing) { act(d, "cancel"); return; }
        if (d.connected) { act(d, "disconnect"); return; }
        if (d.paired || d.bonded) { act(d, "connect"); return; }
        const w = Object.assign({}, wanted);
        w[d.address] = true;
        wanted = w;
        act(d, "pair");
    }

    function key(e) {
        if (e.key === Qt.Key_Down || e.key === Qt.Key_Up) {
            const to = list.contentY + (e.key === Qt.Key_Down ? 80 : -80);
            list.contentY = Math.max(0, Math.min(Math.max(0, list.contentHeight - list.height), to));
            return true;
        }
        return false;
    }

    PanelHead {
        id: head
        phone: bp.phone
        compact: bp.compact
        title: "Bluetooth"
        on: bp.radio || Status.btWanted
        busy: bp.adapter?.discovering ?? false
        onToggled: Status.toggleBt()
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; leftMargin: bp.compact ? 8 : 14; rightMargin: bp.compact ? 8 : 14; topMargin: 4; bottomMargin: 8 }
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: bp.radio ? bp.mine.concat(bp.near) : []
        delegate: Column {
            id: entry
            required property var modelData
            required property int index
            readonly property var d: modelData
            readonly property bool mine: d.paired || d.bonded
            // the first of each kind says which kind it is
            readonly property bool first: index === 0 || index === bp.mine.length
            width: list.width
            spacing: 6
            Txt {
                visible: entry.first
                leftPadding: 8; topPadding: entry.index === 0 ? 0 : 8
                text: entry.mine ? "Your devices" : "Nearby"
                size: 11; weight: Font.DemiBold; color: Theme.outline
            }
            Rectangle {
                id: row
                readonly property bool open: bp.opened === entry.d.address
                width: parent.width
                height: line.height + (open ? drawer.implicitHeight + 10 : 0)
                radius: Theme.r(open ? 22 : 26)
                color: entry.d.connected ? Theme.primaryContainer : Theme.alpha(Theme.surfaceHigh, open ? 0.9 : 0.62)
                Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                clip: true
                readonly property color ink: entry.d.connected ? Theme.inkPrimaryContainer : Theme.ink

                Connections {
                    target: entry.d
                    // one paired from here: trust it and connect
                    function onPairedChanged() {
                        if (!entry.d.paired || !bp.wanted[entry.d.address]) return;
                        const w = Object.assign({}, bp.wanted);
                        delete w[entry.d.address];
                        bp.wanted = w;
                        bp.act(entry.d, "trust");
                        bp.act(entry.d, "connect");
                    }
                }

                Item {
                    id: line
                    width: parent.width
                    height: bp.compact ? 46 : 52
                    Rectangle {
                        id: badge
                        x: 9; anchors.verticalCenter: parent.verticalCenter
                        width: parent.height - 16; height: width
                        radius: Theme.r(width / 2)
                        color: entry.d.connected ? Theme.primary : Theme.surfaceHighest
                        Icon {
                            anchors.centerIn: parent
                            name: bp.glyph(entry.d); size: 18; fill: entry.d.connected ? 1 : 0
                            color: entry.d.connected ? Theme.inkPrimary : Theme.ink
                        }
                    }
                    Column {
                        anchors { left: badge.right; leftMargin: 10; right: spin.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        Txt { width: parent.width; text: entry.d.name; size: 13; weight: entry.d.connected ? Font.DemiBold : Font.Medium; color: row.ink }
                        Txt { width: parent.width; text: bp.about(entry.d); size: 11; color: entry.d.connected ? Theme.inkPrimaryContainer : Theme.inkDim; opacity: 0.85 }
                    }
                    Icon {
                        id: spin
                        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        readonly property bool busy: entry.d.pairing || entry.d.state === BluetoothDeviceState.Connecting || entry.d.state === BluetoothDeviceState.Disconnecting
                        name: busy ? "progress_activity" : entry.mine ? (entry.d.connected ? "link" : "") : "add"
                        size: 16; color: entry.d.connected ? Theme.inkPrimaryContainer : Theme.outline
                        RotationAnimation on rotation { running: spin.busy && bp.phone.shown; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => {
                            if (m.button === Qt.RightButton && entry.mine) bp.opened = row.open ? "" : entry.d.address;
                            else bp.pick(entry.d);
                        }
                    }
                }
                Flow {
                    id: drawer
                    visible: row.open
                    anchors { top: line.bottom; left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14 }
                    spacing: 8
                    Pill {
                        icon: entry.d.connected ? "link_off" : "link"
                        label: entry.d.connected ? "Disconnect" : "Connect"
                        onClicked: { bp.opened = ""; bp.act(entry.d, entry.d.connected ? "disconnect" : "connect"); }
                    }
                    Pill {
                        icon: "delete"; label: "Forget"
                        onClicked: { bp.opened = ""; bp.act(entry.d, "forget"); }
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            width: list.width - 20
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: bp.radio ? "bluetooth_searching" : "bluetooth_disabled"; size: 34; color: Theme.outline }
            Txt {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                text: !bp.adapter ? "No Bluetooth here" : Status.btWanted ? "Turning it on…" : bp.radio ? "Looking for devices…" : "Bluetooth is off"
                size: 13; color: Theme.inkDim
            }
        }
    }
}
