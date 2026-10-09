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
    Island { id: island }
    Lock { id: lockScreen }

    // the binds in ~/.config/aro/config call these
    IpcHandler {
        target: "island"
        function toggle(mode: string): void { island.open(mode, ""); }
        function close(): void { island.close(); }
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
