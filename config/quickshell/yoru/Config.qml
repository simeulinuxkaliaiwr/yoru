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
                // which colour leads the palette: vivid (the most saturated in the picture: lively,
                // but a small bright detail can take over) or main (the one the picture is mostly
                // made of, as Android picks)
                property string accent: "vivid"
                property real speed: 1.0                      // animation speed, > 1 is faster
                property bool musicColours: true              // the shell takes the album art's colours while it plays
                // a mode: a whole look from a folder (~/.config/yoru/modes/NAME, or a path) instead of
                // the wallpaper's palette; "" for none. Set it with `yoru mode NAME|off`, which also
                // runs the mode's hooks and moves to its wallpapers
                property string mode: ""
            }

            property JsonObject wallpaper: JsonObject {
                // what draws it: yoru (the shell: its transitions, parallax and sky) or skwd
                // (skwd-wall v2's daemon; yoru still takes the colours). Change it with
                // `yoru backend NAME`, which also starts or stops skwd's daemon
                property string backend: "yoru"
                // with skwd drawing it, what mod+w opens: yoru (the island's picker) or skwd (skwd-wall's own)
                property string picker: "yoru"
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
                // a wallpaper for the time of day (dawn, day, evening, night, by the real sun):
                // from that period's folder in timeDirs, or by brightness from the folders
                property bool byTime: false
                property JsonObject timeDirs: JsonObject {
                    property string dawn: ""
                    property string day: ""
                    property string evening: ""
                    property string night: ""
                }
                property list<string> dirs: ["~/Pictures/yoru", "~/Pictures/Wallpapers"]
                // `yoru wall fetch`: a random safe-for-work picture from wallhaven or konachan, or a
                // live one (an mp4) from motionbgs, narrowed by search (words on wallhaven and
                // motionbgs, tags on konachan), saved to folder
                property JsonObject online: JsonObject {
                    property string source: "wallhaven"         // wallhaven, konachan or motionbgs
                    property string search: ""
                    property string folder: "~/Pictures/Wallpapers"
                    property string quality: "hd"               // motionbgs: hd (1920x1080) or 4k, when it has one
                    // liked: a fetched one is only on trial, kept by Download (`yoru wall keep`) and
                    // deleted when another wallpaper takes its place; all: every one stays
                    property string keep: "liked"
                }
                // weather drawn over the wallpaper: weather (whatever it's doing outside, and an aurora
                // on clear nights), snow, rain, aurora, fog, storm, or off
                property string sky: "weather"
                property real skyAmount: 0.6                  // how much of it, 0..1
            }

            property JsonObject desktop: JsonObject {
                property bool clock: true
                // thin, bold, stacked, outline, mono, split, words, kanji, serif, analog
                property string clockStyle: "thin"
                property string clockPosition: "bottom-left"  // bottom-left, center, top-left
                property bool visualizer: true
                property string visualizerStyle: "bars"       // bars, mirror, wave, dots, aurora, silk, glass
                property bool visualizerBusy: true            // on workspaces with windows too
                property real visualizerOpacity: 0.85
                property bool widgets: true
                property string widgetSide: "right"
                property string widgetStyle: "glass"          // glass, frosted, solid, tonal, gradient, stack, outline, neon, hud, minimal, manga
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
                // the big clock became a placed Clock widget (on the first edit in custom mode)
                property bool clockPlaced: false
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

            // what mod+a opens: list (the island's launcher) or ring (RingLauncher.qml)
            property JsonObject launcher: JsonObject {
                property string style: "list"                 // list, ring
                property string ringAt: "pointer"             // pointer, island (just under it), center
                property bool ringMorph: true                 // the island flies down and opens into the ring
                property bool ringGlow: true                  // each app's icon glows in its own colours
                property list<string> ringApps: []            // desktop ids; empty = the ones you open most
                property string terminal: "foot"              // what terminal apps (nvim, yazi: Terminal=true) open in
            }

            property JsonObject focus: JsonObject {
                property int minutes: 25
                property int breakMinutes: 5
                property bool quiet: true                     // no notifications while focusing
                property bool music: true                     // pause the music for breaks, play it again after
                property bool rounds: false                   // after a break, focus again, until stopped
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
                property string chars: "shapes"               // the password as: shapes (Material, in turn) or dots
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
                property string imageEngine: "lens"           // reverse image search: lens, bing, saucenao (files too), yandex, tineye, tracemoe (addresses only)
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
                property string city: ""                      // empty: from your IP (ipinfo.io)
                property bool fahrenheit: false
            }
        }
    }
}
