//@ pragma IconTheme Papirus-Dark
// yoru: the night rice for aro. One island at the top that becomes whatever
// you need, a living wallpaper, and colours taken from it.
//   qs -c yoru ipc show

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    // hot reload crashes quickshell 0.3.1 in QWindow::setScreen; restart instead
    settings.watchFiles: false

    Wallpaper { id: wallpaper }

    // a new wallpaper every so often, if the settings ask for it
    Timer {
        interval: Math.max(1, Config.o.wallpaper.rotateMinutes) * 60000
        running: Config.o.wallpaper.rotateMinutes > 0
        repeat: true
        onTriggered: Quickshell.execDetached(["yoru", "wall", Config.o.wallpaper.shuffle ? "random" : "next"])
    }
    Desktop {}
    Editor {}
    FirefoxStart {}
    Island { id: island }
    Lock { id: lockScreen }

    // the binds in ~/.config/aro/config call these
    IpcHandler {
        target: "desktop"
        function edit(): void { Desk.edit(); }
        function done(): void { Desk.done(); }
        function toggle(): void { Desk.toggle(); }
    }
    IpcHandler {
        target: "island"
        function toggle(mode: string): void { island.open(mode, ""); }
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
