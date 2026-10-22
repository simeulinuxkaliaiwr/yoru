pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

// battery, network, bluetooth, brightness, night light and caffeine
Singleton {
    id: st

    // battery
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property real charge: battery?.percentage ?? 0     // 0..1
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged
    readonly property string batteryIcon: {
        if (charging) return "battery_charging_full";
        const steps = ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"];
        return steps[Math.min(7, Math.floor(charge * 8))];
    }

    // network, from nmcli
    property string ssid: ""
    property int signal: -1
    property bool ethernet: false
    property bool wifiOn: true
    readonly property string netIcon: ethernet ? "lan" : !wifiOn ? "wifi_off" : signal < 0 ? "signal_wifi_statusbar_not_connected"
        : signal > 75 ? "network_wifi" : signal > 50 ? "network_wifi_3_bar" : signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string netName: ethernet ? "Ethernet" : !wifiOn ? "Wi-Fi off" : ssid || "Disconnected"

    Process {
        id: netQuery
        command: ["sh", "-c", "nmcli -t -f WIFI radio; echo --; nmcli -t -f TYPE,STATE dev; echo --; nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list --rescan no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [radio, devs, nets] = this.text.split("--\n");
                st.wifiOn = (radio ?? "").trim() === "enabled";
                st.ethernet = /^ethernet:connected$/m.test(devs ?? "");
                const cur = (nets ?? "").split("\n").find(l => l.startsWith("*:"));
                if (cur) {
                    const f = cur.split(":");
                    st.signal = parseInt(f[1]);
                    st.ssid = f.slice(2).join(":").replace(/\\:/g, ":");
                } else { st.signal = -1; st.ssid = ""; }
            }
        }
    }
    Timer { interval: 8000; repeat: true; running: true; triggeredOnStart: true; onTriggered: netQuery.running = true }
    Timer { id: netSoon; interval: 1500; onTriggered: netQuery.running = true }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]);
        wifiOn = !wifiOn;
        netSoon.restart();
    }

    // bluetooth. Switched off by rfkill (a laptop's wireless key, `rfkill block`), the adapter
    // can't power on until the block is lifted: lift it, then turn it on once it's free
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btConnected: (Bluetooth.devices?.values ?? []).filter(d => d.connected)
    property bool btWanted: false
    function toggleBt() {
        if (!adapter) return;
        if (adapter.enabled) { adapter.enabled = false; return; }
        if (adapter.state === BluetoothAdapterState.Blocked) {
            btWanted = true;
            btGiveUp.restart();
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
        } else adapter.enabled = true;
    }
    Connections {
        target: st.adapter
        function onStateChanged() {
            if (st.btWanted && st.adapter.state === BluetoothAdapterState.Disabled) {
                st.btWanted = false;
                st.adapter.enabled = true;
            }
        }
    }
    Timer { id: btGiveUp; interval: 5000; onTriggered: st.btWanted = false }

    // brightness
    property real brightness: 0
    readonly property string brightIcon: brightness < 0.34 ? "brightness_5" : brightness < 0.67 ? "brightness_6" : "brightness_7"
    signal brightnessShown()
    Process {
        id: brightQuery
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split(",");
                if (f.length > 3) st.brightness = parseInt(f[3]) / 100;
            }
        }
    }
    Component.onCompleted: brightQuery.running = true
    function readBrightness() { brightQuery.running = true; }
    property real pendingBright: -1
    function setBrightness(v) {
        v = Math.max(0.01, Math.min(1, v));
        brightness = v;
        pendingBright = v;
        if (!brightSet.running) brightApply.restart();
    }
    // a drag sends a stream of values; only the latest needs to reach brightnessctl
    Timer {
        id: brightApply; interval: 30
        onTriggered: {
            if (st.pendingBright < 0) return;
            brightSet.command = ["brightnessctl", "-q", "set", Math.round(st.pendingBright * 100) + "%"];
            st.pendingBright = -1;
            brightSet.running = true;
        }
    }
    Process { id: brightSet; onExited: if (st.pendingBright >= 0) brightApply.restart() }

    // night light: wlsunset at a fixed warm temperature
    property bool night: false
    Process {
        id: sunset
        running: st.night
        command: ["wlsunset", "-T", "4001", "-t", "4000"]
    }

    // caffeine: hold an idle inhibitor while it's on
    property bool caffeine: false
    Process {
        running: st.caffeine
        command: ["systemd-inhibit", "--what=idle", "--who=yoru", "--why=caffeine", "--mode=block", "sleep", "infinity"]
    }

    // uptime, for the control centre
    property string uptime: ""
    FileView { id: up; path: "/proc/uptime"; blockLoading: true }
    function readUptime() {
        up.reload();
        const s = parseFloat(up.text().split(" ")[0]);
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        uptime = (h > 0 ? h + "h " : "") + m + "m";
    }
}
