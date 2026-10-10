import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.parts
import qs.settings

// the inspector's own part for widgets that have settings: their words,
// cities, pictures, apps and dates. Every edit goes through the editor's `set`, so it
// saves at once and undoes like the rest
Column {
    id: o
    required property var editor        // Editor.qml's root
    required property var it            // the selected item
    readonly property var s: Desk.settingsOf(it)
    readonly property string type: it?.type ?? ""
    spacing: 8
    width: parent ? parent.width : 600

    function set(key, value, run) { editor.set(it.id, key, value, run); }
    function setAt(key, i, field, value) {
        const list = (s[key] ?? []).slice();
        list[i] = Object.assign({}, list[i], { [field]: value });
        set(key, list);
    }
    function drop(key, i) { const list = (s[key] ?? []).slice(); list.splice(i, 1); set(key, list); }
    function push(key, entry) { set(key, (s[key] ?? []).concat([entry])); }

    // a label column like the inspector's
    component Line: Row {
        property string label
        default property alias content: slot.data
        spacing: 12
        Txt { width: 64; text: parent.label; size: 13; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
        Row { id: slot; spacing: 8; anchors.verticalCenter: parent.verticalCenter }
    }
    // several lines of text; saved a moment after typing stops, and on leaving
    component Area: Rectangle {
        id: area
        property string text
        property string placeholder
        signal edited(string text)
        width: 520; height: Math.min(150, Math.max(72, edit.contentHeight + 24))
        radius: 18
        color: Theme.surfaceMid
        border.width: edit.activeFocus ? 2 : 1
        border.color: edit.activeFocus ? Theme.primary : Theme.outlineVariant
        Flickable {
            anchors { fill: parent; margins: 12 }
            contentHeight: edit.contentHeight
            clip: true
            TextEdit {
                id: edit
                width: parent.width
                text: area.text
                wrapMode: TextEdit.Wrap
                color: Theme.ink
                selectionColor: Theme.primaryContainer
                font { family: Theme.sans; pixelSize: 14 }
                onTextChanged: if (activeFocus) quiet.restart()
                onEditingFinished: if (text !== area.text) area.edited(text)
                Keys.onEscapePressed: area.forceActiveFocus()
                Txt { visible: edit.text === ""; text: area.placeholder; color: Theme.outline; size: 14 }
            }
        }
        Timer { id: quiet; interval: 900; onTriggered: if (edit.text !== area.text) area.edited(edit.text) }
    }
    // a one-line field that empties after Enter: for adding things to a list
    component Adder: Rectangle {
        id: adder
        property string placeholder
        signal added(string text)
        width: 300; height: 40; radius: 20
        color: Theme.surfaceMid
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? Theme.primary : Theme.outlineVariant
        Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "add"; size: 18; color: Theme.inkDim }
        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 38; rightMargin: 14 }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.ink
            font { family: Theme.sans; pixelSize: 14 }
            clip: true
            onAccepted: { if (text.trim() !== "") adder.added(text.trim()); text = ""; }
            Txt { anchors.verticalCenter: parent.verticalCenter; visible: input.text === ""; text: adder.placeholder; color: Theme.outline; size: 14 }
        }
    }
    component Small: IconButton { size: 32 }

    // ── world clock: cities ─────────────────────────────────────────
    Column {
        visible: o.type === "world"
        spacing: 6
        Repeater {
            model: o.type === "world" ? (o.s.cities ?? []) : []
            Row {
                required property var modelData
                required property int index
                spacing: 8
                Field { width: 160; text: modelData.name ?? ""; placeholder: "Name"; onEdited: t => o.setAt("cities", index, "name", t) }
                Field { width: 240; text: modelData.tz ?? ""; placeholder: "Area/City"; onEdited: t => o.setAt("cities", index, "tz", t.trim()) }
                Small { icon: "close"; anchors.verticalCenter: parent.verticalCenter; onClicked: o.drop("cities", index) }
            }
        }
        Row {
            spacing: 10
            Adder { width: 240; placeholder: "Add a zone, like Europe/Paris"; onAdded: t => o.push("cities", { name: t.split("/").pop().replace(/_/g, " "), tz: t }) }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Names of zones: timedatectl list-timezones"; size: 11; color: Theme.inkDim }
        }
    }

    // ── photo: a picture or a folder ────────────────────────────────
    Column {
        visible: o.type === "photo"
        spacing: 8
        Line {
            label: "Picture"
            Field { width: 380; text: o.s.path ?? ""; placeholder: "~/Pictures/… (a file or a folder)"; onEdited: t => o.set("path", t.trim()) }
            Pill { icon: "image"; label: "Pick…"; onClicked: o.editor.pick(false, p => o.set("path", p)) }
            Pill { icon: "folder"; label: "Folder…"; onClicked: o.editor.pick(true, p => o.set("path", p)) }
        }
        Line {
            label: "Change"
            Range { value: o.s.minutes ?? 10; from: 1; to: 120; step: 1; suffix: " min"; onMoved: v => o.set("minutes", v, "minutes") }
            Txt { text: "with a folder"; size: 12; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter }
        }
        Line {
            visible: (o.it?.layout ?? "") === "polaroid"
            label: "Caption"
            Field { width: 380; text: o.s.caption ?? ""; placeholder: "Written under the picture"; onEdited: t => o.set("caption", t) }
        }
    }

    // ── notes ───────────────────────────────────────────────────────
    Column {
        visible: o.type === "notes"
        spacing: 8
        Line { label: "Title"; Field { width: 380; text: o.s.title ?? ""; placeholder: "No title"; onEdited: t => o.set("title", t) } }
        Line { label: "Note"; Area { text: o.s.text ?? ""; placeholder: "Write something"; onEdited: t => o.set("text", t, "text") } }
    }

    // ── to-do ───────────────────────────────────────────────────────
    Column {
        visible: o.type === "todo"
        spacing: 6
        Line { label: "Title"; Field { width: 380; text: o.s.title ?? ""; placeholder: "To-do"; onEdited: t => o.set("title", t) } }
        Repeater {
            model: o.type === "todo" ? (o.s.items ?? []) : []
            Row {
                required property var modelData
                required property int index
                x: 76; spacing: 8
                Toggle { checked: modelData.done; anchors.verticalCenter: parent.verticalCenter; onToggled: on => o.setAt("items", index, "done", on) }
                Field { width: 340; text: modelData.text ?? ""; onEdited: t => o.setAt("items", index, "text", t) }
                Small { icon: "close"; anchors.verticalCenter: parent.verticalCenter; onClicked: o.drop("items", index) }
            }
        }
        Adder { x: 76; width: 400; placeholder: "Add a thing to do, then Enter"; onAdded: t => o.push("items", { text: t, done: false }) }
    }

    // ── quote ───────────────────────────────────────────────────────
    Column {
        visible: o.type === "quote"
        spacing: 8
        Line { label: "Daily"; Toggle { checked: o.s.daily ?? true; onToggled: on => o.set("daily", on) }
               Txt { text: "a different old line each day"; size: 12; color: Theme.inkDim; anchors.verticalCenter: parent.verticalCenter } }
        Line { visible: !(o.s.daily ?? true); label: "Words"; Area { text: o.s.text ?? ""; placeholder: "Your own line"; onEdited: t => o.set("text", t, "text") } }
        Line { visible: !(o.s.daily ?? true); label: "Who"; Field { width: 300; text: o.s.author ?? ""; placeholder: "Who said it (or nothing)"; onEdited: t => o.set("author", t) } }
    }

    // ── apps ────────────────────────────────────────────────────────
    Column {
        visible: o.type === "apps"
        spacing: 8
        readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)
        Flow {
            width: o.width
            spacing: 6
            Repeater {
                model: o.type === "apps" ? (o.s.apps ?? []) : []
                Pill {
                    required property var modelData
                    required property int index
                    readonly property var entry: parent.parent.all.find(e => e.id === modelData)
                    icon: "close"
                    label: entry?.name ?? modelData
                    onClicked: o.drop("apps", index)
                }
            }
        }
        Row {
            spacing: 8
            Field { id: find; width: 300; placeholder: "Find an app to add"; onEdited: t => find.query = t
                    property string query: "" }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "type, then Enter"; size: 11; color: Theme.inkDim }
        }
        Flow {
            width: o.width
            spacing: 6
            Repeater {
                model: find.query.length < 1 ? [] : parent.parent.all
                    .filter(e => (e.name + " " + e.id).toLowerCase().includes(find.query.toLowerCase()) && !(o.s.apps ?? []).includes(e.id))
                    .slice(0, 10)
                Pill { required property var modelData; icon: "add"; label: modelData.name; onClicked: o.push("apps", modelData.id) }
            }
        }
    }

    // ── countdown ───────────────────────────────────────────────────
    Column {
        visible: o.type === "countdown"
        spacing: 8
        Line { label: "Until"; Field { width: 300; text: o.s.title ?? ""; placeholder: "What's coming"; onEdited: t => o.set("title", t) } }
        Line { label: "Date"; Field { width: 200; text: o.s.date ?? ""; placeholder: "YYYY-MM-DD"; onEdited: t => o.set("date", t.trim()) }
               Txt { text: /^\d{4}-\d{1,2}-\d{1,2}$/.test(o.s.date ?? "") ? "" : "year-month-day, like 2026-12-25"; size: 12; color: Theme.danger; anchors.verticalCenter: parent.verticalCenter } }
    }
}
