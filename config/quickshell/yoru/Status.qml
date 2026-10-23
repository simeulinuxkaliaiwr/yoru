pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
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

    // network, from NetworkManager through Quickshell.Networking (as the Wi-Fi panel): it says
    // when something changes, so nothing is polled. NetworkManager's own check says whether
    // the internet is there too: "no internet", or a sign-in page (a captive portal)
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev ? wifiDev.networks.values.find(n => n.connected) ?? null : null
    readonly property bool ethernet: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property string ssid: wifiNet?.name ?? ""
    readonly property int signal: wifiNet ? Math.round(wifiNet.signalStrength * 100) : -1
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full || Networking.connectivity === NetworkConnectivity.Unknown
    readonly property bool portal: Networking.connectivity === NetworkConnectivity.Portal
    readonly property string netIcon: ethernet ? "lan" : !wifiOn ? "wifi_off" : signal < 0 ? "signal_wifi_statusbar_not_connected"
        : !online ? "signal_wifi_bad"
        : signal > 75 ? "network_wifi" : signal > 50 ? "network_wifi_3_bar" : signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string netName: (ethernet ? "Ethernet" : !wifiOn ? "Wi-Fi off" : ssid || "Disconnected")
        + ((ethernet || signal >= 0) && !online ? (portal ? " · sign in" : " · no internet") : "")
    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
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
    Component.onCompleted: {
        brightQuery.running = true;
        // as they were before a restart
        caffeine = Saved.getThisBoot("caffeine", false);
        if (Config.loaded) restoreNight();
    }
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

    // night light: wlsunset. By hand it holds one warmth; on a schedule (night.auto) wlsunset
    // follows the sun where the weather is, or the hours, and fades over half an hour. Switched
    // by hand while a schedule runs, that holds until the schedule's next turn
    readonly property var nightCfg: Config.o.night
    readonly property int warmth: Math.max(1900, Math.min(6400, nightCfg.warmth))
    readonly property bool nightSun: nightCfg.auto === "sun" && Weather.located
    readonly property bool nightAuto: nightCfg.auto === "sun" || nightCfg.auto === "hours"
    property bool nightManual: false        // by hand, with no schedule
    property var nightHeld: null            // by hand during a schedule: on or off until its next turn
    property bool nightWindow: false        // the schedule's night, right now
    property bool nightReady: false         // read back from before a restart
    readonly property bool night: nightAuto ? (nightHeld ?? nightWindow) : nightManual
    // what its tile says
    readonly property bool nightScheduled: nightAuto && nightHeld === null
    readonly property string nightSub: night ? (nightScheduled ? "Until " + nightTo : warmth + "K")
                                             : (nightScheduled ? "From " + nightFrom : "Off")
    function toggleNight() {
        if (nightAuto) nightHeld = !night;
        else nightManual = !nightManual;
    }
    // when the schedule's night starts and ends: the sun's times, or the settings' hours
    // (also when the weather doesn't know where you are yet)
    readonly property string nightFrom: nightSun ? Weather.sunset.slice(11, 16) : nightCfg.from
    readonly property string nightTo: nightSun ? Weather.sunrise.slice(11, 16) : nightCfg.to
    function inNight() {
        if (!nightAuto) return false;
        const m = s => { const [h, mi] = String(s).split(":").map(Number); return (h || 0) * 60 + (mi || 0); };
        const d = new Date(), now = d.getHours() * 60 + d.getMinutes(), a = m(nightFrom), b = m(nightTo);
        return a <= b ? now >= a && now < b : now >= a || now < b;
    }
    Timer {
        interval: 30000; repeat: true; running: st.nightAuto
        onTriggered: {
            const w = st.inNight();
            if (w !== st.nightWindow) { st.nightWindow = w; st.nightHeld = null; }
        }
    }
    // a new schedule (or none) starts from what it says
    readonly property string nightMode: nightCfg.auto
    onNightModeChanged: if (nightReady) { nightWindow = inNight(); nightHeld = null; }
    onNightFromChanged: nightWindow = inNight()
    onNightToChanged: nightWindow = inNight()
    readonly property var nightState: ({ manual: nightManual, held: nightHeld, window: nightWindow })
    onNightStateChanged: if (nightReady) Saved.set("night", nightState)
    // once the settings are read (the schedule is in them): a turn of the schedule while the
    // shell was away gives it back to the schedule
    function restoreNight() {
        if (nightReady) return;
        nightWindow = inNight();
        const n = Saved.get("night", null);
        if (typeof n === "boolean") nightManual = n;
        else if (n !== null && typeof n === "object") {
            nightManual = !!n.manual;
            nightHeld = n.window === nightWindow ? n.held ?? null : null;
        }
        nightReady = true;
    }
    Connections { target: Config; function onLoadedChanged() { if (Config.loaded) st.restoreNight(); } }

    // the schedule runs in wlsunset itself (it fades); held, or by hand, it's one fixed warmth
    readonly property var sunsetCmd: nightAuto && nightHeld === null
        ? ["wlsunset", "-t", String(warmth), "-T", "6500", "-d", "1800"].concat(
            nightSun ? ["-l", String(Weather.lat), "-L", String(Weather.lon)] : ["-s", nightFrom, "-S", nightTo])
        : ["wlsunset", "-t", String(warmth), "-T", String(warmth + 1)]
    readonly property bool sunsetOn: nightAuto && nightHeld === null ? true : night
    onSunsetCmdChanged: if (sunset.running) sunsetAgain.restart()
    // a new warmth from a slider comes in a stream: start again once it settles, and once
    // the old one has gone
    property bool sunsetRestart: false
    Timer { id: sunsetAgain; interval: 400; onTriggered: if (sunset.running) { st.sunsetRestart = true; sunset.running = false; } }
    Process {
        id: sunset
        running: st.sunsetOn && st.nightReady
        command: st.sunsetCmd
        onExited: if (st.sunsetRestart) { st.sunsetRestart = false; running = Qt.binding(() => st.sunsetOn && st.nightReady); }
    }

    // caffeine: hold an idle inhibitor while it's on
    property bool caffeine: false
    onCaffeineChanged: Saved.setThisBoot("caffeine", caffeine)
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
