import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts

Column {
    id: page
    spacing: 14
    readonly property var c: Config.o.calendar

    // how many events each feed gives, as `yoru events` reads them (not Events: that's the shell's)
    property var counts: ({})
    property bool asking: false
    function check() { asking = true; ask.running = true; }
    // once the settings are read: before that the feeds are still the empty default
    function first() { if (Config.loaded && c.feeds.length && counts.total === undefined) check(); }
    Component.onCompleted: first()
    Connections { target: Config; function onLoadedChanged() { page.first(); } }
    Process {
        id: ask
        command: ["yoru", "events"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.asking = false;
                let list = [];
                try { list = JSON.parse(this.text); } catch (e) {}
                const by = {};
                for (const e of list) by[e.cal] = (by[e.cal] ?? 0) + 1;
                page.counts = { total: list.length, by: by };
            }
        }
    }
    function setFeeds(l) { c.feeds = l; }

    Section {
        icon: "calendar_month"; title: "Your calendars"
        Txt {
            x: 10; width: parent.width - 20; bottomPadding: 8
            text: "An .ics link (Google: Settings → your calendar → Secret address in iCal format; Proton, Nextcloud, Outlook have one too), or a file or a folder of them (as vdirsyncer keeps them). Their events show in the island's calendar, in the Next up widget, and a word before each starts."
            size: 12; color: Theme.inkDim; wrapMode: Text.Wrap
        }
        Repeater {
            model: page.c.feeds
            Item {
                id: feedRow
                required property string modelData
                required property int index
                width: parent.width; height: 52
                Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: /^(https?|webcal):/.test(feedRow.modelData) ? "link" : "folder"; size: 18; color: Theme.inkDim }
                Field {
                    x: 44; anchors.verticalCenter: parent.verticalCenter
                    width: feedRow.width - 44 - 36 - 20
                    text: feedRow.modelData; placeholder: "https://…/basic.ics or ~/.calendars"
                    onEdited: t => { const l = page.c.feeds.slice(); l[feedRow.index] = t.trim(); page.setFeeds(l.filter(x => x !== "")); page.check(); }
                }
                IconButton {
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    icon: "close"; size: 36
                    onClicked: { const l = page.c.feeds.slice(); l.splice(feedRow.index, 1); page.setFeeds(l); }
                }
            }
        }
        Item { width: 1; height: 6 }
        Row {
            x: 10
            spacing: 10
            Btn { icon: "add"; label: "Add a calendar"; tonal: true; onClicked: page.setFeeds(page.c.feeds.concat(["https://"])) }
            Btn { visible: page.c.feeds.length > 0; icon: "refresh"; label: page.asking ? "Reading…" : "Read them now"; tonal: true; onClicked: page.check() }
        }
        Txt {
            x: 10; topPadding: 6
            visible: page.counts.total !== undefined
            text: page.counts.total === 0 ? "No events found from a month back to two ahead: is the link right?"
                : page.counts.total + " events from a month back to two ahead: " + Object.keys(page.counts.by ?? {}).map(k => k + " " + page.counts.by[k]).join(", ")
            size: 12; color: page.counts.total === 0 ? Theme.danger : Theme.inkDim
        }
        Item { width: 1; height: 8 }
    }

    Section {
        icon: "notifications_active"; title: "Reminders"
        SetRow {
            icon: "alarm"; label: "Before each event"; hint: page.c.remind > 0 ? "The island says so, this long before it starts" : "No reminders"
            Range { value: page.c.remind; from: 0; to: 60; step: 5; suffix: " min"; onMoved: v => page.c.remind = v }
        }
    }
}
