import Quickshell
import Quickshell.Networking
import QtQuick
import qs
import qs.parts

// Wi-Fi: the networks around, the one you're on first, then the ones you know, then by
// strength. A click joins (asking for the password first when it's new), or opens the one
// you're on to leave or forget it; right-click opens any you know. It looks for networks
// while it's open. The password goes to NetworkManager over D-Bus, never on a command line
Item {
    id: wp
    required property var phone
    property bool compact: false
    property string opened: ""              // the network whose row is open
    property string failed: ""              // why joining it didn't work
    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var nets: !dev ? [] : dev.networks.values.filter(n => n.name !== "").sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength) || a.name.localeCompare(b.name))
    readonly property bool radio: Networking.wifiEnabled

    onDevChanged: if (dev) dev.scannerEnabled = true
    Timer { id: fresh; interval: 5000; running: true }
    // only networks you know show while it isn't scanning: keep it scanning, whatever got there first
    Timer { interval: 2500; repeat: true; running: true; onTriggered: if (wp.dev && !wp.dev.scannerEnabled) wp.dev.scannerEnabled = true }
    Component.onCompleted: if (dev) dev.scannerEnabled = true
    Component.onDestruction: if (dev) dev.scannerEnabled = false

    function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe; }
    // what a password alone opens (WPA and WPA3 personal); the rest want NetworkManager's own settings
    function personal(n) { return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(n.security); }
    function bars(n) {
        const s = n.signalStrength;
        return s > 0.75 ? "network_wifi" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }
    function about(n) {
        if (n.state === ConnectionState.Connecting) return "Joining…";
        if (n.state === ConnectionState.Disconnecting) return "Leaving…";
        if (n.connected) return "Connected";
        if (n.known) return "Saved";
        return secured(n) ? "Secured" : "Open";
    }
    // everything this panel asks of NetworkManager
    function act(n, what, psk) {
        if (what === "join") n.connect();
        else if (what === "password") n.connectWithPsk(psk);
        else if (what === "leave") n.disconnect();
        else if (what === "forget") n.forget();
    }
    function pick(n) {
        failed = "";
        if (n.connected) { opened = opened === n.name ? "" : n.name; return; }
        if (n.known || !secured(n)) { opened = ""; act(n, "join"); return; }
        opened = opened === n.name ? "" : n.name;   // new: its password first
    }
    function fail(n, reason) {
        failed = reason === ConnectionFailReason.NoSecrets ? "That password didn't work"
               : reason === ConnectionFailReason.WifiAuthTimeout ? "It didn't answer in time"
               : reason === ConnectionFailReason.WifiNetworkLost ? "It went out of reach"
               : "Couldn't join it";
        opened = n.name;
    }
    // NetworkManager's own settings, for the networks that want more than a password
    function more() {
        phone.afterwards(() => Quickshell.execDetached(["sh", "-c", 'command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec "$@"', "sh"]
                                                       .concat(Apps.inTerminal(["nmtui"], ""))));
    }
    onOpenedChanged: if (opened === "") wp.forceActiveFocus()

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
        phone: wp.phone
        compact: wp.compact
        title: "Wi-Fi"
        on: wp.radio
        busy: wp.radio && (fresh.running || wp.nets.length === 0)
        onToggled: Status.toggleWifi()
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: wp.compact ? 8 : 14; rightMargin: wp.compact ? 8 : 14; topMargin: 4 }
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: wp.radio ? wp.nets : []
        header: Item {
            width: list.width
            height: wp.wired ? 58 : 0
            visible: !!wp.wired
            Rectangle {
                width: parent.width; height: 52
                radius: Theme.r(20)
                color: Theme.primaryContainer
                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "lan"; size: 20; fill: 1; color: Theme.inkPrimaryContainer }
                Column {
                    anchors { left: parent.left; leftMargin: 46; verticalCenter: parent.verticalCenter }
                    Txt { text: "Ethernet"; size: 13; weight: Font.DemiBold; color: Theme.inkPrimaryContainer }
                    Txt { text: "Connected"; size: 11; color: Theme.inkPrimaryContainer; opacity: 0.85 }
                }
            }
        }
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property var n: modelData
            readonly property bool open: wp.opened === n.name
            readonly property bool asks: open && !n.connected && wp.personal(n) && (!n.known || wp.failed !== "")
            width: list.width
            height: line.height + (open ? drawer.implicitHeight + 10 : 0)
            radius: Theme.r(open ? 22 : 26)
            color: n.connected ? Theme.primaryContainer : Theme.alpha(Theme.surfaceHigh, open ? 0.9 : 0.62)
            Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            clip: true
            readonly property color ink: n.connected ? Theme.inkPrimaryContainer : Theme.ink

            Connections {
                target: row.n
                function onConnectionFailed(reason) { wp.fail(row.n, reason); }
                function onConnectedChanged() { if (row.n.connected && wp.opened === row.n.name) { wp.opened = ""; wp.failed = ""; } }
            }

            Item {
                id: line
                width: parent.width
                height: wp.compact ? 46 : 52
                Icon {
                    id: sig
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    name: wp.bars(row.n); size: 20; fill: 1
                    color: row.ink
                }
                Column {
                    anchors { left: sig.right; leftMargin: 12; right: lock.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    Txt { width: parent.width; text: row.n.name; size: 13; weight: row.n.connected ? Font.DemiBold : Font.Medium; color: row.ink }
                    Txt { width: parent.width; text: wp.about(row.n); size: 11; color: row.n.connected ? Theme.inkPrimaryContainer : Theme.inkDim; opacity: 0.85 }
                }
                Icon {
                    id: lock
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    name: row.n.stateChanging ? "progress_activity" : wp.secured(row.n) ? "lock" : "lock_open"
                    size: 16; color: row.n.connected ? Theme.inkPrimaryContainer : Theme.outline
                    RotationAnimation on rotation { running: row.n.stateChanging && wp.phone.shown; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.RightButton && row.n.known) { wp.failed = ""; wp.opened = row.open ? "" : row.n.name; }
                        else wp.pick(row.n);
                    }
                }
            }

            // opened: a password to give, or the way to leave and forget it
            Column {
                id: drawer
                visible: row.open
                anchors { top: line.bottom; left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14 }
                spacing: 8
                Txt {
                    visible: wp.failed !== "" && row.open
                    width: parent.width
                    text: wp.failed
                    size: 11; weight: Font.Medium; color: Theme.danger
                }
                // a password: NetworkManager keeps it once it works
                Rectangle {
                    visible: row.asks
                    width: parent.width; height: 40
                    radius: Theme.r(20)
                    color: Theme.surfaceHighest
                    border.width: pw.activeFocus ? 1.5 : 0
                    border.color: Theme.primary
                    TextInput {
                        id: pw
                        anchors { left: parent.left; leftMargin: 14; right: eye.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                        color: Theme.ink
                        font { family: Theme.sans; pixelSize: 13 }
                        echoMode: eye.on ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        clip: true
                        Component.onCompleted: if (row.asks) forceActiveFocus()
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { join.go(); e.accepted = true; }
                            else if (e.key === Qt.Key_Escape) { wp.opened = ""; e.accepted = true; }
                        }
                        Txt { anchors.verticalCenter: parent.verticalCenter; visible: pw.text === ""; text: "Password"; size: 13; color: Theme.outline }
                    }
                    Connections {
                        target: row
                        function onAsksChanged() { if (row.asks) pw.forceActiveFocus(); else pw.text = ""; }
                    }
                    IconButton {
                        id: eye
                        property bool on: false
                        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                        size: 32; icon: on ? "visibility_off" : "visibility"
                        onClicked: on = !on
                    }
                }
                // more than a password: NetworkManager's own settings
                Txt {
                    visible: row.open && !row.n.connected && !row.n.known && wp.secured(row.n) && !wp.personal(row.n)
                    width: parent.width
                    text: "It wants more than a password (a user name, a certificate)."
                    size: 11; color: Theme.inkDim; wrapMode: Text.Wrap
                }
                Flow {
                    width: parent.width
                    spacing: 8
                    Pill {
                        id: join
                        visible: row.asks
                        primary: true
                        icon: "login"; label: "Join"
                        enabled: pw.text.length >= 8
                        function go() { if (enabled) { wp.failed = ""; wp.act(row.n, "password", pw.text); pw.text = ""; } }
                        onClicked: go()
                    }
                    Pill {
                        visible: row.open && !row.n.connected && row.n.known && !row.asks
                        icon: "login"; label: "Join"
                        onClicked: { wp.failed = ""; wp.act(row.n, "join"); }
                    }
                    Pill {
                        visible: row.open && !row.n.connected && !row.n.known && wp.secured(row.n) && !wp.personal(row.n)
                        icon: "settings"; label: "Network settings"
                        onClicked: wp.more()
                    }
                    Pill {
                        visible: row.n.connected
                        icon: "link_off"; label: "Disconnect"
                        onClicked: { wp.opened = ""; wp.act(row.n, "leave"); }
                    }
                    Pill {
                        visible: row.n.known
                        icon: "delete"; label: "Forget"
                        onClicked: { wp.opened = ""; wp.act(row.n, "forget"); }
                    }
                }
            }
        }

        // nothing to show
        Column {
            anchors.centerIn: parent
            visible: list.count === 0 && !wp.wired
            width: list.width - 20
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: !wp.dev ? "wifi_off" : wp.radio ? "wifi_find" : "wifi_off"; size: 34; color: Theme.outline }
            Txt {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                text: !wp.dev ? "No Wi-Fi here" : wp.radio ? "Looking for networks…" : "Wi-Fi is off"
                size: 13; color: Theme.inkDim
            }
        }
    }

    Item {
        id: foot
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: wp.compact ? 40 : 56
        Pill {
            anchors.centerIn: parent
            icon: "tune"; label: "Network settings"
            onClicked: wp.more()
        }
    }
}
