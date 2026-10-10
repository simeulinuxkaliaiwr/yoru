pragma Singleton

import Quickshell
import QtQuick

// the desktop's widgets as things you place: what kinds there are, where each
// one sits (Config desktop.items, with arrangement "custom"), and edit mode.
// An item is { id, type, output, x, y, scale, layout, look }: x/y is its
// top-left corner on that output, layout one of its type's layouts ("" follows
// Widget layouts), look a card look ("" follows Widgets → Style).
Singleton {
    id: desk

    property bool editing: false

    readonly property var types: [
        { type: "weather", group: "Today", name: "Weather", icon: "partly_cloudy_day", key: "weatherStyle",
          layouts: [["card", "Card"], ["hero", "Hero"], ["pill", "Pill"], ["graph", "Graph"], ["split", "Split"]] },
        { type: "calendar", group: "Today", name: "Calendar", icon: "calendar_month", key: "calendarStyle",
          layouts: [["month", "Month"], ["week", "Week"], ["date", "Date"], ["dots", "Dots"]] },
        { type: "system", group: "System", name: "System", icon: "monitoring", key: "systemStyle",
          layouts: [["rings", "Rings"], ["bars", "Bars"], ["chips", "Chips"], ["graph", "Graph"]] },
        { type: "media", group: "Music", name: "Now playing", icon: "album", key: "mediaStyle",
          layouts: [["card", "Card"], ["cover", "Cover"], ["pill", "Pill"], ["vinyl", "Vinyl"]] },
        { type: "day", group: "Today", name: "Today", icon: "hourglass_bottom", key: "dayStyle",
          layouts: [["bars", "Bars"], ["rings", "Rings"], ["sun", "Sun"]] },
        // only in placed mode, and only once added: each keeps its own settings
        { type: "clock", group: "Time", name: "Clock", icon: "schedule", bare: true,
          layouts: [["thin", "Thin"], ["bold", "Bold"], ["stacked", "Stacked"], ["outline", "Outline"], ["mono", "Mono"], ["split", "Split"],
                    ["words", "Words"], ["kanji", "漢字"], ["serif", "Serif"], ["analog", "Analog"], ["cookie", "Cookie"]] },
        { type: "world", group: "Time", name: "World clock", icon: "public", layouts: [["list", "List"], ["grid", "Grid"]],
          defaults: { cities: [{ name: "Tokyo", tz: "Asia/Tokyo" }, { name: "London", tz: "Europe/London" }, { name: "New York", tz: "America/New_York" }] } },
        { type: "lyrics", group: "Music", name: "Lyrics", icon: "lyrics", layouts: [["scroll", "Scroll"], ["line", "Line"], ["card", "Card"]] },
        { type: "photo", group: "Yours", name: "Photo", icon: "photo", bare: true,
          layouts: [["rounded", "Rounded"], ["circle", "Circle"], ["cookie", "Cookie"], ["polaroid", "Polaroid"]],
          defaults: { path: "", minutes: 10, caption: "" } },
        { type: "notes", group: "Yours", name: "Notes", icon: "sticky_note_2", layouts: [["sticky", "Sticky"], ["paper", "Paper"], ["plain", "Plain"]],
          defaults: { title: "Notes", text: "Edit me in edit mode (Super+E)." } },
        { type: "todo", group: "Yours", name: "To-do", icon: "checklist", layouts: [["list", "List"], ["checks", "Checklist"], ["progress", "Progress"]],
          defaults: { title: "To-do", items: [{ text: "Add things in edit mode", done: false }, { text: "Tick them off here", done: false }] } },
        { type: "timers", group: "Time", name: "Timers", icon: "timer", layouts: [["trio", "Trio"], ["focus", "Focus"]] },
        { type: "quote", group: "Yours", name: "Quote", icon: "format_quote", layouts: [["bubble", "Bubble"], ["serif", "Serif"], ["plain", "Plain"]],
          defaults: { text: "", author: "", daily: true } },
        { type: "user", group: "System", name: "User", icon: "account_circle", layouts: [["card", "Card"], ["compact", "Compact"]] },
        { type: "apps", group: "System", name: "Apps", icon: "apps", layouts: [["dock", "Dock"], ["grid", "Grid"]],
          defaults: { apps: ["firefox", "foot", "org.gnome.Nautilus", "steam"] } },
        { type: "countdown", group: "Time", name: "Countdown", icon: "event", layouts: [["number", "Number"], ["page", "Page"], ["pill", "Pill"]],
          defaults: { title: "New year", date: (new Date().getFullYear() + 1) + "-01-01" } },
    ]
    readonly property var looks: [["glass", "Glass"], ["frosted", "Frosted"], ["solid", "Solid"], ["tonal", "Tonal"],
        ["gradient", "Gradient"], ["stack", "Stack"], ["outline", "Outline"], ["neon", "Neon"], ["hud", "HUD"], ["minimal", "Minimal"]]
    readonly property var groups: ["Today", "Time", "Music", "Yours", "System"]
    function kind(type) { return types.find(t => t.type === type) ?? types[0]; }
    // an item's settings over its type's defaults
    function settingsOf(item) { return Object.assign({}, kind(item?.type).defaults ?? {}, item?.settings ?? {}); }
    // a widget saving its own state from the desktop (a to-do ticked off)
    function setting(id, key, value) {
        save(items.map(i => i.id === id ? Object.assign({}, i, { settings: Object.assign({}, i.settings ?? {}, { [key]: value }) }) : i));
    }
    // widgets asking for the island (the user card's power button); shell.qml opens it
    signal island(string mode)

    readonly property bool custom: Config.o.desktop.arrangement === "custom"
    readonly property var items: Config.o.desktop.items ?? []

    // the output an item shows on: its own if that's plugged in, else the first
    function outputOf(item) {
        const names = Quickshell.screens.map(s => s.name);
        return names.includes(item.output) ? item.output : (names[0] ?? "");
    }
    function itemsOn(output) { return items.filter(i => outputOf(i) === output); }
    function save(list) { Config.o.desktop.items = JSON.parse(JSON.stringify(list)); }

    function nextId(list, type) {
        let n = 1;
        while (list.some(i => i.id === type + "-" + n)) n++;
        return type + "-" + n;
    }

    // ── from the automatic arrangements to placed widgets ───────────
    // the desktop's cards report themselves here (plain JS, no bindings), so
    // the first edit starts from exactly where they are on screen
    property var cards: ({})
    function report(key, entry) { if (entry) cards[key] = entry; else delete cards[key]; }

    function snapshot() {
        const d = Config.o.desktop, list = [];
        for (const key in cards) {
            const e = cards[key];
            if (!e.item || !e.win) continue;
            const p = e.item.mapToItem(e.win.contentItem, 0, 0);
            list.push({ id: nextId(list, e.type), type: e.type, output: e.output,
                        x: Math.round(e.win.frostX + p.x), y: Math.round(e.win.frostY + p.y),
                        scale: 1, layout: "", look: "" });
        }
        // switched on but not showing (nothing playing, no forecast yet): near the middle
        const first = Quickshell.screens[0];
        for (const t of types) {
            if (!d.widgets || !d[t.type] || list.some(i => i.type === t.type)) continue;
            list.push({ id: nextId(list, t.type), type: t.type, output: first?.name ?? "",
                        x: Math.round((first?.width ?? 1920) / 2 - 160), y: Math.round((first?.height ?? 1080) / 2 - 80 + list.length * 24),
                        scale: 1, layout: "", look: "" });
        }
        return list;
    }

    function edit() {
        if (!custom) {
            save(snapshot());
            Config.o.desktop.arrangement = "custom";
        }
        editing = true;
    }
    function done() { editing = false; }
    function toggle() { if (editing) done(); else edit(); }
}
