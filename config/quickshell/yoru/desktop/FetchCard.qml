import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import qs
import qs.parts

// the system, as a fetch tool would print it, in the wallpaper's colours:
//   classic: the distro's logo by the facts, and the terminal's colours under them
//   compact: the logo and four lines · line: one line in a pill
// (the logo is the distro's own, named by os-release's LOGO, tinted with the accent)
Card {
    id: c
    property string layout: "classic"
    property var settings: ({})
    property string itemId
    width: layout === "line" ? row.implicitWidth + 40 : layout === "compact" ? 330 : 470
    height: layout === "line" ? 52 : layout === "compact" ? 132 : 336
    radius: layout === "line" ? height / 2 : Theme.r(Config.o.desktop.widgetRadius)

    // the facts that don't change by the minute, asked once (and every half hour)
    property var info: ({})
    Process {
        id: ask
        running: true
        command: ["sh", "-c", `
. /etc/os-release 2>/dev/null
echo "os=\${PRETTY_NAME:-\$NAME}"
echo "logo=\${LOGO:-}"
for f in "/usr/share/pixmaps/\${LOGO}.svg" "/usr/share/pixmaps/\${LOGO}.png"; do [ -n "\$LOGO" ] && [ -f "\$f" ] && { echo "logofile=\$f"; break; }; done
echo "kernel=\$(uname -r)"
echo "host=\$(cat /etc/hostname 2>/dev/null || uname -n)"
n=""
if command -v pacman >/dev/null; then n="\$(pacman -Qq | wc -l) (pacman)"
elif command -v dpkg-query >/dev/null; then n="\$(dpkg-query -f '.\\n' -W | wc -l) (dpkg)"
elif command -v rpm >/dev/null; then n="\$(rpm -qa | wc -l) (rpm)"
elif command -v xbps-query >/dev/null; then n="\$(xbps-query -l | wc -l) (xbps)"; fi
command -v flatpak >/dev/null && f=\$(flatpak list --app 2>/dev/null | wc -l) && [ "\$f" -gt 0 ] && n="\$n, \$f (flatpak)"
echo "packages=\$n"
echo "cpu=\$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//; s/(R)//g; s/(TM)//g; s/ with .*Graphics//; s/ [0-9]*-Core Processor//')"
# the GPU by its marketing name when lspci has one in brackets, else its maker and codename
if command -v lspci >/dev/null; then
    l=\$(lspci -mm 2>/dev/null | grep -iE '"(vga|3d|display)' | head -1)
    dev=\$(echo "\$l" | cut -d'"' -f6); ven=\$(echo "\$l" | cut -d'"' -f4)
    case \$dev in *\[*\]*) dev=\$(echo "\$dev" | sed 's/.*\\[\\(.*\\)\\].*/\\1/') ;; *) dev="\$(echo "\$ven" | sed 's/.*\\[\\([^/]*\\).*\\].*/\\1/; s/ Corporation//; s/,.*//') \$dev" ;; esac
    echo "gpu=\$dev"
fi
echo "shell=\${SHELL##*/}"
awk '/MemTotal/ { printf "memtotal=%.1f\\n", \$2 / 1048576 }' /proc/meminfo`]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = {};
                for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) d[l.slice(0, i)] = l.slice(i + 1).trim(); }
                c.info = d;
            }
        }
    }
    Timer { interval: 30 * 60000; repeat: true; running: true; onTriggered: ask.running = true }

    // and what does: the uptime, the memory in use
    property string uptime: ""
    FileView { id: up; path: "/proc/uptime"; blockLoading: true }
    function readUp() {
        up.reload();
        const s = parseFloat(up.text().split(" ")[0]);
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        uptime = (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m";
    }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: c.readUp() }
    Component.onCompleted: SysStats.watchers++
    Component.onDestruction: SysStats.watchers--

    readonly property string wm: ({ aro: "aro", hyprland: "Hyprland", niri: "niri" })[Wm.name] ?? (Wm.name || "Wayland")
    readonly property var screen0: Quickshell.screens[0]
    readonly property var facts: [
        ["OS", info.os ?? ""], ["Kernel", info.kernel ?? ""], ["Uptime", uptime], ["Packages", info.packages ?? ""],
        ["WM", wm], ["Shell", info.shell ?? ""], ["Terminal", Config.o.launcher.terminal || "foot"],
        ["Display", screen0 ? screen0.width + "×" + screen0.height : ""],
        ["CPU", info.cpu ?? ""], ["GPU", info.gpu ?? ""],
        ["Memory", SysStats.memTotalGb > 0 ? SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GB" : (info.memtotal ? info.memtotal + " GB" : "")],
        ["Theme", "yoru" + (Theme.mode?.name ? " · " + Theme.mode.name : "") + " · " + Theme.sans]
    ].filter(f => f[1] !== "")
    readonly property var swatches: Theme.base?.ansi ?? []

    // the distro's logo in the accent
    component Logo: Item {
        id: lg
        property real size: 96
        width: size; height: size
        Image {
            id: logoImg
            anchors.fill: parent
            source: c.info.logofile ? "file://" + c.info.logofile : c.info.logo ? Quickshell.iconPath(c.info.logo, true) : ""
            sourceSize: Qt.size(lg.size * 2, lg.size * 2)
            fillMode: Image.PreserveAspectFit
            visible: false
            asynchronous: true
        }
        // the accent, cut to the logo's shape (tinting would darken it by its own colours)
        Rectangle { id: fill; anchors.fill: parent; color: Theme.primary; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            source: fill
            visible: logoImg.status === Image.Ready
            maskEnabled: true
            maskSource: logoImg
        }
        // no logo to be had: the first letter
        Rectangle {
            anchors.fill: parent
            visible: logoImg.status !== Image.Ready
            radius: Theme.r(lg.size / 4)
            color: Theme.primaryContainer
            Txt { anchors.centerIn: parent; text: (c.info.os ?? "?").charAt(0); size: lg.size * 0.5; weight: Font.Bold; color: Theme.inkPrimaryContainer }
        }
    }

    // classic
    Item {
        visible: c.layout === "classic"
        anchors.fill: parent
        Logo { id: bigLogo; x: 24; y: 28; size: 112 }
        Column {
            anchors { left: bigLogo.right; leftMargin: 26; right: parent.right; rightMargin: 22; top: parent.top; topMargin: 22 }
            spacing: 2
            Row {
                spacing: 0
                Txt { text: Quickshell.env("USER"); size: 15; weight: Font.Bold; color: Theme.primary; font.family: Theme.mono }
                Txt { text: "@"; size: 15; color: Theme.inkDim; font.family: Theme.mono }
                Txt { text: c.info.host ?? ""; size: 15; weight: Font.Bold; color: Theme.primary; font.family: Theme.mono }
            }
            Rectangle { width: 150; height: 1; color: Theme.alpha(Theme.ink, 0.2) }
            Item { width: 1; height: 4 }
            Repeater {
                model: c.facts.slice(0, 12)
                Row {
                    required property var modelData
                    spacing: 10
                    Txt { width: 74; text: modelData[0]; size: 12; weight: Font.DemiBold; color: Theme.tertiary; font.family: Theme.mono }
                    Txt { width: c.width - bigLogo.width - 26 - 22 - 24 - 84; text: modelData[1]; size: 12; font.family: Theme.mono }
                }
            }
        }
        // the terminal's sixteen colours, as fetch tools end with
        Grid {
            anchors { left: parent.left; leftMargin: 26; bottom: parent.bottom; bottomMargin: 22 }
            columns: 8
            spacing: 4
            Repeater {
                model: c.swatches
                Rectangle { required property string modelData; width: 16; height: 16; radius: Theme.r(5); color: "#" + modelData }
            }
        }
    }

    // compact
    Item {
        visible: c.layout === "compact"
        anchors.fill: parent
        Logo { id: midLogo; x: 20; anchors.verticalCenter: parent.verticalCenter; size: 80 }
        Column {
            anchors { left: midLogo.right; leftMargin: 18; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 3
            Txt { width: parent.width; text: c.info.os ?? ""; size: 15; weight: Font.DemiBold }
            Txt { width: parent.width; text: (c.info.kernel ?? "") + "  ·  " + c.wm; size: 12; color: Theme.inkDim; font.family: Theme.mono }
            Txt { width: parent.width; text: (c.info.packages ?? "").replace(/ \(\w+\)/g, "") + " packages"; size: 12; color: Theme.inkDim; font.family: Theme.mono }
            Txt { width: parent.width; text: "up " + c.uptime; size: 12; color: Theme.inkDim; font.family: Theme.mono }
        }
    }

    // line
    Row {
        id: row
        visible: c.layout === "line"
        x: 18; anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Logo { anchors.verticalCenter: parent.verticalCenter; size: 24 }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: (c.info.os ?? "") + "  ·  " + (c.info.kernel ?? "").split("-")[0] + "  ·  " + c.wm + "  ·  up " + c.uptime
            size: 13; font.family: Theme.mono
        }
    }
}
