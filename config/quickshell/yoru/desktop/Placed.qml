import QtQuick
import QtQuick.Effects
import qs

// one placed widget (a Desk item): its card in the item's layout and look,
// scaled to the item's size. `shown` says whether it has anything to show
Item {
    id: v
    property var item
    readonly property var kind: Desk.kind(item?.type ?? "")
    // a mode can dress every card alike (its cardLook)
    readonly property string look: (Theme.mode && Theme.mode.cardLook) || item?.look || Config.o.desktop.widgetStyle
    property real k: item?.scale ?? 1
    property bool force: false          // show it even with nothing to show (previews, edit mode)
    readonly property Item card: loader.item
    readonly property real baseWidth: card?.width ?? 320
    readonly property real baseHeight: card?.height ?? 150
    // whether it has something to show: music playing, a forecast in
    readonly property bool live: item?.type === "media" ? Media.title !== "" : item?.type === "weather" ? Weather.ready : true
    readonly property bool shown: !!card && live
    width: baseWidth * k
    height: baseHeight * k
    // how bright the wallpaper is under it (its screen is its parent's size)
    readonly property real under: parent && parent.width > 0
        ? Theme.brightAt(x / parent.width, y / parent.height, width / parent.width, height / parent.height) : Theme.bright

    Loader {
        id: loader
        scale: v.k
        transformOrigin: Item.TopLeft
        sourceComponent: ({ day: dayC, weather: weatherC, calendar: calC, system: sysC, media: mediaC,
                            clock: clockC, world: worldC, lyrics: lyricsC, photo: photoC, notes: notesC, todo: todoC,
                            timers: timersC, quote: quoteC, user: userC, apps: appsC, countdown: countC, focuslog: focusC, tonight: tonightC, fetch: fetchC, agenda: agendaC })[v.item?.type] ?? null
        // with no card under it, the text needs a shadow to read, wider where it's bright
        layer.enabled: v.look === "minimal" && !v.kind.bare
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.9)
            shadowBlur: 0.35 + 0.4 * Theme.shade(v.under)
            shadowVerticalOffset: 1
        }
    }
    readonly property string layout: v.item?.layout || (kind.key ? Config.o.desktop[kind.key] : kind.layouts[0][0])
    Component { id: dayC; DayCard { layout: v.layout; look: v.look } }
    Component { id: weatherC; WeatherCard { layout: v.layout; look: v.look } }
    Component { id: calC; CalendarCard { layout: v.layout; look: v.look } }
    Component { id: sysC; SystemCard { layout: v.layout; look: v.look } }
    Component { id: mediaC; MediaCard { layout: v.layout; look: v.look; visible: v.force || Media.title !== "" } }
    // the newer ones keep their own settings (Desk.settingsOf) and know their id, to save state
    readonly property var settings: Desk.settingsOf(v.item)
    readonly property string itemId: v.item?.id ?? ""
    Component { id: clockC; ClockCard { layout: v.layout; settings: v.settings; itemId: v.itemId; under: v.under } }
    Component { id: worldC; WorldCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: lyricsC; LyricsCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: photoC; PhotoCard { layout: v.layout; settings: v.settings; itemId: v.itemId } }
    Component { id: notesC; NotesCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: todoC; TodoCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: timersC; TimersCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: quoteC; QuoteCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: userC; UserCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: appsC; AppsCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: countC; CountdownCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: focusC; FocusCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: tonightC; TonightCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: fetchC; FetchCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
    Component { id: agendaC; AgendaCard { layout: v.layout; look: v.look; settings: v.settings; itemId: v.itemId } }
}
