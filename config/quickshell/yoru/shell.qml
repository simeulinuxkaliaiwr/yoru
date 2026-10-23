//@ pragma IconTheme Papirus-Dark
// yoru: a night rice for aro, Hyprland and niri. One island at the top that becomes whatever
// you need, a living wallpaper, and colours taken from it.
//   qs -c yoru ipc show

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root
    // hot reload crashes quickshell 0.3.1 in QWindow::setScreen; restart instead
    settings.watchFiles: false

    Wallpaper { id: wallpaper }

    // a new wallpaper every so often, if the settings ask for it
    Timer {
        interval: Math.max(1, Config.o.wallpaper.rotateMinutes) * 60000
        running: Config.o.wallpaper.rotateMinutes > 0
        repeat: true
        onTriggered: Quickshell.execDetached(Config.o.wallpaper.byTime
            ? ["yoru", "wall", "time", root.period]
            : ["yoru", "wall", Config.o.wallpaper.shuffle ? "random" : "next"].concat(Config.o.wallpaper.rotateFrom === "favourites" ? ["--favourites"] : []))
    }

    // the time of day, by the real sun once the weather knows it: dawn and the
    // evening are the hour or so either side of sunrise and sunset
    property string period: ""
    function periodNow() {
        const now = new Date(), mins = d => d.getHours() * 60 + d.getMinutes();
        const t = mins(now);
        const rise = Weather.sunrise !== "" ? mins(new Date(Weather.sunrise)) : 6 * 60;
        const set = Weather.sunset !== "" ? mins(new Date(Weather.sunset)) : 18 * 60;
        if (t >= rise - 45 && t < rise + 60) return "dawn";
        if (t >= rise + 60 && t < set - 60) return "day";
        if (t >= set - 60 && t < set + 45) return "evening";
        return "night";
    }
    readonly property bool byTime: Config.o.wallpaper.byTime
    // switched on: only change if the wallpaper doesn't already suit the hour
    onByTimeChanged: if (byTime) Quickshell.execDetached(["yoru", "wall", "time", periodNow(), "--keep"])
    Timer {
        interval: 60000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            const p = root.periodNow();
            if (p === root.period) return;
            // at startup only if it doesn't suit; at the turn of the hour, always
            const first = root.period === "";
            root.period = p;
            if (root.byTime) Quickshell.execDetached(["yoru", "wall", "time", p].concat(first ? ["--keep"] : []));
        }
    }
    Desktop {}
    Editor {}
    FirefoxStart {}
    Island { id: island }
    RingLauncher { id: ring; isle: island; onTyped: text => island.search(text) }
    Phone { id: phone; isle: island }
    // the launcher key opens the ring instead, when the settings say so
    function openIsland(mode) {
        if (phone.shown) phone.close();
        if (mode === "launcher" && Config.o.launcher.style === "ring") {
            island.close();
            ring.toggle();
            return;
        }
        if (ring.shown) ring.close();
        island.open(mode, "");
    }
    Lock { id: lockScreen }
    // what came while the screen was locked, said once you're back
    property real lockedAt: 0
    Connections {
        target: lockScreen
        function onLockedChanged() {
            if (lockScreen.locked) root.lockedAt = Date.now();
            else root.away(root.lockedAt);
        }
    }
    function away(since) {
        const came = Notifs.history.filter(h => h.time > since);
        if (came.length === 0) return;
        const apps = [...new Set(came.map(h => h.app))];
        island.showToast({
            icon: "mark_email_unread", app: "While you were away",
            title: came.length === 1 ? came[0].summary : came.length + " notifications",
            body: came.length === 1 ? came[0].app : apps.slice(0, 3).join(", ") + (apps.length > 3 ? " and " + (apps.length - 3) + " more" : ""),
            open: "control"
        });
    }
    Idle { id: idleWarn; isle: island; locked: lockScreen.locked; Component.onCompleted: island.idle = idleWarn }
    // yoru-idle's swayidle calls these a few seconds before it locks, and when you come back
    IpcHandler {
        target: "idle"
        function warn(seconds: int): void { idleWarn.warn(seconds); }
        function cancel(): void { idleWarn.cancel(); }
    }

    // the compositor's binds call these
    Connections {
        target: Desk
        function onIsland(mode) { root.openIsland(mode); }
    }
    IpcHandler {
        target: "desktop"
        function edit(): void { Desk.edit(); }
        function done(): void { Desk.done(); }
        function toggle(): void { Desk.toggle(); }
    }
    Connections {
        target: Alerts
        function onRaised(t) { island.showToast(t); }
    }
    // plugging in: the charge, in the island for a moment (not as the shell starts)
    property bool chargeSettled: false
    Timer { interval: 4000; running: true; onTriggered: root.chargeSettled = true }
    Connections {
        target: Status
        function onChargingChanged() {
            if (Status.charging && Status.hasBattery && root.chargeSettled && Config.o.power.chargeFlash) island.showOsd("charge");
        }
    }
    // the phone takes the screen from the island and the ring
    function openPhone(where) {
        if (phone.shown && where === "") { phone.close(); return; }
        island.close();
        if (ring.shown) ring.close();
        phone.open(where);
    }
    IpcHandler {
        target: "phone"
        function toggle(): void { root.openPhone(""); }
        // on a page: home, control, today, music, or a panel: wifi, bluetooth
        function open(page: string): void { root.openPhone(page === "" ? (phone.shown ? phone.page : "") : page); }
        function close(): void { phone.close(); }
    }
    IpcHandler {
        target: "ring"
        function toggle(): void { if (phone.shown) phone.close(); ring.toggle(); }
        function open(): void { if (phone.shown) phone.close(); ring.open(); }
        function close(): void { ring.close(); }
    }
    IpcHandler {
        target: "alerts"
        function preview(kind: string): void { Alerts.preview(kind); }
    }
    IpcHandler {
        target: "island"
        function toggle(mode: string): void { root.openIsland(mode); }
        function search(text: string): void { island.search(text); }
        function close(): void { island.close(); }
    }
    Connections {
        target: Recorder
        function onSaved(file, ok) {
            island.showToast(ok ? { icon: "videocam", app: "Recording", title: "Saved, path copied", body: file.split("/").pop() }
                                : { icon: "error", app: "Recording", title: "Recording failed", body: "see `qs log -c yoru`" });
        }
    }
    Connections {
        target: Picker
        function onPicked(hex) {
            const c = Qt.color(hex);
            const rgb = [c.r, c.g, c.b].map(x => Math.round(x * 255)).join(", ");
            island.showToast({ swatch: hex, app: "Colour picked · copied", title: hex.toUpperCase(), body: "rgb(" + rgb + ")" });
        }
    }
    Connections {
        target: Focus
        function onFinished(phase) {
            island.showToast(phase === "focus"
                ? { icon: "self_improvement", app: "Focus", title: "Time for a break", body: Config.o.focus.breakMinutes + " minutes; notifications are back" }
                : { icon: "timer", app: "Focus", title: "Break's over", body: "Start another round from the control centre (mod+x)" });
            Quickshell.execDetached(["sh", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null"]);
        }
    }
    Connections {
        target: Timers
        function onRang(minutes) {
            island.showToast({ icon: "alarm", app: "Timer", title: "Time's up", body: minutes + (minutes === 1 ? " minute" : " minutes") + " are over" });
            Quickshell.execDetached(["sh", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null || pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null"]);
        }
    }
    IpcHandler {
        target: "record"
        function toggle(): void { Recorder.toggle(""); }
        function area(): void { Recorder.area(); }
    }
    IpcHandler {
        target: "picker"
        function pick(): void { Picker.pick(); }
    }
    IpcHandler {
        target: "focus"
        function toggle(): void { Focus.toggle(); }
        function start(minutes: int): void { Focus.start(minutes); }
        function stop(): void { Focus.stop(); }
    }

    // yoru-lock calls this; false sends it to swaylock instead
    IpcHandler {
        target: "lock"
        function lock(): bool {
            if (!Config.o.lock.enabled) return false;
            lockScreen.lockNow();
            return true;
        }
        function locked(): bool { return lockScreen.locked; }
    }
    IpcHandler {
        target: "wallpaper"
        function preview(file: string, transition: string): void { wallpaper.show(file, transition); }
        // shows that weather over the wallpaper for a while, whatever it's really doing:
        // snow, rain, aurora, fog, storm, or "" to go back
        function sky(kind: string): void { wallpaper.trySky = kind; }
    }
    IpcHandler {
        target: "osd"
        function volume(): void { island.showOsd("volume"); }
        function mic(): void { island.showOsd("mic"); }
        function brightness(): void { Status.readBrightness(); island.showOsd("brightness"); }
    }
    IpcHandler {
        target: "toast"
        function shot(file: string): void {
            island.showToast({ shot: true, image: file, icon: "screenshot", app: "Screenshot", title: "Copied to clipboard", body: file.split("/").pop() });
        }
        function say(title: string, body: string): void { island.showToast({ icon: "info", title: title, body: body }); }
    }
}
