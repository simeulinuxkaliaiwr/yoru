pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// yoru's settings: ~/.config/yoru/config.json. The settings window (mod+i)
// edits it and the shell follows the file, so changes show at once; the file
// is also fine to edit by hand.
Singleton {
    id: config
    readonly property alias o: adapter
    readonly property string path: Quickshell.env("HOME") + "/.config/yoru/config.json"

    FileView {
        path: config.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // the first run: write the defaults out so there's a file to edit
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string scheme: "scheme-tonal-spot"   // matugen's scheme types
                property real speed: 1.0                      // animation speed, > 1 is faster
                property bool musicColours: true              // the shell takes the album art's colours while it plays
            }

            property JsonObject wallpaper: JsonObject {
                // ripple, fade, wipe, disc, stripes, zoom, honeycomb, pixelate, or random
                property string transition: "random"
                property list<string> pool: ["ripple", "fade", "wipe", "disc", "stripes", "zoom", "honeycomb", "pixelate"]
                property int duration: 1500
                property real smoothness: 0.3                 // the soft edge, 0..1
                property bool parallax: true
                property bool pauseCovered: true              // videos pause under windows
                property bool liveColours: true               // the shell follows a video wallpaper's colours as it plays
                property int rotateMinutes: 0                 // 0: never change on its own
                property bool shuffle: true
                property list<string> dirs: ["~/Pictures/nightcore", "~/Pictures/Wallpapers"]
            }

            property JsonObject desktop: JsonObject {
                property bool clock: true
                // thin, bold, stacked, outline, mono, split, words, kanji, serif, analog
                property string clockStyle: "thin"
                property string clockPosition: "bottom-left"  // bottom-left, center, top-left
                property bool visualizer: true
                property string visualizerStyle: "bars"       // bars, mirror, wave, dots
                property bool visualizerBusy: true            // on workspaces with windows too
                property real visualizerOpacity: 0.85
                property bool widgets: true
                property string widgetSide: "right"
                property string widgetStyle: "glass"          // glass, frosted, solid, tonal, gradient, stack, outline, neon, hud, minimal
                property int widgetRadius: 28
                property bool weather: true
                property bool system: true
                property bool media: true
                property bool calendar: false
                property bool day: false
                // where: column (one side), grid (two columns on a side), row (under the island), free,
                // or custom: placed by hand in edit mode (mod+e), from `items`
                property string arrangement: "column"
                // custom: [{ id, type, output, x, y, scale, layout, look }], see Desk.qml
                property var items: []
                property bool snapGrid: true                  // edit mode's grid (G)
                // each widget's look
                property string weatherStyle: "card"          // card, hero, pill, graph, split
                property string calendarStyle: "month"        // month, week, date, dots
                property string systemStyle: "rings"          // rings, bars, chips, graph
                property string mediaStyle: "card"            // card, cover, pill, vinyl
                property string dayStyle: "bars"              // bars, rings, sun
                // with arrangement "free": top-left, top-right, middle-left, middle-right, bottom-right, top-center
                property JsonObject spots: JsonObject {
                    property string day: "top-left"
                    property string weather: "top-right"
                    property string calendar: "middle-right"
                    property string system: "bottom-right"
                    property string media: "middle-left"
                }
            }

            property JsonObject island: JsonObject {
                property bool clock24: true
                property bool showMedia: true
                property bool batteryPercent: true
                property string workspaces: "pills"           // pills, numbers
                property int toastSeconds: 5
            }

            property JsonObject focus: JsonObject {
                property int minutes: 25
                property int breakMinutes: 5
                property bool quiet: true                     // no notifications while focusing
            }

            property JsonObject quiet: JsonObject {
                property bool schedule: false                 // do not disturb at night
                property string from: "23:00"
                property string to: "07:00"
            }

            property JsonObject lock: JsonObject {
                property bool enabled: true
                property real blur: 0.8
                property real dim: 0.35
                property bool media: true
                property bool power: true
                property string clockStyle: "thin"
                property int lockAfterMinutes: 10
            }

            // Firefox's new tab page; the shell writes these to ~/startpages/yoru-start.js
            property JsonObject start: JsonObject {
                property string layout: "centre"              // centre, left, minimal
                property bool greeting: true
                property string name: ""                      // who it greets; empty: your user name
                property bool clock: true
                property bool seconds: false
                property bool date: true
                property string engine: "google"              // google, duckduckgo, youtube, github, wikipedia
                property var links: [                         // [{ name, url }], up to 9, keys 1-9
                    { name: "GitHub", url: "https://github.com" },
                    { name: "YouTube", url: "https://youtube.com" },
                    { name: "Reddit", url: "https://reddit.com" },
                    { name: "Claude", url: "https://claude.ai" }
                ]
                property int blur: 22                         // the wallpaper behind it, px
                property real dim: 0.45                       // how much darker the wallpaper gets, 0..1
                property bool keys: true                      // the shortcut hints along the bottom
                property string focus: "search"               // where new tabs type: search (the page) or address (Firefox's bar)
            }

            property JsonObject weather: JsonObject {
                property string city: "São Paulo"             // empty: from your IP
                property bool fahrenheit: false
            }
        }
    }
}
