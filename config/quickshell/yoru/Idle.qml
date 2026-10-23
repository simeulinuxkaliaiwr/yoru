import Quickshell
import Quickshell.Wayland
import QtQuick
import qs

// the moment before the screen locks itself: swayidle (yoru-idle) says so a few seconds
// early (`idle warn SECONDS`), the screens dim and the island counts down; any input
// brings swayidle's resume (`idle cancel`). The idle time and the warning are swayidle's
// arguments, so a change in the settings swaps it for one with the new ones
Scope {
    id: idle

    required property var isle
    required property bool locked
    property bool warning: false
    property int secs: 0
    property real until: 0
    property int left: 0

    function warn(s) {
        if (locked) return;
        secs = Math.max(1, s);
        until = Date.now() + secs * 1000;
        left = secs;
        warning = true;
        isle.showIdle(true);
    }
    function cancel() {
        warning = false;
        isle.showIdle(false);
    }
    onLockedChanged: if (locked) cancel()
    Timer {
        interval: 200; repeat: true; running: idle.warning
        onTriggered: idle.left = Math.max(0, Math.ceil((idle.until - Date.now()) / 1000))
    }

    readonly property string args: Config.o.lock.lockAfterMinutes + "/" + Config.o.lock.warnSeconds
    onArgsChanged: restart.restart()
    // also at start: the settings may have changed while the shell was away. yoru-idle only
    // replaces a swayidle of its own that runs with other values, and starts none itself
    Component.onCompleted: restart.restart()
    Timer { id: restart; interval: 2500; onTriggered: Quickshell.execDetached(["yoru-idle", "--restart"]) }

    Variants {
        model: Quickshell.screens
        Scope {
            id: dimmer
            required property var modelData
            LazyLoader {
                active: idle.warning
                PanelWindow {
                    screen: dimmer.modelData
                    anchors { top: true; bottom: true; left: true; right: true }
                    exclusionMode: ExclusionMode.Ignore
                    // under the island, which says why
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "yoru-idle"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}
                    color: "transparent"
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0
                        NumberAnimation on opacity { to: 0.6; duration: idle.secs * 1000; easing.type: Easing.InQuad }
                    }
                }
            }
        }
    }
}
