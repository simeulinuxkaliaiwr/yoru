import Quickshell.Io
import QtQuick
import qs
import qs.parts

Column {
    id: page
    spacing: 14
    readonly property var c: Config.o.notifications

    // the apps that have sent some, from the history file (not Notifs: that would start a
    // second notification server here), and any with a rule already
    property var seen: []
    FileView {
        path: Theme.cacheDir + "/notifications.json"
        printErrors: false
        onLoaded: {
            let h = [];
            try { h = JSON.parse(text()); } catch (e) {}
            page.seen = [...new Set(h.map(x => x.app))];
        }
    }
    readonly property var apps: [...new Set(seen.concat(Object.keys(c.apps)))].filter(a => a)
    function setRule(app, r) {
        const a = Object.assign({}, c.apps);
        if (r === "show") delete a[app]; else a[app] = r;
        c.apps = a;
    }

    Section {
        icon: "notifications"; title: "Pop-ups"
        SetRow {
            icon: "timer"; label: "They stay for"; hint: "Longer while the pointer is on one; critical ones 12 s"
            Range { value: Config.o.island.toastSeconds; from: 2; to: 15; step: 1; suffix: " s"; onMoved: v => Config.o.island.toastSeconds = v }
        }
        SetRow { icon: "volume_up"; label: "A sound with each"; hint: "Not during do not disturb"; Toggle { checked: c.sound; onToggled: on => c.sound = on } }
        SetRow {
            icon: "history"; label: "The history keeps"; hint: "In the control centre, across restarts"
            Range { value: c.keep; from: 10; to: 500; step: 10; onMoved: v => c.keep = v }
        }
    }

    Section {
        icon: "apps"; title: "By app"
        SetRow {
            icon: "info"; label: "What each app's do"
            hint: page.apps.length ? "Quietly: into the history without popping up (the bell by an app in the control centre does it too). Never: not kept at all. Critical ones always show"
                                   : "Apps show up here once they've sent a notification"
        }
        Repeater {
            model: page.apps
            SetRow {
                required property string modelData
                icon: "notifications_active"; label: modelData
                Choice {
                    width: 320
                    current: page.c.apps[modelData] ?? "show"
                    options: [{ value: "show", label: "Show" }, { value: "quiet", label: "Quietly" }, { value: "never", label: "Never" }]
                    onPicked: v => page.setRule(modelData, v)
                }
            }
        }
    }
}
