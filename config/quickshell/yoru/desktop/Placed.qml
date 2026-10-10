import QtQuick
import QtQuick.Effects
import qs

// one placed widget (a Desk item): its card in the item's layout and look,
// scaled to the item's size. `shown` says whether it has anything to show
Item {
    id: v
    property var item
    readonly property var kind: Desk.kind(item?.type ?? "")
    readonly property string look: item?.look || Config.o.desktop.widgetStyle
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

    Loader {
        id: loader
        scale: v.k
        transformOrigin: Item.TopLeft
        sourceComponent: ({ day: dayC, weather: weatherC, calendar: calC, system: sysC, media: mediaC })[v.item?.type] ?? null
        // with no card under it, the text needs a shadow to read
        layer.enabled: v.look === "minimal"
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.9)
            shadowBlur: 0.35
            shadowVerticalOffset: 1
        }
    }
    readonly property string layout: v.item?.layout || Config.o.desktop[kind.key]
    Component { id: dayC; DayCard { layout: v.layout; look: v.look } }
    Component { id: weatherC; WeatherCard { layout: v.layout; look: v.look } }
    Component { id: calC; CalendarCard { layout: v.layout; look: v.look } }
    Component { id: sysC; SystemCard { layout: v.layout; look: v.look } }
    Component { id: mediaC; MediaCard { layout: v.layout; look: v.look; visible: v.force || Media.title !== "" } }
}
