import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

Column {
    id: page
    spacing: 14
    readonly property var c: Config.o.themes

    // what `yoru themes` says: each app, whether it's there, its file, whether it uses it
    property var apps: []
    function refresh() { list.running = true; }
    Component.onCompleted: refresh()
    Process {
        id: list
        command: ["yoru", "themes"]
        stdout: StdioCollector { onStreamFinished: { try { page.apps = JSON.parse(this.text); } catch (e) {} } }
    }
    // pointing an app at its theme, or writing them now; then the list again
    Process {
        id: act
        onExited: page.refresh()
    }
    function run(args) { act.command = ["yoru", "themes"].concat(args); act.running = true; }

    readonly property var glyphs: ({ kitty: "terminal", alacritty: "terminal", ghostty: "terminal", yazi: "folder_open",
                                     tmux: "view_column", nvim: "code", spicetify: "music_note" })
    function about(a) {
        if (!a.installed) return "Not installed";
        const f = a.files[0] ?? { out: "" };
        if (a.files.some(x => !x.mine)) return f.out + " is your own: yoru leaves it be";
        if (a.used) return "Uses yoru's colours (" + f.out + "), new ones with each wallpaper";
        const where = (f.exists ? "Written to " : "Written with the next wallpaper to ") + f.out;
        if (!a.canUse) return where + "; to use it: " + a.line;
        if (a.id === "spicetify") return where + ", not used yet: Use it makes it spicetify's theme and applies it (Spotify restarts)";
        return where + ", not used yet: Use it adds " + a.line + " to " + a.conf + " (keeping a copy)";
    }

    Section {
        icon: "palette"; title: "Your apps"
        SetRow {
            icon: "info"; label: "In the wallpaper's colours"
            hint: "yoru writes each app a theme from the palette as the wallpaper changes; open terminals change colour anyway"
        }
        Repeater {
            model: page.apps.filter(a => a.own)
            SetRow {
                required property var modelData
                icon: page.glyphs[modelData.id] ?? "apps"
                label: modelData.name
                hint: page.about(modelData)
                opacity: modelData.installed ? 1 : 0.55
                Row {
                    spacing: 10
                    Btn {
                        visible: modelData.installed && !modelData.used && modelData.canUse && modelData.files.every(f => f.mine) && page.c[modelData.id]
                        icon: "check"; label: modelData.id === "spicetify" ? "Use it (restarts Spotify)" : "Use it"
                        onClicked: page.run(["use", modelData.id])
                    }
                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.installed
                        checked: page.c[modelData.id] ?? true
                        onToggled: on => { page.c[modelData.id] = on; if (on) page.run(["write"]); }
                    }
                }
            }
        }
    }

    Section {
        icon: "description"; title: "Your own templates"
        SetRow {
            icon: "folder"; label: "~/.config/yoru/templates"
            hint: "Any file there is written out with each wallpaper: {{primary}}, {{surface}}, {{on_surface}}… (matugen's roles, as hex without #; {{primary.rgb}} as r, g, b), {{color0}} to {{color15}} for a terminal. Its first lines say where: \"yoru: out ~/.config/app/colours.conf\", and optionally \"yoru: needs app\" and \"yoru: then a command to run after\""
        }
        SetRow {
            icon: "edit_note"; label: "Write them"
            Toggle { checked: page.c.mine; onToggled: on => { page.c.mine = on; if (on) page.run(["write"]); } }
        }
        Repeater {
            model: page.apps.filter(a => !a.own)
            SetRow {
                required property var modelData
                icon: "draft"; label: modelData.name
                hint: !modelData.installed ? "Its app isn't installed" : modelData.files[0]?.out ? "Written to " + modelData.files[0].out : "No \"yoru: out\" line: nothing to write"
            }
        }
    }
}
